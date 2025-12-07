const express = require('express');
const router = express.Router();
const Group = require('../models/Group');
const GroupMessage = require('../models/GroupMessage');
const User = require('../models/User');
const { authenticateToken } = require('../middleware/auth');
const multer = require('multer');
const path = require('path');

// Configure multer for group photo uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/groups/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'group-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!'));
    }
  }
});

// Create a new group
router.post('/create', authenticateToken, upload.single('groupPhoto'), async (req, res) => {
  try {
    const { name, description, memberIds, isPublic, allowMembersToAddOthers } = req.body;
    const creatorId = req.user.id;

    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'Group name is required' });
    }

    // Parse memberIds if it's a string
    let members = [];
    if (memberIds) {
      members = typeof memberIds === 'string' ? JSON.parse(memberIds) : memberIds;
    }

    // Ensure creator is in members list
    if (!members.includes(creatorId)) {
      members.push(creatorId);
    }

    // Verify all members exist
    const users = await User.find({ id: { $in: members } });
    if (users.length !== members.length) {
      return res.status(400).json({ error: 'One or more members not found' });
    }

    const group = new Group({
      name: name.trim(),
      description: description?.trim() || null,
      groupPhoto: req.file ? `/uploads/groups/${req.file.filename}` : null,
      createdBy: creatorId,
      admins: [creatorId], // Creator is the first admin
      members: members,
      isPublic: isPublic === 'true' || isPublic === true,
      allowMembersToAddOthers: allowMembersToAddOthers === 'true' || allowMembersToAddOthers === true
    });

    await group.save();

    res.status(201).json({
      message: 'Group created successfully',
      group: group
    });
  } catch (error) {
    console.error('Error creating group:', error);
    res.status(500).json({ error: 'Failed to create group' });
  }
});

// Get all groups for current user
router.get('/my-groups', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const groups = await Group.find({
      members: userId
    }).sort({ 'lastMessage.timestamp': -1, updatedAt: -1 });

    res.json(groups);
  } catch (error) {
    console.error('Error fetching groups:', error);
    res.status(500).json({ error: 'Failed to fetch groups' });
  }
});

// Get single group details
router.get('/:groupId', authenticateToken, async (req, res) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;

    const group = await Group.findById(groupId);

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user is a member
    if (!group.isMember(userId)) {
      return res.status(403).json({ error: 'You are not a member of this group' });
    }

    res.json(group);
  } catch (error) {
    console.error('Error fetching group:', error);
    res.status(500).json({ error: 'Failed to fetch group details' });
  }
});

// Update group details (admin only)
router.put('/:groupId', authenticateToken, upload.single('groupPhoto'), async (req, res) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;
    const { name, description, isPublic, allowMembersToAddOthers } = req.body;

    const group = await Group.findById(groupId);

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user is admin
    if (!group.isAdmin(userId)) {
      return res.status(403).json({ error: 'Only admins can update group details' });
    }

    // Update fields
    if (name && name.trim()) {
      group.name = name.trim();
    }
    if (description !== undefined) {
      group.description = description?.trim() || null;
    }
    if (req.file) {
      group.groupPhoto = `/uploads/groups/${req.file.filename}`;
    }
    if (isPublic !== undefined) {
      group.isPublic = isPublic === 'true' || isPublic === true;
    }
    if (allowMembersToAddOthers !== undefined) {
      group.allowMembersToAddOthers = allowMembersToAddOthers === 'true' || allowMembersToAddOthers === true;
    }

    group.updatedAt = new Date();
    await group.save();

    res.json({
      message: 'Group updated successfully',
      group: group
    });
  } catch (error) {
    console.error('Error updating group:', error);
    res.status(500).json({ error: 'Failed to update group' });
  }
});

// Add member to group
router.post('/:groupId/add-member', authenticateToken, async (req, res) => {
  try {
    const { groupId } = req.params;
    const { memberIds } = req.body; // Can be single ID or array
    const userId = req.user.id;

    const group = await Group.findById(groupId);

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check permissions
    const canAdd = group.isAdmin(userId) || group.allowMembersToAddOthers;
    if (!canAdd) {
      return res.status(403).json({ error: 'You do not have permission to add members' });
    }

    const idsToAdd = Array.isArray(memberIds) ? memberIds : [memberIds];

    // Verify users exist
    const users = await User.find({ id: { $in: idsToAdd } });
    if (users.length !== idsToAdd.length) {
      return res.status(400).json({ error: 'One or more users not found' });
    }

    // Add members (avoid duplicates)
    const newMembers = idsToAdd.filter(id => !group.members.includes(id));
    group.members.push(...newMembers);
    group.updatedAt = new Date();

    await group.save();

    res.json({
      message: `Added ${newMembers.length} new member(s)`,
      group: group
    });
  } catch (error) {
    console.error('Error adding member:', error);
    res.status(500).json({ error: 'Failed to add member' });
  }
});

// Remove member from group
router.post('/:groupId/remove-member', authenticateToken, async (req, res) => {
  try {
    const { groupId } = req.params;
    const { memberId } = req.body;
    const userId = req.user.id;

    const group = await Group.findById(groupId);

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user is admin
    if (!group.isAdmin(userId)) {
      return res.status(403).json({ error: 'Only admins can remove members' });
    }

    // Cannot remove creator
    if (memberId === group.createdBy) {
      return res.status(400).json({ error: 'Cannot remove group creator' });
    }

    // Remove member
    group.members = group.members.filter(id => id !== memberId);

    // Also remove from admins if they were admin
    group.admins = group.admins.filter(id => id !== memberId);

    group.updatedAt = new Date();
    await group.save();

    res.json({
      message: 'Member removed successfully',
      group: group
    });
  } catch (error) {
    console.error('Error removing member:', error);
    res.status(500).json({ error: 'Failed to remove member' });
  }
});

// Leave group
router.post('/:groupId/leave', authenticateToken, async (req, res) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;

    const group = await Group.findById(groupId);

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Creator cannot leave (must delete group or transfer ownership)
    if (userId === group.createdBy) {
      return res.status(400).json({ error: 'Group creator cannot leave. Delete the group or transfer ownership first.' });
    }

    // Remove user from members and admins
    group.members = group.members.filter(id => id !== userId);
    group.admins = group.admins.filter(id => id !== userId);

    group.updatedAt = new Date();
    await group.save();

    res.json({
      message: 'Left group successfully'
    });
  } catch (error) {
    console.error('Error leaving group:', error);
    res.status(500).json({ error: 'Failed to leave group' });
  }
});

// Promote member to admin
router.post('/:groupId/promote', authenticateToken, async (req, res) => {
  try {
    const { groupId } = req.params;
    const { memberId } = req.body;
    const userId = req.user.id;

    const group = await Group.findById(groupId);

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user is admin
    if (!group.isAdmin(userId)) {
      return res.status(403).json({ error: 'Only admins can promote members' });
    }

    // Check if member exists in group
    if (!group.isMember(memberId)) {
      return res.status(400).json({ error: 'User is not a member of this group' });
    }

    // Add to admins if not already
    if (!group.isAdmin(memberId)) {
      group.admins.push(memberId);
      group.updatedAt = new Date();
      await group.save();
    }

    res.json({
      message: 'Member promoted to admin',
      group: group
    });
  } catch (error) {
    console.error('Error promoting member:', error);
    res.status(500).json({ error: 'Failed to promote member' });
  }
});

// Demote admin to member
router.post('/:groupId/demote', authenticateToken, async (req, res) => {
  try {
    const { groupId } = req.params;
    const { adminId } = req.body;
    const userId = req.user.id;

    const group = await Group.findById(groupId);

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user is admin
    if (!group.isAdmin(userId)) {
      return res.status(403).json({ error: 'Only admins can demote other admins' });
    }

    // Cannot demote creator
    if (adminId === group.createdBy) {
      return res.status(400).json({ error: 'Cannot demote group creator' });
    }

    // Remove from admins
    group.admins = group.admins.filter(id => id !== adminId);
    group.updatedAt = new Date();
    await group.save();

    res.json({
      message: 'Admin demoted to member',
      group: group
    });
  } catch (error) {
    console.error('Error demoting admin:', error);
    res.status(500).json({ error: 'Failed to demote admin' });
  }
});

// Delete group (creator only)
router.delete('/:groupId', authenticateToken, async (req, res) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;

    const group = await Group.findById(groupId);

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Only creator can delete
    if (userId !== group.createdBy) {
      return res.status(403).json({ error: 'Only the group creator can delete the group' });
    }

    // Delete all group messages
    await GroupMessage.deleteMany({ groupId: groupId });

    // Delete group
    await Group.findByIdAndDelete(groupId);

    res.json({
      message: 'Group deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting group:', error);
    res.status(500).json({ error: 'Failed to delete group' });
  }
});

// Get group messages
router.get('/:groupId/messages', authenticateToken, async (req, res) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;
    const { limit = 50, before } = req.query;

    const group = await Group.findById(groupId);

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user is a member
    if (!group.isMember(userId)) {
      return res.status(403).json({ error: 'You are not a member of this group' });
    }

    // Build query
    const query = {
      groupId: groupId,
      deletedForEveryone: false,
      deletedFor: { $ne: userId }
    };

    if (before) {
      query.timestamp = { $lt: new Date(before) };
    }

    const messages = await GroupMessage.find(query)
      .sort({ timestamp: -1 })
      .limit(parseInt(limit));

    res.json(messages.reverse());
  } catch (error) {
    console.error('Error fetching group messages:', error);
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
});

// Mute/unmute group
router.post('/:groupId/mute', authenticateToken, async (req, res) => {
  try {
    const { groupId } = req.params;
    const { duration } = req.body; // duration in hours, null = forever, 0 = unmute
    const userId = req.user.id;

    const group = await Group.findById(groupId);

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    if (!group.isMember(userId)) {
      return res.status(403).json({ error: 'You are not a member of this group' });
    }

    // Remove existing mute for this user
    group.mutedBy = group.mutedBy.filter(m => m.userId !== userId);

    // Add new mute if not unmuting
    if (duration !== 0) {
      const mutedUntil = duration ? new Date(Date.now() + duration * 60 * 60 * 1000) : null;
      group.mutedBy.push({
        userId: userId,
        mutedUntil: mutedUntil
      });
    }

    await group.save();

    res.json({
      message: duration === 0 ? 'Group unmuted' : 'Group muted',
      group: group
    });
  } catch (error) {
    console.error('Error muting group:', error);
    res.status(500).json({ error: 'Failed to mute group' });
  }
});

module.exports = router;
