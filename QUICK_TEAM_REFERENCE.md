# Quick Team Reference - Who Does What?

## 👥 At a Glance

```
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND (4 Members)                       │
├─────────────────────────────────────────────────────────────┤
│ Member 1: Authentication System                             │
│ Member 3: Real-Time Direct Messaging                        │
│ Member 5: Advanced Features (Edit, Delete, React, Media)    │
│ Member 7: Group Chat System                                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (4 Members)                      │
├─────────────────────────────────────────────────────────────┤
│ Member 2: Authentication UI & Profile                       │
│ Member 4: Real-Time Chat UI                                 │
│ Member 6: Advanced Features UI                              │
│ Member 8: Group Chat UI + Server Config                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Member 1: Backend Authentication
**Keywords:** JWT, bcrypt, User Model, Login, Register, Password Reset

**Main Files:**
- `backend/routes/auth.js` (Registration, Login)
- `backend/middleware/auth.js`
- `backend/models/User.js`

**Demo:** Register → Login → Show JWT token → Account locking

---

## 📋 Member 2: Frontend Authentication
**Keywords:** Login Screen, Register Screen, Profile, GetX, Token Storage

**Main Files:**
- `flutter_app/lib/screens/login_screen.dart`
- `flutter_app/lib/screens/register_screen.dart`
- `flutter_app/lib/screens/profile_screen.dart`
- `flutter_app/lib/services/auth_service.dart`

**Demo:** UI walkthrough → Register → Login → Profile photo upload

---

## 📋 Member 3: Backend Real-Time Messaging
**Keywords:** Socket.io, WebSocket, Message Delivery, Typing Indicator, Presence

**Main Files:**
- `backend/socket.js` (Lines 1-300)
- `backend/models/Message.js`
- `backend/server.js`

**Demo:** Message flow → Delivery tracking → Typing → Online status

---

## 📋 Member 4: Frontend Real-Time Chat UI
**Keywords:** Chat Screen, Users List, Socket Client, Message Bubbles

**Main Files:**
- `flutter_app/lib/screens/chat_screen_new.dart`
- `flutter_app/lib/screens/users_list_screen.dart`
- `flutter_app/lib/services/socket_service.dart`

**Demo:** Send message → Real-time receive → Typing indicator → Status

---

## 📋 Member 5: Backend Advanced Features
**Keywords:** Edit, Delete, Reactions, Media Upload, Multer, File Storage

**Main Files:**
- `backend/socket.js` (Lines 300-420)
- `backend/routes/auth.js` (File upload)
- `backend/uploads/` folder

**Demo:** Edit message → Delete (both modes) → Reactions → Upload file

---

## 📋 Member 6: Frontend Advanced Features UI
**Keywords:** Message Menu, Edit UI, Delete Dialogs, Emoji Picker, Media Upload

**Main Files:**
- `flutter_app/lib/screens/chat_screen_new.dart` (Advanced)
- `flutter_app/lib/services/socket_service.dart` (Edit/Delete/React)
- Message widgets

**Demo:** Long-press menu → Edit → Delete → Add reaction → Send image

---

## 📋 Member 7: Backend Group System
**Keywords:** Group Creation, Admin, Members, Group Messages, Read Receipts

**Main Files:**
- `backend/routes/groups.js`
- `backend/socket.js` (Lines 447-747)
- `backend/models/Group.js`
- `backend/models/GroupMessage.js`

**Demo:** Create group → Add members → Admin controls → Group messaging

---

## 📋 Member 8: Frontend Groups + Server Config
**Keywords:** Group Chat, Create Group, Group Info, Server Configuration, Home

**Main Files:**
- `flutter_app/lib/screens/group_chat_screen.dart`
- `flutter_app/lib/screens/create_group_screen.dart`
- `flutter_app/lib/screens/server_config_screen.dart` ⭐
- `flutter_app/lib/screens/home_screen.dart`

**Demo:** Home screen → Create group → Group chat → **Server config** ⭐

---

## 🎯 Presentation Order

```
1. Member 1 (Backend Auth)
   ↓
2. Member 2 (Frontend Auth)
   ↓
3. Member 3 (Backend Messaging)
   ↓
4. Member 4 (Frontend Chat)
   ↓
5. Member 5 (Backend Advanced)
   ↓
6. Member 6 (Frontend Advanced)
   ↓
7. Member 7 (Backend Groups)
   ↓
8. Member 8 (Frontend Groups + Config)
```

---

## 🔥 Unique Features by Member

| Member | Unique Feature to Highlight |
|--------|----------------------------|
| 1 | Account locking after 5 failed attempts |
| 2 | Profile photo upload with preview |
| 3 | Auto-delivery of pending messages on connection |
| 4 | Real-time typing indicator with debouncing |
| 5 | Delete for everyone vs delete for me |
| 6 | Emoji reaction picker with animations |
| 7 | Multi-user read receipts in groups |
| 8 | **Dynamic server URL configuration** ⭐ |

---

## ⏱️ Time Allocation (Total: 56 minutes)

- Each member: **7 minutes** (Introduction 1m + Explanation 3m + Demo 2m + Q&A 1m)
- Team intro: **2 minutes**
- System demo: **5 minutes**
- Final Q&A: **10 minutes**

---

## 📊 Code Ownership

### Backend (Node.js)
```
Member 1: auth.js (auth routes), auth middleware, User model
Member 3: socket.js (messaging), Message model, server setup
Member 5: socket.js (advanced), file upload, media handling
Member 7: groups.js, Group models, socket.js (groups)
```

### Frontend (Flutter)
```
Member 2: Auth screens, auth service, profile
Member 4: Chat screen, users list, socket service (chat)
Member 6: Advanced UI, message widgets, media pickers
Member 8: Group screens, home screen, server config ⭐
```

---

## 🎤 30-Second Elevator Pitch (Each Member)

### Member 1:
*"I built the secure authentication backend using JWT tokens and bcrypt password hashing. Our system locks accounts after 5 failed login attempts and supports password reset functionality."*

### Member 2:
*"I created the authentication UI in Flutter with beautiful, responsive screens for login, registration, and profile management. Users can upload profile photos and the app securely stores JWT tokens."*

### Member 3:
*"I implemented the real-time messaging backend with Socket.io. Messages are delivered instantly, we track delivery status, show typing indicators, and automatically deliver pending messages when users come online."*

### Member 4:
*"I built the chat interface in Flutter with real-time updates, message bubbles, typing indicators, and online status. The UI auto-scrolls and shows message status with checkmarks."*

### Member 5:
*"I added advanced messaging features on the backend: users can edit messages, delete for themselves or everyone, add emoji reactions, and upload media files with validation."*

### Member 6:
*"I created the UI for advanced features: long-press menus, edit dialogs, emoji pickers, and media upload. Users can reply to messages and see reaction animations."*

### Member 7:
*"I built the group chat system on the backend with admin controls, member management, and multi-user read receipts. Groups can be public or private with customizable permissions."*

### Member 8:
*"I created the group chat UI and a unique server configuration feature. Users can create groups, manage members, and most importantly, configure their own backend server URL without code changes."*

---

## 💡 Quick Tips

### During Demo:
- **Keep it simple** - Don't try to show everything
- **One feature at a time** - Let it sink in
- **Explain as you go** - "Notice how..."
- **Highlight connections** - "This calls the API that Member X created"

### During Q&A:
- **Be honest** - "That's a great question, let me explain..."
- **Ask for help** - If stuck, say "Let me ask my teammate who worked on that"
- **Stay calm** - Take a breath before answering
- **Refer to code** - "Let me show you in the code..."

### If Something Breaks:
- **Have screenshots ready**
- **Have a video backup**
- **Explain what should happen**
- **Show the code instead**

---

## 🏆 Success Criteria

✅ Each member speaks for 6-8 minutes
✅ All features demonstrated
✅ Questions answered confidently
✅ Team coordination visible
✅ Technical depth shown
✅ Working demo completed

---

## 📞 Support Each Other

If someone struggles with a question:
- Jump in to support
- Add context from your component
- Show team cohesion
- Never blame or criticize

Remember: **You're a team!** 🤝

---

## 🎓 Final Checklist

**Individual:**
- [ ] Know your files inside-out
- [ ] Practice demo 5+ times
- [ ] Prepare 2-3 slides
- [ ] Test features thoroughly
- [ ] Prepare for common questions

**Team:**
- [ ] Full system test together
- [ ] Practice transitions
- [ ] Assign timekeeper
- [ ] Backup demo ready
- [ ] Architecture diagram prepared

---

**Good luck! You've built something amazing! 🚀**
