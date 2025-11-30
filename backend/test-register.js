const express = require('express');
const mongoose = require('mongoose');
const User = require('./models/User');
const bcrypt = require('bcryptjs');

const app = express();
app.use(express.json());

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/chatapp', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('Connected to MongoDB'))
.catch(err => console.error('MongoDB connection error:', err));

app.post('/test-register', async (req, res) => {
  try {
    const { email, username, password } = req.body;
    console.log('Received registration request:', { email, username, password: '***' });

    const existingUser = await User.findOne({ $or: [{ email }, { username }] });
    if (existingUser) {
      console.log('User already exists');
      return res.status(400).json({ error: 'User already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new User({
      id: Date.now(),
      email,
      username,
      password: hashedPassword
    });

    await newUser.save();
    console.log('User registered successfully');
    res.status(201).json({ message: 'User registered successfully' });
  } catch (error) {
    console.error('Error during registration:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

const server = app.listen(3001, () => {
  console.log('Test server running on port 3001');
});

process.on('SIGINT', () => {
  server.close();
  mongoose.connection.close();
  process.exit(0);
});
