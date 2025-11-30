const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const multer = require('multer');
const path = require('path');
const User = require('../models/User');
const Message = require('../models/Message');
const { authenticateToken } = require('../middleware/auth');
const { validateRegistration, validateLogin, validatePasswordReset, sanitizeInput } = require('../middleware/validation');
const { authRateLimit, passwordResetRateLimit } = require('../middleware/rateLimit');

const router = express.Router();

// Initialize user ID counter from database
let userIdCounter = 1;
async function initializeUserIdCounter() {
  try {
    const lastUser = await User.findOne({}, {}, { sort: { 'id': -1 } });
    if (lastUser) {
      userIdCounter = lastUser.id + 1;
    }
    console.log(`User ID counter initialized to: ${userIdCounter}`);
  } catch (error) {
    console.error('Error initializing user ID counter:', error);
  }
}

// Initialize counter on module load
initializeUserIdCounter();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: (req, file, cb) => {
    const allowedMimetypes = [
      'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp',
      'video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/avi',
      'audio/mpeg', 'audio/wav', 'audio/mp3', 'audio/m4a', 'audio/aac',
      'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain', 'application/json',
      'application/octet-stream' // Allow octet-stream for files that might not have proper mimetypes
    ];
    const allowedExtensions = ['.jpeg', '.jpg', '.png', '.gif', '.webp', '.mp4', '.mov', '.avi', '.mp3', '.wav', '.m4a', '.aac', '.pdf', '.doc', '.docx', '.txt', '.json'];

    const extname = allowedExtensions.includes(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedMimetypes.includes(file.mimetype);

    // Special handling for octet-stream: check if extension suggests it's an allowed file type
    const isOctetStreamWithValidExt = file.mimetype === 'application/octet-stream' && extname;

    console.log('File check:', file.originalname, 'mimetype:', file.mimetype, 'ext:', path.extname(file.originalname), 'extname valid:', extname, 'mimetype valid:', mimetype, 'octet-stream with valid ext:', isOctetStreamWithValidExt);

    if ((mimetype && extname) || isOctetStreamWithValidExt) {
      return cb(null, true);
    } else {
      console.log('Rejected file:', file.originalname, 'mimetype:', file.mimetype, 'ext:', path.extname(file.originalname));
      cb(new Error('Invalid file type'));
    }
  }
});

// Register endpoint
router.post('/register', sanitizeInput, validateRegistration, authRateLimit, async (req, res) => {
  try {
    const { email, username, password } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ $or: [{ email }, { username }] });
    if (existingUser) {
      return res.status(400).json({ error: 'User already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    const newUser = new User({
      id: userIdCounter++,
      email,
      username,
      password: hashedPassword,
      profilePhoto: null
    });
    await newUser.save();

    res.status(201).json({ message: 'User registered successfully' });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Login endpoint
router.post('/login', sanitizeInput, validateLogin, authRateLimit, async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    // Check if account is locked
    if (user.isLocked) {
      return res.status(423).json({ error: 'Account is temporarily locked due to too many failed login attempts' });
    }

    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      // Increment login attempts
      await user.incLoginAttempts();
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    // Reset login attempts on successful login
    await user.resetLoginAttempts();

    // Generate JWT token
    const token = jwt.sign(
      { id: user.id, email: user.email, username: user.username },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        profilePhoto: user.profilePhoto
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get all users endpoint (for chat selection)
router.get('/users', authenticateToken, async (req, res) => {
  try {
    const users = await User.find({}, 'id email username profilePhoto');
    res.json(users);
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get messages between two users
router.get('/messages/:receiverId', authenticateToken, async (req, res) => {
  try {
    const { receiverId } = req.params;
    const senderId = req.user.id;

    const chatMessages = await Message.find({
      $or: [
        { senderId: senderId, receiverId: parseInt(receiverId) },
        { senderId: parseInt(receiverId), receiverId: senderId }
      ]
    }).sort({ timestamp: 1 });

    // Convert timestamps to ISO strings for Flutter compatibility
    const messagesWithISOString = chatMessages.map(msg => ({
      ...msg.toObject(),
      timestamp: msg.timestamp.toISOString()
    }));

    res.json(messagesWithISOString);
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// File upload endpoint
router.post('/upload', authenticateToken, (req, res) => {
  console.log('Upload endpoint called');
  console.log('Headers:', req.headers);
  console.log('Body:', req.body);

  const uploadSingle = upload.single('file');
  uploadSingle(req, res, (err) => {
    if (err) {
      console.error('Multer error:', err);
      return res.status(400).json({ error: err.message || 'File upload error' });
    }

    try {
      if (!req.file) {
        console.log('No file in request after multer');
        return res.status(400).json({ error: 'No file uploaded' });
      }

      console.log('File uploaded successfully:', req.file.filename);
      const fileUrl = `/uploads/${req.file.filename}`;
      res.json({ fileUrl });
    } catch (error) {
      console.error('Upload error:', error);
      res.status(500).json({ error: 'Upload failed' });
    }
  });
});

// Profile photo upload endpoint
router.post('/upload-profile-photo', authenticateToken, (req, res) => {
  const uploadSingle = upload.single('profilePhoto');
  uploadSingle(req, res, async (err) => {
    if (err) {
      console.error('Profile photo upload error:', err);
      return res.status(400).json({ error: err.message || 'File upload error' });
    }

    try {
      if (!req.file) {
        return res.status(400).json({ error: 'No file uploaded' });
      }

      const userId = req.user.id;
      const profilePhotoUrl = `/uploads/${req.file.filename}`;

      // Update user's profile photo in database
      await User.findOneAndUpdate(
        { id: userId },
        { profilePhoto: profilePhotoUrl }
      );

      res.json({
        message: 'Profile photo uploaded successfully',
        profilePhoto: profilePhotoUrl
      });
    } catch (error) {
      console.error('Profile photo update error:', error);
      res.status(500).json({ error: 'Failed to update profile photo' });
    }
  });
});

// Password reset request endpoint
router.post('/forgot-password', sanitizeInput, validatePasswordReset, passwordResetRateLimit, async (req, res) => {
  try {
    const { email } = req.body;

    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      // Don't reveal if email exists or not for security
      return res.json({ message: 'If the email exists, a reset link has been sent' });
    }

    // Generate reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenExpiry = Date.now() + 3600000; // 1 hour

    // Save reset token to user (in production, use a separate collection)
    user.resetToken = resetToken;
    user.resetTokenExpiry = resetTokenExpiry;
    await user.save();

    // In production, send email with reset link
    // For now, just return the token for testing
    console.log(`Password reset token for ${email}: ${resetToken}`);

    res.json({
      message: 'If the email exists, a reset link has been sent',
      resetToken: process.env.NODE_ENV === 'development' ? resetToken : undefined
    });
  } catch (error) {
    console.error('Password reset error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Password reset confirmation endpoint
router.post('/reset-password', sanitizeInput, async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    if (!token || !newPassword || newPassword.length < 6) {
      return res.status(400).json({ error: 'Invalid reset token or password' });
    }

    // Find user with valid reset token
    const user = await User.findOne({
      resetToken: token,
      resetTokenExpiry: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({ error: 'Invalid or expired reset token' });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password and clear reset token
    user.password = hashedPassword;
    user.resetToken = undefined;
    user.resetTokenExpiry = undefined;
    await user.save();

    res.json({ message: 'Password reset successfully' });
  } catch (error) {
    console.error('Password reset confirmation error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get current user profile
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const user = await User.findOne({ id: req.user.id }, 'id email username profilePhoto');
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = { router, upload };
