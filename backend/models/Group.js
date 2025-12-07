const mongoose = require('mongoose');

const groupSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, default: null },
  groupPhoto: { type: String, default: null },
  createdBy: { type: Number, required: true }, // User ID
  admins: [{ type: Number }], // Array of user IDs
  members: [{ type: Number }], // Array of user IDs
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },

  // Group settings
  isPublic: { type: Boolean, default: false },
  allowMembersToAddOthers: { type: Boolean, default: false },

  // Muted members (userId => muteUntil)
  mutedBy: [{
    userId: { type: Number, required: true },
    mutedUntil: { type: Date, default: null } // null = forever
  }],

  // Last message info (for quick display)
  lastMessage: {
    text: { type: String, default: null },
    senderId: { type: Number, default: null },
    timestamp: { type: Date, default: null }
  }
});

// Virtual to check if user is admin
groupSchema.methods.isAdmin = function(userId) {
  return this.admins.includes(userId);
};

// Virtual to check if user is member
groupSchema.methods.isMember = function(userId) {
  return this.members.includes(userId);
};

// Virtual to check if user has muted this group
groupSchema.methods.isMutedBy = function(userId) {
  const mute = this.mutedBy.find(m => m.userId === userId);
  if (!mute) return false;
  if (!mute.mutedUntil) return true; // Muted forever
  return mute.mutedUntil > Date.now();
};

module.exports = mongoose.model('Group', groupSchema);
