import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/users_list_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Chat App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: Colors.green,
              selectionColor: Colors.green.withOpacity(0.3),
              selectionHandleColor: Colors.green,
            ),
            bottomAppBarTheme: BottomAppBarThemeData(
              color: Colors.white,
              surfaceTintColor: Colors.white,
            ),
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: const SplashScreen(),
          getPages: [
            GetPage(name: '/splash', page: () => const SplashScreen()),
            GetPage(name: '/login', page: () => LoginScreen()),
            GetPage(name: '/register', page: () => RegisterScreen()),
            GetPage(
              name: '/forgot-password',
              page: () => ForgotPasswordScreen(),
            ),
            GetPage(name: '/users', page: () => UsersListScreen()),
            GetPage(name: '/chat', page: () => ChatScreen()),
            GetPage(name: '/profile', page: () => ProfileScreen()),
          ],
        );
      },
    );
  }
}
