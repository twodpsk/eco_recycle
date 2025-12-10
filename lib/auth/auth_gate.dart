import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../home/home_screen.dart'; // ★ 경로 확인: home 폴더 안에 home_screen.dart가 있어야 함

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const HomeScreen();
          // 만약 여기서 또 에러가 나면 'const' 글자만 지워주세요 (return HomeScreen();)
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}