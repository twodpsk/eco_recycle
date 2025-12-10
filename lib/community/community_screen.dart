import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hall_of_fame.dart'; // 명예의 전당 위젯 import
import 'class_board.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  // [핵심] 입장 권한 체크 함수
  Future<void> _checkAccessAndEnter(BuildContext context, int targetGrade, int targetClass) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. 내 정보 가져오기
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return;

    final data = userDoc.data() as Map<String, dynamic>;
    final myGrade = data['grade'] ?? 0;       // 내 학년
    final myClass = data['classNumber'] ?? 0; // 내 반

    // 2. 비교하기 (2학년 2반만 들어갈 수 있게 하려면)
    if (myGrade == targetGrade && myClass == targetClass) {
      // 입장 성공! (여기에 실제 게시판 화면으로 이동하는 코드 넣기)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$targetGrade학년 $targetClass반 커뮤니티에 입장했습니다! 👋")),
      );
      if (myGrade == targetGrade && myClass == targetClass) {
        // 입장 성공! 게시판 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassBoardScreen(
                grade: targetGrade,
                classNumber: targetClass
            ),
          ),
        );
      }
      else {
      }
    } else {
      // 입장 거부 알림
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("입장 불가 🚫"),
          content: Text("본인의 학급($myGrade학년 $myClass반)만 입장할 수 있습니다.\n여기는 $targetGrade학년 $targetClass반입니다."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("확인"))
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("우리 학교 커뮤니티", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. 명예의 전당 (TOP 3) - 아까 만든 위젯
            const HallOfFameSection(),
            const SizedBox(height: 20),
            const Divider(thickness: 5, color: Color(0xFFF5F5F5)),
            const SizedBox(height: 10),

            // 2. 학급 리스트 (예시: 2학년의 반들)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🏫 우리 반 게시판 찾기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // 예시: 2학년 1반 ~ 4반 버튼
                  _buildClassTile(context, 2, 1),
                  _buildClassTile(context, 2, 2), // 내가 2-2라면 여기만 들어가지겠죠?
                  _buildClassTile(context, 2, 3),
                  _buildClassTile(context, 2, 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 반 버튼 디자인
  Widget _buildClassTile(BuildContext context, int grade, int classNum) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Text("$classNum", style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
        ),
        title: Text("$grade학년 $classNum반"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // 버튼 누르면 권한 체크 함수 실행
          _checkAccessAndEnter(context, grade, classNum);
        },
      ),
    );
  }
}