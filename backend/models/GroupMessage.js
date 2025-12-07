const mongoose = require('mongoose');

const groupMessageSchema = new mongoose.Schema({
  groupId: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true },
  senderId: { type: Number, required: true }, // User ID
  text: { type: String, default: null },
  mediaUrl: { type: String, default: null },
  mediaType: { type: String, enum: ['image', 'video', 'audio', 'file', null], default: null },
  fileName: { type: String, default: null },
  fileSize: { type: Number, default: null },

  // Message metadata
  timestamp: { type: Date, default: Date.now },
  isEdited: { type: Boolean, default: false },
  editedAt: { type: Date, default: null },

  // Deletion tracking
  deletedForEveryone: { type: Boolean, default: false },
  deletedFor: [{ type: Number }], // Array of user IDs who deleted this message for themselves

  // Reply feature
  replyTo: {
    messageId: { type: mongoose.Schema.Types.ObjectId, default: null },
    senderId: { type: Number, default: null },
    text: { type: String, default: null }
  },

  // Reactions
  reactions: [{
    userId: { type: Number, required: true },
    emoji: { type: String, required: true },
    timestamp: { type: Date, default: Date.now }
  }],

  // Read receipts for group messages
  readBy: [{
    userId: { type: Number, required: true },
    readAt: { type: Date, default: Date.now }
  }],

  // Delivery tracking
  deliveredTo: [{
    userId: { type: Number, required: true },
    deliveredAt: { type: Date, default: Date.now }
  }]
});

// Index for faster queries
groupMessageSchema.index({ groupId: 1, timestamp: -1 });
groupMessageSchema.index({ senderId: 1 });

// Add index for delivery tracking
groupMessageSchema.index({ 'deliveredTo.userId': 1 });
groupMessageSchema.index({ groupId: 1, 'deliveredTo.userId': 1 });

module.exports = mongoose.model('GroupMessage', groupMessageSchema);
