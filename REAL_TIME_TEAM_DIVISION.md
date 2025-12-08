# Real-Time Features Team Division
## 8 Members - Socket.io & Real-Time Communication Focus

---

## 🎯 Division Strategy

**Focus:** Only the real-time communication aspects (Socket.io, WebSocket, live updates)
**Excluded:** Authentication, UI design, basic CRUD operations

---

## 👥 Team Member Assignments

### **Member 1: Socket.io Connection & Authentication**

**Responsibilities:**
- Socket.io server setup
- WebSocket connection handling
- JWT authentication for socket connections
- Connection/disconnection events
- Socket middleware

**Backend Files:**
```
backend/
├── server.js (Lines 12-18: Socket.io initialization)
├── socket.js (Lines 1-50: Connection setup, authentication)
```

**Code Sections:**
```javascript
// server.js - Socket.io setup
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// socket.js - JWT authentication middleware
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  // JWT verification
});

io.on('connection', async (socket) => {
  console.log(`User ${socket.user.username} connected`);
  // Connection logic
});
```

**Frontend Files:**
```
flutter_app/lib/
├── services/socket_service.dart (Lines 1-40: Connection setup)
```

**Key Concepts:**
- WebSocket handshake
- JWT token passing via socket auth
- Connection state management
- Socket.io rooms concept

**Demo:**
- Show connection establishment
- JWT token verification
- Connection/disconnection logs
- Socket authentication flow

---

### **Member 2: User Presence & Status System**

**Responsibilities:**
- Online/offline status tracking
- Away status (auto after 5 min inactivity)
- Custom status messages
- Last seen timestamps
- Real-time presence updates

**Backend Files:**
```
backend/
├── socket.js (Lines 28-49: User presence update on connect)
├── socket.js (Lines 157-197: Activity tracking & auto-away)
├── socket.js (Lines 422-445: Status change handler)
├── socket.js (Lines 800-828: Disconnect handling)
```

**Code Sections:**
```javascript
// On connection - Update to online
await User.findOneAndUpdate(
  { id: socket.user.id },
  {
    isOnline: true,
    status: 'online',
    lastSeen: new Date(),
    socketId: socket.id
  }
);

// Broadcast status change
io.emit('user_status_changed', {
  userId: socket.user.id,
  isOnline: true,
  status: 'online'
});

// Auto-away timer (5 minutes)
activityTimer = setTimeout(async () => {
  await User.findOneAndUpdate(
    { id: socket.user.id },
    { status: 'away' }
  );
}, 5 * 60 * 1000);

// On disconnect - Update to offline
await User.findOneAndUpdate(
  { id: socket.user.id },
  {
    isOnline: false,
    status: 'offline',
    lastSeen: new Date()
  }
);
```

**Frontend Files:**
```
flutter_app/lib/
├── services/socket_service.dart (Lines 179-199: User presence events)
```

**Key Concepts:**
- Real-time presence tracking
- Activity-based status updates
- Timer-based auto-away
- Broadcasting status to all users

**Demo:**
- User goes online/offline
- Auto-away after inactivity
- Custom status setting
- Last seen display

---

### **Member 3: Direct Message Sending & Delivery**

**Responsibilities:**
- Real-time message sending
- Message delivery to recipient
- Auto-delivery of pending messages
- Message routing between users
- Acknowledgment system

**Backend Files:**
```
backend/
├── socket.js (Lines 54-106: Auto-delivery on connection)
├── socket.js (Lines 199-255: Message sending handler)
```

**Code Sections:**
```javascript
// Auto-deliver pending messages on connection
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

// Send message handler
socket.on('message', async (data) => {
  const { receiverId, text, mediaUrl, mediaType, replyTo } = data;

  const message = new Message({
    senderId: socket.user.id,
    receiverId: parseInt(receiverId),
    text,
    timestamp: new Date(),
    status: 'sent'
  });

  await message.save();

  // Auto-deliver if receiver is online
  const receiver = await User.findOne({ id: parseInt(receiverId) });
  if (receiver && receiver.isOnline) {
    message.status = 'delivered';
    message.deliveredAt = new Date();
    await message.save();
  }

  // Emit to receiver
  io.to(String(receiverId)).emit('receive_message', messageObj);

  // Confirm to sender
  socket.emit('message_sent', messageObj);
});
```

**Frontend Files:**
```
flutter_app/lib/
├── services/socket_service.dart (Lines 40-54: Send message)
├── services/socket_service.dart (Lines 95-106: Receive message)
```

**Key Concepts:**
- Socket rooms for user targeting
- Pending message queue
- Auto-delivery mechanism
- Bidirectional communication

**Demo:**
- Send message from User A to User B
- Show real-time delivery
- Demonstrate pending message delivery when user comes online

---

### **Member 4: Message Status Tracking (Delivered & Read)**

**Responsibilities:**
- Message delivery receipts
- Read receipts
- Status update broadcasting
- Three-tier status (sent → delivered → read)

**Backend Files:**
```
backend/
├── socket.js (Lines 257-277: Message delivered handler)
├── socket.js (Lines 279-299: Message read handler)
```

**Code Sections:**
```javascript
// Mark message as delivered
socket.on('message_delivered', async (data) => {
  const { messageId } = data;
  const message = await Message.findById(messageId);

  if (message && message.status === 'sent') {
    message.status = 'delivered';
    message.deliveredAt = new Date();
    await message.save();

    // Notify sender
    io.to(String(message.senderId)).emit('message_status_update', {
      messageId: message._id.toString(),
      status: 'delivered',
      deliveredAt: message.deliveredAt.toISOString()
    });
  }
});

// Mark message as read
socket.on('message_read', async (data) => {
  const { messageId } = data;
  const message = await Message.findById(messageId);

  if (message && (message.status === 'sent' || message.status === 'delivered')) {
    message.status = 'read';
    message.readAt = new Date();
    await message.save();

    // Notify sender
    io.to(String(message.senderId)).emit('message_status_update', {
      messageId: message._id.toString(),
      status: 'read',
      readAt: message.readAt.toISOString()
    });
  }
});
```

**Frontend Files:**
```
flutter_app/lib/
├── services/socket_service.dart (Lines 57-64: Mark delivered)
├── services/socket_service.dart (Lines 109-113: Status updates)
```

**Key Concepts:**
- Read receipts (blue checkmarks)
- Delivery confirmation
- Status change events
- Real-time status broadcasting

**Demo:**
- Send message (single tick)
- Delivery receipt (double tick)
- Read receipt (blue double tick)

---

### **Member 5: Typing Indicators & Real-Time Feedback**

**Responsibilities:**
- Typing indicator signals
- Real-time typing status
- Debouncing typing events
- User activity signals

**Backend Files:**
```
backend/
├── socket.js (Lines 301-309: Typing indicator)
├── socket.js (Lines 194: User activity handler)
```

**Code Sections:**
```javascript
// Typing indicator
socket.on('typing', (data) => {
  const { receiverId, isTyping } = data;

  io.to(String(receiverId)).emit('user_typing', {
    userId: socket.user.id,
    username: socket.user.username,
    isTyping
  });
});

// User activity signal (resets away timer)
socket.on('user_active', resetActivityTimer);
```

**Frontend Files:**
```
flutter_app/lib/
├── services/socket_service.dart (Lines 67-69: Send typing)
├── services/socket_service.dart (Lines 115-119: Receive typing)
├── services/socket_service.dart (Lines 193-195: Send activity)
```

**Key Concepts:**
- Real-time feedback
- Event debouncing
- Lightweight signaling
- User experience enhancement

**Demo:**
- Type in chat → "User is typing..." appears
- Stop typing → indicator disappears
- Activity signal prevents auto-away

---

### **Member 6: Real-Time Message Operations (Edit & Delete)**

**Responsibilities:**
- Real-time message editing
- Message deletion (for me / for everyone)
- Broadcasting edits/deletes
- Timestamp tracking for edits

**Backend Files:**
```
backend/
├── socket.js (Lines 311-334: Edit message)
├── socket.js (Lines 336-363: Delete message)
```

**Code Sections:**
```javascript
// Edit message
socket.on('edit_message', async (data) => {
  const { messageId, newText } = data;
  const message = await Message.findById(messageId);

  if (message && message.senderId === socket.user.id) {
    message.text = newText;
    message.isEdited = true;
    message.editedAt = new Date();
    await message.save();

    const messageObj = message.toObject();

    // Notify both users
    io.to(String(message.receiverId)).emit('message_edited', messageObj);
    socket.emit('message_edited', messageObj);
  }
});

// Delete message
socket.on('delete_message', async (data) => {
  const { messageId, deleteForEveryone } = data;
  const message = await Message.findById(messageId);

  if (deleteForEveryone && message.senderId === socket.user.id) {
    // Delete for everyone
    message.deletedForEveryone = true;
    await message.save();

    io.to(String(message.receiverId)).emit('message_deleted', {
      messageId: message._id.toString(),
      deleteForEveryone: true
    });
    socket.emit('message_deleted', { messageId, deleteForEveryone: true });
  } else {
    // Delete for me only
    message.deletedFor.push(socket.user.id);
    await message.save();
    socket.emit('message_deleted', { messageId, deleteForEveryone: false });
  }
});
```

**Frontend Files:**
```
flutter_app/lib/
├── services/socket_service.dart (Lines 72-74: Edit message)
├── services/socket_service.dart (Lines 76-82: Delete message)
├── services/socket_service.dart (Lines 121-133: Edit/Delete events)
```

**Key Concepts:**
- Real-time synchronization
- Two deletion modes
- Edit history tracking
- Instant UI updates

**Demo:**
- Edit a message → shows "edited" tag
- Delete for me → message disappears locally
- Delete for everyone → disappears for both

---

### **Member 7: Reactions & Real-Time Interactions**

**Responsibilities:**
- Emoji reactions on messages
- Real-time reaction updates
- Multiple reactions handling
- Reaction removal

**Backend Files:**
```
backend/
├── socket.js (Lines 365-396: Add reaction)
├── socket.js (Lines 398-420: Remove reaction)
```

**Code Sections:**
```javascript
// Add reaction
socket.on('add_reaction', async (data) => {
  const { messageId, emoji } = data;
  const message = await Message.findById(messageId);

  if (message) {
    // Remove existing reaction from this user
    message.reactions = message.reactions.filter(
      r => r.userId !== socket.user.id
    );

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

    // Notify both users
    io.to(String(message.receiverId)).emit('reaction_added', reactionData);
    io.to(String(message.senderId)).emit('reaction_added', reactionData);
  }
});

// Remove reaction
socket.on('remove_reaction', async (data) => {
  const { messageId } = data;
  const message = await Message.findById(messageId);

  if (message) {
    message.reactions = message.reactions.filter(
      r => r.userId !== socket.user.id
    );
    await message.save();

    // Notify both users
    io.to(String(message.receiverId)).emit('reaction_removed', reactionData);
    io.to(String(message.senderId)).emit('reaction_removed', reactionData);
  }
});
```

**Frontend Files:**
```
flutter_app/lib/
├── services/socket_service.dart (Lines 84-92: Add/Remove reaction)
├── services/socket_service.dart (Lines 134-144: Reaction events)
```

**Key Concepts:**
- Real-time emoji reactions
- Array manipulation
- Multi-user reactions
- Instant feedback

**Demo:**
- Add reaction to message
- See reaction appear instantly
- Remove reaction
- Multiple users reacting

---

### **Member 8: Group Chat Real-Time System**

**Responsibilities:**
- Group message broadcasting
- Group typing indicators
- Multi-user read receipts
- Group message delivery tracking
- Room-based communication

**Backend Files:**
```
backend/
├── socket.js (Lines 449-463: Join groups)
├── socket.js (Lines 465-541: Send group message)
├── socket.js (Lines 543-605: Group typing & read receipts)
├── socket.js (Lines 607-746: Group message operations)
```

**Code Sections:**
```javascript
// Join group rooms
socket.on('join_groups', async (data) => {
  const { groupIds } = data;
  groupIds.forEach(groupId => {
    socket.join(`group_${groupId}`);
  });
});

// Send group message
socket.on('group_message', async (data) => {
  const { groupId, text, mediaUrl } = data;

  const groupMessage = new GroupMessage({
    groupId,
    senderId: socket.user.id,
    text,
    timestamp: new Date()
  });

  await groupMessage.save();

  // Broadcast to all group members
  io.to(`group_${groupId}`).emit('group_message_received', messageData);

  // Mark as delivered to online members
  const onlineMembers = await User.find({
    id: { $in: group.members },
    isOnline: true
  });

  const deliveredTo = onlineMembers.map(user => ({
    userId: user.id,
    deliveredAt: new Date()
  }));

  groupMessage.deliveredTo = deliveredTo;
  await groupMessage.save();
});

// Group typing indicator
socket.on('group_typing', async (data) => {
  const { groupId } = data;

  socket.to(`group_${groupId}`).emit('group_user_typing', {
    groupId,
    userId: socket.user.id,
    username: socket.user.username
  });
});

// Group read receipts
socket.on('group_message_read', async (data) => {
  const { groupId, messageIds } = data;

  await GroupMessage.updateMany(
    {
      _id: { $in: messageIds },
      groupId,
      'readBy.userId': { $ne: userId }
    },
    {
      $push: {
        readBy: {
          userId: socket.user.id,
          readAt: new Date()
        }
      }
    }
  );

  // Notify group
  io.to(`group_${groupId}`).emit('group_messages_read', {
    groupId,
    messageIds,
    userId: socket.user.id,
    readAt: new Date().toISOString()
  });
});
```

**Frontend Files:**
```
flutter_app/lib/
├── services/socket_service.dart (Lines 201-400: Group events)
```

**Key Concepts:**
- Socket.io rooms for groups
- Broadcasting to multiple users
- Multi-user delivery tracking
- Group-specific events
- Read receipt aggregation

**Demo:**
- Send message to group
- All members receive instantly
- Show typing in group
- Multi-user read receipts

---

## 📊 Workload Distribution

| Member | Backend Lines | Frontend Lines | Complexity | Socket Events |
|--------|---------------|----------------|------------|---------------|
| 1 | ~50 | ~40 | Medium | 2 |
| 2 | ~200 | ~20 | Medium | 4 |
| 3 | ~150 | ~40 | High | 2 |
| 4 | ~80 | ~30 | Medium | 3 |
| 5 | ~50 | ~30 | Low | 2 |
| 6 | ~100 | ~40 | Medium | 4 |
| 7 | ~80 | ~30 | Medium | 4 |
| 8 | ~300 | ~200 | High | 10+ |

---

## 🎯 Presentation Order

```
1. Member 1: Socket Connection & Auth
   ↓ (Foundation)

2. Member 2: User Presence System
   ↓ (Status tracking)

3. Member 3: Message Sending & Delivery
   ↓ (Core messaging)

4. Member 4: Message Status Tracking
   ↓ (Receipts)

5. Member 5: Typing Indicators
   ↓ (Real-time feedback)

6. Member 6: Edit & Delete Operations
   ↓ (Message operations)

7. Member 7: Reactions
   ↓ (Interactions)

8. Member 8: Group Chat System
   ↓ (Advanced multi-user)
```

---

## 🔑 Key Socket.io Concepts to Explain

### All Members Should Understand:

1. **WebSocket vs HTTP**
   - HTTP: Request-response
   - WebSocket: Persistent bidirectional connection

2. **Socket.io Events**
   - `emit()` - Send event
   - `on()` - Listen for event
   - `to()` - Target specific room/user
   - `broadcast` - Send to all except sender

3. **Rooms**
   - User rooms: `socket.join(String(userId))`
   - Group rooms: `socket.join(`group_${groupId}`)`

4. **Event Flow**
```
Client A                Server                Client B
   |                      |                      |
   |---emit('message')---->|                      |
   |                      |---to(B).emit()------>|
   |<--emit('sent')-------|                      |
   |                      |                      |
```

---

## 🎤 Demo Scenarios

### Scenario 1: Basic Real-Time Flow
1. **Member 1**: Connect users A & B
2. **Member 2**: Show online status
3. **Member 3**: A sends message to B
4. **Member 4**: Show delivery & read receipts
5. **Member 5**: Show typing indicator

### Scenario 2: Advanced Operations
1. **Member 6**: Edit a message
2. **Member 6**: Delete a message
3. **Member 7**: Add reactions
4. **Member 5**: Show typing while editing

### Scenario 3: Group Communication
1. **Member 8**: Create group & join rooms
2. **Member 8**: Send group message
3. **Member 8**: Multiple users read
4. **Member 8**: Group typing indicator

---

## 💡 Technical Deep Dive Points

### Member 1 - Socket Authentication:
- Why JWT in socket handshake?
- How middleware validates tokens?
- Connection state management

### Member 2 - Presence System:
- Timer-based auto-away mechanism
- Broadcasting to all connected users
- LastSeen vs IsOnline difference

### Member 3 - Message Delivery:
- Auto-delivery queue concept
- Online user detection
- Message routing logic

### Member 4 - Status Tracking:
- Three-tier status system
- Timestamp precision
- Status update broadcasting

### Member 5 - Typing Indicators:
- Lightweight event design
- Debouncing strategy
- Activity signal purpose

### Member 6 - Message Operations:
- Edit timestamp tracking
- Delete modes (me vs everyone)
- Synchronization logic

### Member 7 - Reactions:
- Array manipulation
- Multiple reactions handling
- Real-time updates

### Member 8 - Group System:
- Socket rooms architecture
- Multi-user delivery
- Read receipt aggregation
- Broadcasting strategies

---

## 📝 Common Questions to Prepare For

**Q: Why Socket.io instead of plain WebSocket?**
A: Socket.io provides fallback mechanisms, automatic reconnection, rooms, and easier event handling.

**Q: How do you ensure message delivery?**
A: Three-tier status (sent → delivered → read), auto-delivery on reconnection, and database persistence.

**Q: What happens if user disconnects?**
A: Messages are queued in database with 'sent' status and auto-delivered when user reconnects.

**Q: How do typing indicators work?**
A: Client emits 'typing' event to server, server broadcasts to specific user room, receiver displays indicator.

**Q: How are read receipts handled in groups?**
A: Each message has `readBy` array tracking userId and readAt timestamp for each member.

**Q: How do you prevent message duplication?**
A: Database IDs, acknowledgments, and idempotent operations.

**Q: What's the difference between `emit()` and `broadcast`?**
A: `emit()` sends to specific target, `broadcast` sends to all except sender.

**Q: How do Socket.io rooms work?**
A: Rooms are virtual channels. Users join rooms, and events can be emitted to all users in a room.

---

## 🏆 Success Criteria

✅ Explain WebSocket/Socket.io basics
✅ Show real-time event flow
✅ Demonstrate your specific feature
✅ Explain server-client communication
✅ Show code and live demo
✅ Answer technical questions
✅ Connect your part to others

---

## 📚 Study Resources

### All Members:
- Socket.io Documentation: https://socket.io/docs/
- WebSocket Protocol: RFC 6455
- Event-driven architecture
- Real-time system design

### Specific Topics:
- **Member 1**: JWT, Socket middleware
- **Member 2**: Timers in Node.js, broadcasting
- **Member 3**: Message queues, auto-delivery
- **Member 4**: Status tracking, acknowledgments
- **Member 5**: Debouncing, event throttling
- **Member 6**: Data synchronization, CRDT concepts
- **Member 7**: Array operations, real-time updates
- **Member 8**: Rooms, multi-user systems, pub-sub

---

## ⚡ Quick Reference Card (Print This!)

```
┌─────────────────────────────────────────────┐
│ Member 1: Socket Connection & Auth         │
│ Events: connection, disconnect              │
│ Demo: JWT auth, connect/disconnect         │
├─────────────────────────────────────────────┤
│ Member 2: Presence & Status                 │
│ Events: user_status_changed, user_active   │
│ Demo: Online→Away→Offline, custom status   │
├─────────────────────────────────────────────┤
│ Member 3: Message Sending                   │
│ Events: message, receive_message            │
│ Demo: Send message, auto-delivery           │
├─────────────────────────────────────────────┤
│ Member 4: Message Status                    │
│ Events: message_delivered, message_read     │
│ Demo: ✓ → ✓✓ → ✓✓ (blue)                   │
├─────────────────────────────────────────────┤
│ Member 5: Typing Indicators                 │
│ Events: typing, user_typing                 │
│ Demo: Type → "User is typing..."           │
├─────────────────────────────────────────────┤
│ Member 6: Edit & Delete                     │
│ Events: edit_message, delete_message        │
│ Demo: Edit → (edited), Delete options       │
├─────────────────────────────────────────────┤
│ Member 7: Reactions                         │
│ Events: add_reaction, remove_reaction       │
│ Demo: Add 👍, remove, multiple reactions    │
├─────────────────────────────────────────────┤
│ Member 8: Group Chat                        │
│ Events: join_groups, group_message, etc.   │
│ Demo: Group message, multi-user receipts   │
└─────────────────────────────────────────────┘
```

---

**Good luck presenting the real-time features! 🚀📡**
