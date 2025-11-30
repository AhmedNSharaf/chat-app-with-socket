require('dotenv').config();
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const mongoose = require('mongoose');
const { router } = require('./routes/auth');
const { handleSocketConnection } = require('./socket');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*", // Allow all origins for development
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Security middleware
const { securityHeaders, csrfProtection } = require('./middleware/security');
app.use(securityHeaders);
app.use(csrfProtection);

// Rate limiting
const { apiRateLimit } = require('./middleware/rateLimit');
app.use('/api/', apiRateLimit);

// Routes
app.use('/api/auth', router);

// Serve uploaded files statically
app.use('/uploads', express.static('uploads'));

// Socket.io connection handling
handleSocketConnection(io);

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/chatapp', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('Connected to MongoDB'))
.catch(err => console.error('MongoDB connection error:', err));

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
