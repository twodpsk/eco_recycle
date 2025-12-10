import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isChecked = false; // 아이디 저장 체크박스 상태

  @override
  void initState() {
    super.initState();
    _loadSavedEmail(); // 앱 시작 시 저장된 아이디 불러오기
  }

  // 저장된 이메일 불러오기 함수
  void _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();

    // ⚠️ 화면이 이미 dispose된 상태라면 setState 금지
    if (!mounted) return;

    setState(() {
      _isChecked = prefs.getBool('isIdSaved') ?? false;
      if (_isChecked) {
        _emailController.text = prefs.getString('savedEmail') ?? '';
      }
    });
  }

  // 로그인 로직
  void _login() async {
    try {
      // 1. Firebase 로그인 시도
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. 아이디 저장 로직 (로그인 성공 시 수행)
      final prefs = await SharedPreferences.getInstance();
      if (_isChecked) {
        prefs.setBool('isIdSaved', true);
        prefs.setString('savedEmail', _emailController.text.trim());
      } else {
        prefs.remove('isIdSaved');
        prefs.remove('savedEmail');
      }

      // 3. 성공하면 AuthGate에 의해 자동으로 메인으로 이동함

    } on FirebaseAuthException catch (e) {
      // 4. 로그인 실패 시 에러 메시지
      String message = '';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = '아이디 및 비밀번호를 확인 해주세요';
      } else {
        message = '로그인 오류가 발생했습니다.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // 배경색
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 100),
              const Icon(Icons.recycling, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              const Text('에코봇 로그인',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 40),

              // 이메일 입력
              TextField(
                controller: _emailController,
                decoration:
                const InputDecoration(labelText: '이메일', prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 10),

              // 비밀번호 입력
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration:
                const InputDecoration(labelText: '비밀번호', prefixIcon: Icon(Icons.lock)),
              ),

              Row(
                children: [
                  Checkbox(
                    value: _isChecked,
                    onChanged: (value) {
                      setState(() {
                        _isChecked = value!;
                      });
                    },
                  ),
                  const Text('아이디 저장'),
                ],
              ),
              const SizedBox(height: 20),

              // 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: _login,
                  child: const Text('로그인',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),

              // 회원가입 버튼
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                child: const Text('계정이 없으신가요? 회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
