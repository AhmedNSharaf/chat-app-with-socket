const Message = require('./models/Message');
const User = require('./models/User');
const Group = require('./models/Group');
const GroupMessage = require('./models/GroupMessage');

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

  io.on('connection', async (socket) => {
    console.log(`User ${socket.user.username} connected`);

    // Update user presence to online
    try {
      await User.findOneAndUpdate(
        { id: socket.user.id },
        {
          isOnline: true,
          status: 'online',
          lastSeen: new Date(),
          socketId: socket.id
        }
      );

      // Broadcast user online status to all connected users
      io.emit('user_status_changed', {
        userId: socket.user.id,
        isOnline: true,
        status: 'online',
        lastSeen: new Date().toISOString()
      });
    } catch (error) {
      console.error('Error updating user presence:', error);
    }

    // Join user-specific room (convert to string for Socket.IO rooms)
    socket.join(String(socket.user.id));

    // ============ AUTO-DELIVER PENDING MESSAGES ON CONNECTION ============
    try {
      const userId = socket.user.id;
      const now = new Date();

      // PART 1: Auto-deliver Direct Messages
      const dmResult = await Message.updateMany(
        {
          receiverId: userId,
          status: 'sent'
        },
        {
          $set: {
            status: 'delivered',
            deliveredAt: now
          }
        }
      );
      //How many messages were updated (delivered now).
      if (dmResult.modifiedCount > 0) {
        // Fetch updated messages to notify senders
        const deliveredMessages = await Message.find({
          receiverId: userId,
          deliveredAt: now
        });

        // Group notifications by sender
        const senderNotifications = new Map();
        deliveredMessages.forEach(message => {
          //So we can send one notification per sender efficiently instead of spam.
          const senderId = String(message.senderId);
          if (!senderNotifications.has(senderId)) {
            senderNotifications.set(senderId, []);
          }
          //to push each delivered message info to the sender's notification list.
          senderNotifications.get(senderId).push({
            messageId: message._id.toString(),
            status: 'delivered',
            deliveredAt: now.toISOString()
          });
        });

        // Emit status updates to senders
        // update the ui of senders about delivery.
        senderNotifications.forEach((notifications, senderId) => {
          notifications.forEach(notification => {
            io.to(senderId).emit('message_status_update', notification);
          });
        });
        // logging for debugging and production monitoring
        if (process.env.NODE_ENV === 'production') {
          console.log(`[Auto-Delivery] User ${socket.user.username}: ${dmResult.modifiedCount} DMs delivered`);
        } else {
          console.log(`[Auto-Delivery] Delivered ${dmResult.modifiedCount} direct messages to ${socket.user.username}`);
        }
      }

      // PART 2: Auto-deliver Group Messages
      // Find all groups where user is a member
      const userGroups = await Group.find({ members: userId });
      const groupIds = userGroups.map(g => g._id);

      if (groupIds.length > 0) {
        // Find group messages where this user hasn't been marked as delivered
        const undeliveredGroupMessages = await GroupMessage.find({
          groupId: { $in: groupIds },
          senderId: { $ne: userId }, // Don't deliver user's own messages
          'deliveredTo.userId': { $ne: userId } // Not already in deliveredTo array
        });

        if (undeliveredGroupMessages.length > 0) {
          const deliveryEntry = {
            userId: userId,
            deliveredAt: now
          };

          // Update each message to add user to deliveredTo array
          for (const message of undeliveredGroupMessages) {
            message.deliveredTo.push(deliveryEntry);
            await message.save();

            // Notify the group about delivery
            io.to(`group_${message.groupId}`).emit('group_message_delivered', {
              messageId: message._id.toString(),
              deliveredTo: [userId]
            });
          }
          // logging for debugging and production monitoring
          if (process.env.NODE_ENV === 'production') {
            console.log(`[Auto-Delivery] User ${socket.user.username}: ${undeliveredGroupMessages.length} group messages delivered`);
          } else {
            console.log(`[Auto-Delivery] Delivered ${undeliveredGroupMessages.length} group messages to ${socket.user.username}`);
          }
        }
      }

      // Summary log for production
      if (process.env.NODE_ENV === 'production') {
        if (dmResult.modifiedCount > 0 || (undeliveredGroupMessages && undeliveredGroupMessages.length > 0)) {
          console.log(`[Auto-Delivery] User ${socket.user.username}: ${dmResult.modifiedCount} DMs, ${undeliveredGroupMessages ? undeliveredGroupMessages.length : 0} group messages`);
        }
      }
    } catch (error) {
      console.error('[Auto-Delivery] Error auto-delivering messages on connection:', error);
    }

    // Track user activity for auto-away
    let activityTimer = null;

    const resetActivityTimer = async () => {
      clearTimeout(activityTimer);

      // Update to online if was away
      const user = await User.findOne({ id: socket.user.id });
      if (user && user.status === 'away') {
        await User.findOneAndUpdate(
          { id: socket.user.id },
          { status: 'online' }
        );

        io.emit('user_status_changed', {
          userId: socket.user.id,
          status: 'online',
          isOnline: true
        });
      }

      // Set away after 2 minutes of inactivity
      activityTimer = setTimeout(async () => {
        await User.findOneAndUpdate(
          { id: socket.user.id },
          { status: 'away' }
        );

        io.emit('user_status_changed', {
          userId: socket.user.id,
          status: 'away',
          isOnline: true
        });
      }, 2 * 60 * 1000); // 2 minutes
    };

    // Reset activity timer on user activity
    socket.on('user_active', resetActivityTimer);

    // Start activity timer
    resetActivityTimer();

    // Handle message event
    socket.on('message', async (data) => {
      const { receiverId, text, mediaUrl, mediaType, replyTo } = data;
      const senderId = socket.user.id;

      try {
        // Create message object
        const message = new Message({
          senderId: parseInt(senderId),
          receiverId: parseInt(receiverId),
          text: text || '',
          mediaUrl,
          mediaType,
          timestamp: new Date(),
          status: 'sent',
          replyTo: replyTo || null
        });

        // Save message to database
        await message.save();

        // Check if receiver is currently online and auto-deliver
        const receiver = await User.findOne({ id: parseInt(receiverId) });
        if (receiver && receiver.isOnline) {
          // Receiver is online, mark as delivered immediately
          message.status = 'delivered';
          message.deliveredAt = new Date();
          await message.save();

          // Notify sender about immediate delivery
          socket.emit('message_status_update', {
            messageId: message._id.toString(),
            status: 'delivered',
            deliveredAt: message.deliveredAt.toISOString()
          });
        }

        // Populate replyTo if it exists
        if (message.replyTo) {
          await message.populate('replyTo');
        }

        // Convert to plain object and ensure timestamp is ISO string
        const messageObj = message.toObject();
        messageObj.id = message._id.toString();
        messageObj.timestamp = message.timestamp.toISOString();

        // Emit to receiver
        io.to(String(receiverId)).emit('receive_message', messageObj);

        // Emit back to sender for confirmation
        socket.emit('message_sent', messageObj);
      } catch (error) {
        console.error('Error saving message:', error);
        socket.emit('message_error', { error: 'Failed to send message' });
      }
    });

    // Handle message delivered event
    socket.on('message_delivered', async (data) => {
      const { messageId } = data;
      try {
        const message = await Message.findById(messageId);
        if (message && message.status === 'sent') {
          message.status = 'delivered';
          message.deliveredAt = new Date();
          await message.save();

          // Notify sender about delivery
          io.to(String(message.senderId)).emit('message_status_update', {
            messageId: message._id.toString(),
            status: 'delivered',
            deliveredAt: message.deliveredAt.toISOString()
          });
        }
      } catch (error) {
        console.error('Error updating message status:', error);
      }
    });

    // Handle message read event
    socket.on('message_read', async (data) => {
      const { messageId } = data;
      try {
        const message = await Message.findById(messageId);
        if (message && (message.status === 'sent' || message.status === 'delivered')) {
          message.status = 'read';
          message.readAt = new Date();
          await message.save();

          // Notify sender about read status
          io.to(String(message.senderId)).emit('message_status_update', {
            messageId: message._id.toString(),
            status: 'read',
            readAt: message.readAt.toISOString()
          });
        }
      } catch (error) {
        console.error('Error updating message status:', error);
      }
    });

    // Handle typing indicator
    socket.on('typing', (data) => {
      const { receiverId, isTyping } = data;
      io.to(String(receiverId)).emit('user_typing', {
        userId: socket.user.id,
        username: socket.user.username,
        isTyping
      });
    });

    // Handle message edit
    socket.on('edit_message', async (data) => {
      const { messageId, newText } = data;
      try {
        const message = await Message.findById(messageId);
        if (message && message.senderId === socket.user.id) {
          message.text = newText;
          message.isEdited = true;
          message.editedAt = new Date();
          await message.save();

          const messageObj = message.toObject();
          messageObj.id = message._id.toString();
          messageObj.timestamp = message.timestamp.toISOString();

          // Notify both users
          //notify receiver
          io.to(String(message.receiverId)).emit('message_edited', messageObj);
          //notify sender
          socket.emit('message_edited', messageObj);
        }
      } catch (error) {
        console.error('Error editing message:', error);
        socket.emit('edit_error', { error: 'Failed to edit message' });
      }
    });

    // Handle message delete
    socket.on('delete_message', async (data) => {
      const { messageId, deleteForEveryone } = data;
      try {
        const message = await Message.findById(messageId);
        if (!message) return;

        if (deleteForEveryone && message.senderId === socket.user.id) {
          // Delete for everyone
          message.deletedForEveryone = true;
          await message.save();

          // Notify both users
          io.to(String(message.receiverId)).emit('message_deleted', { messageId: message._id.toString(), deleteForEveryone: true });
          socket.emit('message_deleted', { messageId: message._id.toString(), deleteForEveryone: true });
        } else {
          // Delete for me only
          if (!message.deletedFor.includes(socket.user.id)) {
            message.deletedFor.push(socket.user.id);
            await message.save();
          }
          socket.emit('message_deleted', { messageId: message._id.toString(), deleteForEveryone: false });
        }
      } catch (error) {
        console.error('Error deleting message:', error);
        socket.emit('delete_error', { error: 'Failed to delete message' });
      }
    });

    // Handle message reaction
    socket.on('add_reaction', async (data) => {
      const { messageId, emoji } = data;
      try {
        const message = await Message.findById(messageId);
        if (message) {
          // Remove existing reaction from this user if he has already reacted
          message.reactions = message.reactions.filter(r => r.userId !== socket.user.id);
          //then add the new reaction
          message.reactions.push({
            userId: socket.user.id,
            emoji,
            timestamp: new Date()
          });
          await message.save();

          const reactionData = {
            messageId: message._id.toString(),
            userId: socket.user.id,
            emoji,
            reactions: message.reactions
          };

          // Notify both users
          // emitting to all sockets of the receiver if he has multiple connections
          io.to(String(message.receiverId)).emit('reaction_added', reactionData);
          // emitting to all sockets of the sender if he has multiple connections
          io.to(String(message.senderId)).emit('reaction_added', reactionData);
        }
      } catch (error) {
        console.error('Error adding reaction:', error);
      }
    });

    // Handle remove reaction
    socket.on('remove_reaction', async (data) => {
      const { messageId } = data;
      try {
        const message = await Message.findById(messageId);
        if (message) {
          message.reactions = message.reactions.filter(r => r.userId !== socket.user.id);
          await message.save();

          const reactionData = {
            messageId: message._id.toString(),
            userId: socket.user.id,
            reactions: message.reactions
          };

          // Notify both users
          // emitting to all sockets of the receiver if he has multiple connections
          io.to(String(message.receiverId)).emit('reaction_removed', reactionData);
          //emitting to all sockets of the sender if he has multiple connections
          io.to(String(message.senderId)).emit('reaction_removed', reactionData);
        }
      } catch (error) {
        console.error('Error removing reaction:', error);
      }
    });

    // Handle custom status change
    socket.on('change_status', async (data) => {
      const { status, customStatus } = data;

      try {
        await User.findOneAndUpdate(
          { id: socket.user.id },
          {
            status,
            customStatus,
            statusUpdatedAt: new Date()
          }
        );

        io.emit('user_status_changed', {
          userId: socket.user.id,
          status,
          customStatus,
          isOnline: true
        });
      } catch (error) {
        console.error('Error changing status:', error);
      }
    });

    // ============ GROUP MESSAGE HANDLERS ============

    // Join group rooms
    socket.on('join_groups', async (data) => {
      try {
        const { groupIds } = data;

        // Join all group rooms
        groupIds.forEach(groupId => {
          socket.join(`group_${groupId}`);
        });

        console.log(`User ${socket.user.username} joined ${groupIds.length} groups`);
      } catch (error) {
        console.error('Error joining groups:', error);
      }
    });

    // Leave group room
    socket.on('leave_group', (data) => {
      const { groupId } = data;
      // make my socket leave the group room named with (`group_${groupId}`)
      socket.leave(`group_${groupId}`);
      console.log(`User ${socket.user.username} left group ${groupId}`);
    });

    // Send group message
    socket.on('group_message', async (data) => {
      const { groupId, text, mediaUrl, mediaType, fileName, fileSize, replyTo } = data;
      const senderId = socket.user.id;

      try {
        // Verify user is member of group
        const group = await Group.findById(groupId);
        if (!group || !group.isMember(senderId)) {
          socket.emit('group_message_error', { error: 'You are not a member of this group' });
          return;
        }

        // Create group message
        const groupMessage = new GroupMessage({
          groupId,
          senderId,
          text,
          mediaUrl,
          mediaType,
          fileName,
          fileSize,
          timestamp: new Date(),
          replyTo: replyTo || undefined
        });

        await groupMessage.save();

        // Update group's last message
        group.lastMessage = {
          text: text || (mediaType ? `[${mediaType}]` : ''),
          senderId,
          timestamp: new Date()
        };
        group.updatedAt = new Date();
        await group.save();

        const messageData = {
          ...groupMessage.toObject(),
          _id: groupMessage._id.toString()
        };

        // Broadcast to all group members
        io.to(`group_${groupId}`).emit('group_message_received', messageData);

        // Mark as delivered to online members
        const onlineMembers = await User.find({
          id: { $in: group.members.filter(m => m !== senderId) },
          isOnline: true
        });

        const deliveredTo = onlineMembers.map(user => ({
          userId: user.id,
          deliveredAt: new Date()
        }));

        if (deliveredTo.length > 0) {
          groupMessage.deliveredTo = deliveredTo;
          await groupMessage.save();

          io.to(`group_${groupId}`).emit('group_message_delivered', {
            messageId: groupMessage._id.toString(),
            deliveredTo: deliveredTo.map(d => d.userId)
          });
        }
      } catch (error) {
        console.error('Error sending group message:', error);
        socket.emit('group_message_error', { error: 'Failed to send message' });
      }
    });

    // Group typing indicator
    socket.on('group_typing', async (data) => {
      const { groupId } = data;
      const userId = socket.user.id;

      try {
        // Verify user is a member of the group
        const group = await Group.findOne({ _id: groupId, members: userId });
        if (!group) {
          return;
        }

        socket.to(`group_${groupId}`).emit('group_user_typing', {
          groupId,
          userId,
          username: socket.user.username
        });
      } catch (error) {
        console.error('Error in group typing:', error);
      }
    });

    // Mark group message as read
    socket.on('group_message_read', async (data) => {
      const { groupId, messageIds } = data;
      const userId = socket.user.id;

      try {
        // Verify user is a member of the group
        const group = await Group.findOne({ _id: groupId, members: userId });
        if (!group) {
          console.error('User not authorized to read messages in this group');
          return;
        }

        // Update read receipts for multiple messages
        await GroupMessage.updateMany(
          {
            _id: { $in: messageIds },
            groupId,
            'readBy.userId': { $ne: userId }
          },
          {
            $push: {
              readBy: {
                userId,
                readAt: new Date()
              }
            }
          }
        );

        // Notify group
        io.to(`group_${groupId}`).emit('group_messages_read', {
          groupId,
          messageIds,
          userId,
          readAt: new Date().toISOString()
        });
      } catch (error) {
        console.error('Error marking group messages as read:', error);
      }
    });

    // Edit group message
    socket.on('edit_group_message', async (data) => {
      const { messageId, newText } = data;

      try {
        const message = await GroupMessage.findById(messageId);

        if (!message) {
          socket.emit('edit_error', { error: 'Message not found' });
          return;
        }

        if (message.senderId !== socket.user.id) {
          socket.emit('edit_error', { error: 'You can only edit your own messages' });
          return;
        }

        if (message.mediaType) {
          socket.emit('edit_error', { error: 'Cannot edit media messages' });
          return;
        }

        message.text = newText;
        message.isEdited = true;
        message.editedAt = new Date();
        await message.save();

        const editData = {
          messageId: message._id.toString(),
          newText,
          isEdited: true,
          editedAt: message.editedAt.toISOString()
        };

        io.to(`group_${message.groupId}`).emit('group_message_edited', editData);
      } catch (error) {
        console.error('Error editing group message:', error);
        socket.emit('edit_error', { error: 'Failed to edit message' });
      }
    });

    // Delete group message
    socket.on('delete_group_message', async (data) => {
      const { messageId, deleteForEveryone } = data;

      try {
        const message = await GroupMessage.findById(messageId);

        if (!message) {
          socket.emit('delete_error', { error: 'Message not found' });
          return;
        }

        const group = await Group.findById(message.groupId);

        if (deleteForEveryone) {
          // Only sender or admin can delete for everyone
          if (message.senderId !== socket.user.id && !group.isAdmin(socket.user.id)) {
            socket.emit('delete_error', { error: 'You can only delete your own messages for everyone' });
            return;
          }

          message.deletedForEveryone = true;
          await message.save();

          io.to(`group_${message.groupId}`).emit('group_message_deleted', {
            messageId: message._id.toString(),
            deleteForEveryone: true
          });
        } else {
          // Delete for me only
          if (!message.deletedFor.includes(socket.user.id)) {
            message.deletedFor.push(socket.user.id);
            await message.save();
          }
          socket.emit('group_message_deleted', {
            messageId: message._id.toString(),
            deleteForEveryone: false
          });
        }
      } catch (error) {
        console.error('Error deleting group message:', error);
        socket.emit('delete_error', { error: 'Failed to delete message' });
      }
    });

    // Add reaction to group message
    socket.on('add_group_reaction', async (data) => {
      const { messageId, emoji } = data;

      try {
        const message = await GroupMessage.findById(messageId);
        if (message) {
          // Remove existing reaction from this user if any
          message.reactions = message.reactions.filter(r => r.userId !== socket.user.id);

          // Add new reaction
          message.reactions.push({
            userId: socket.user.id,
            emoji,
            timestamp: new Date()
          });
          await message.save();

          const reactionData = {
            messageId: message._id.toString(),
            userId: socket.user.id,
            emoji,
            reactions: message.reactions
          };

          io.to(`group_${message.groupId}`).emit('group_reaction_added', reactionData);
        }
      } catch (error) {
        console.error('Error adding group reaction:', error);
      }
    });

    // Remove reaction from group message
    socket.on('remove_group_reaction', async (data) => {
      const { messageId } = data;

      try {
        const message = await GroupMessage.findById(messageId);
        if (message) {
          message.reactions = message.reactions.filter(r => r.userId !== socket.user.id);
          await message.save();

          const reactionData = {
            messageId: message._id.toString(),
            userId: socket.user.id,
            reactions: message.reactions
          };

          io.to(`group_${message.groupId}`).emit('group_reaction_removed', reactionData);
        }
      } catch (error) {
        console.error('Error removing group reaction:', error);
      }
    });

    // Group member added/removed events
    socket.on('member_added_to_group', (data) => {
      const { groupId, memberIds } = data;
      io.to(`group_${groupId}`).emit('group_member_added', { groupId, memberIds });
    });

    socket.on('member_removed_from_group', (data) => {
      const { groupId, memberId } = data;
      io.to(`group_${groupId}`).emit('group_member_removed', { groupId, memberId });
    });

    // Calculator calculation event
    socket.on('calculate', (data) => {
      try {
        const { expression } = data;

        // Remove trailing operators before calculation
        let cleanExpression = expression.trim();
        while (cleanExpression.length > 0 && /[+\-×÷%]$/.test(cleanExpression)) {
          cleanExpression = cleanExpression.slice(0, -1);
        }

        if (!cleanExpression) {
          socket.emit('calculation_result', { result: '0', error: false });
          return;
        }

        // Replace symbols for evaluation
        cleanExpression = cleanExpression
          .replace(/×/g, '*')
          .replace(/÷/g, '/')
          .replace(/%/g, '/100');

        // Evaluate the expression safely
        const result = Function('"use strict"; return (' + cleanExpression + ')')();

        // Format result
        let formattedResult;
        if (isNaN(result) || !isFinite(result)) {
          formattedResult = 'Error';
        } else if (result === Math.floor(result)) {
          formattedResult = result.toString();
        } else {
          formattedResult = parseFloat(result.toFixed(8)).toString();
        }

        socket.emit('calculation_result', { result: formattedResult, error: false });
      } catch (error) {
        socket.emit('calculation_result', { result: 'Error', error: true });
      }
    });

    socket.on('disconnect', async () => {
      console.log(`User ${socket.user.username} disconnected`);

      // Clear activity timer
      clearTimeout(activityTimer);

      // Update user presence to offline
      try {
        await User.findOneAndUpdate(
          { id: socket.user.id },
          {
            isOnline: false,
            status: 'offline',
            lastSeen: new Date(),
            socketId: null
          }
        );

        // Broadcast user offline status
        io.emit('user_status_changed', {
          userId: socket.user.id,
          isOnline: false,
          status: 'offline',
          lastSeen: new Date().toISOString()
        });
      } catch (error) {
        console.error('Error updating user offline status:', error);
      }
    });
  });
}

module.exports = { handleSocketConnection };
