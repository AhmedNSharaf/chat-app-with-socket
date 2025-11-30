# Real-Time Chat Application

A full-stack real-time chat application built for a Distributed Systems university project. The application allows users to register, login, and chat with each other in real-time using WebSockets.

## 🏗️ Architecture

### Backend
- **Framework**: Node.js with Express.js
- **Real-time Communication**: Socket.io
- **Authentication**: JWT (JSON Web Tokens)
- **Data Storage**: In-memory storage (easily replaceable with MongoDB)
- **Security**: Password hashing with bcryptjs

### Frontend
- **Framework**: Flutter
- **State Management**: GetX
- **UI Responsiveness**: ScreenUtil
- **Real-time Communication**: Socket.io client

## 📁 Project Structure

```
chat-app/
├── backend/
│   ├── models/
│   │   └── User.js
│   ├── middleware/
│   │   └── auth.js
│   ├── routes/
│   │   └── auth.js
│   ├── socket.js
│   ├── server.js
│   ├── package.json
│   └── .env.example
├── flutter_app/
│   ├── lib/
│   │   ├── controllers/
│   │   │   ├── auth_controller.dart
│   │   │   ├── chat_controller.dart
│   │   │   └── users_controller.dart
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   └── message_model.dart
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── users_list_screen.dart
│   │   │   └── chat_screen.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   └── socket_service.dart
│   │   └── main.dart
│   └── pubspec.yaml
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- Node.js (v14 or higher)
- Flutter SDK
- Dart SDK

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create environment file:
   ```bash
   cp .env.example .env
   ```
   Edit `.env` with your configuration:
   ```
   PORT=3000
   JWT_SECRET=your_jwt_secret_key_here
   ```

4. Start the backend server:
   ```bash
   npm start
   ```
   or for development:
   ```bash
   npm run dev
   ```

The backend will be running on `http://localhost:3000`

### Frontend Setup

1. Navigate to the Flutter app directory:
   ```bash
   cd flutter_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the Flutter app:
   ```bash
   flutter run
   ```

## 🔧 API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/users` - Get all users (authenticated)
- `GET /api/auth/messages/:receiverId` - Get messages between users (authenticated)

### Socket Events
- `message` - Send a message
- `receive_message` - Receive a message

## 📱 Features

### Backend Features
- User registration and login with JWT authentication
- Real-time messaging with Socket.io
- In-memory data storage (users and messages)
- CORS enabled for cross-origin requests
- Password hashing for security

### Frontend Features
- Responsive UI with ScreenUtil
- Real-time chat interface
- User authentication flow
- Users list for chat selection
- Message bubbles with timestamps
- Auto-scroll to latest messages

## 🔒 Security

- JWT token-based authentication
- Password hashing with bcryptjs
- CORS configuration for secure cross-origin requests
- Input validation and error handling

## 🧪 Testing the Application

1. Start the backend server
2. Run the Flutter app on an emulator or device
3. Register two users (User A and User B)
4. Login with User A on one device/emulator
5. Login with User B on another device/emulator
6. Start chatting between the users

## 📚 Technologies Used

### Backend
- **Express.js**: Web framework for Node.js
- **Socket.io**: Real-time bidirectional communication
- **jsonwebtoken**: JWT implementation
- **bcryptjs**: Password hashing
- **cors**: Cross-origin resource sharing
- **dotenv**: Environment variable management

### Frontend
- **Flutter**: UI toolkit for building natively compiled applications
- **GetX**: State management, routing, and dependency injection
- **ScreenUtil**: Responsive UI scaling
- **socket_io_client**: Socket.io client for Flutter
- **http**: HTTP client for API calls
- **shared_preferences**: Local storage for tokens

## 🤝 Contributing

This is a university project. For improvements or bug fixes, please create an issue or submit a pull request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Authors

- [Your Name] - University Project

## 🙏 Acknowledgments

- Built for Distributed Systems course
- Inspired by modern chat applications
- Uses best practices for real-time applications
