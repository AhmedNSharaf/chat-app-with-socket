const Message = require('./models/Message');

// Socket.io logic
function handleSocketConnection(io) {
  io.use((socket, next) => {
    // Authenticate socket connection with JWT
    const token = socket.handshake.auth.token;
    if (!token) {
      return next(new Error('Authentication error'));
    }

    try {
      const jwt = require('jsonwebtoken');
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.user = decoded;
      next();
    } catch (err) {
      next(new Error('Authentication error'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`User ${socket.user.username} connected`);

    // Join user-specific room
    socket.join(socket.user.id);

    // Handle message event
    socket.on('message', async (data) => {
      const { receiverId, text, mediaUrl, mediaType } = data;
      const senderId = socket.user.id;

      try {
        // Create message object
        const message = new Message({
          senderId: parseInt(senderId),
          receiverId: parseInt(receiverId),
          text: text || '',
          mediaUrl,
          mediaType,
          timestamp: new Date()
        });

        // Save message to database
        await message.save();

        // Convert to plain object and ensure timestamp is ISO string
        const messageObj = message.toObject();
        messageObj.id = message._id.toString();
        messageObj.timestamp = message.timestamp.toISOString();

        // Emit to receiver
        io.to(receiverId).emit('receive_message', messageObj);

        // Emit back to sender for confirmation
        socket.emit('message_sent', messageObj);
      } catch (error) {
        console.error('Error saving message:', error);
        socket.emit('message_error', { error: 'Failed to send message' });
      }
    });

    socket.on('disconnect', () => {
      console.log(`User ${socket.user.username} disconnected`);
    });
  });
}

module.exports = { handleSocketConnection };
