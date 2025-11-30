const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  senderId: { type: Number, required: true },
  receiverId: { type: Number, required: true },
  text: { type: String, default: '' },
  mediaType: { type: String, enum: ['image', 'video', 'document', 'audio', null], default: null },
  mediaUrl: { type: String, default: null },
  timestamp: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Message', messageSchema);
