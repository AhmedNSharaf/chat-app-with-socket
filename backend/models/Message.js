const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  senderId: { type: Number, required: true },
  receiverId: { type: Number, required: true },
  text: { type: String, default: '' },
  mediaType: { type: String, enum: ['image', 'video', 'document', 'audio', null], default: null },
  mediaUrl: { type: String, default: null },
  timestamp: { type: Date, default: Date.now },
  status: { type: String, enum: ['sent', 'delivered', 'read'], default: 'sent' },
  deliveredAt: { type: Date, default: null },
  readAt: { type: Date, default: null },
  isEdited: { type: Boolean, default: false },
  editedAt: { type: Date, default: null },
  deletedFor: [{ type: Number }], // Array of user IDs who deleted this message
  deletedForEveryone: { type: Boolean, default: false },
  replyTo: { type: mongoose.Schema.Types.ObjectId, ref: 'Message', default: null },
  reactions: [{
    userId: { type: Number, required: true },
    emoji: { type: String, required: true },
    timestamp: { type: Date, default: Date.now }
  }]
});

// Add indexes for efficient delivery queries
messageSchema.index({ receiverId: 1, status: 1 });
messageSchema.index({ senderId: 1, timestamp: -1 });

module.exports = mongoose.model('Message', messageSchema);
