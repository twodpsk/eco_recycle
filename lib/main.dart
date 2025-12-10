import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

// [수정] .dart 확장자 추가 및 HomeScreen으로 변경
import 'auth/auth_gate.dart';
import 'home/home_screen.dart';
import 'cert/cert_upload.dart';
import 'chat/chatbot_screen.dart';

void main() async { // 👈 [수정]: main 함수를 반드시 async로 선언해야 await 사용 가능
  // Flutter 엔진 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 1. [intl 초기화] 요일 한글 표시를 위한 로케일 데이터 초기화 (runApp 호출 전에 필수)
  try {
    await initializeDateFormatting('ko', null);
  } catch (e) {
    print("날짜 포맷팅 초기화 오류: $e");
  }


  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print("⚠️ Firebase가 이미 연결되어 있습니다. (이 에러는 무시해도 됩니다)");
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eco Recycle App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
          primary: Colors.teal,
          secondary: Colors.amber,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'Pretendard',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
      home: const AuthGate(),

      routes: {
        '/home': (context) => const HomeScreen(),
        '/certUpload': (context) => const CertUploadScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
      },
    );
  }
}