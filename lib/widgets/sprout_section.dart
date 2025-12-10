import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../shop/shop_screen.dart';
import '../character/animated_mascot.dart';

class SproutSection extends StatelessWidget {
  const SproutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // 중앙 캐릭터
          const Align(
            alignment: Alignment.center,
            child: AnimatedMascot(
              imagePath: 'assets/sprout.png',
              width: 130,
              height: 130,
            ),
          ),

          // 환영 문구
          const Positioned(
            top: 0,
            left: 0,
            child: _WelcomeMessage(),
          ),

          // 현재 포인트 + 상점 이동
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get()
                    .then((doc) {
                  int point = doc['point'] ?? 0;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShopScreen(
                        currentPoints: point,
                        onPointsChanged: (updatedPoint) {
                          // 상점에서 포인트 업데이트 후 홈화면 갱신 가능
                        },
                      ),
                    ),
                  );
                });
              },
              child: const _PointDisplay(),
            ),
          ),
        ],
      ),
    );
  }
}

// 환영 메세지
class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage();
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text("환영합니다!", style: TextStyle(fontWeight: FontWeight.bold));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        String nickname = "환경지킴이";

        if (snapshot.hasData && snapshot.data!.exists) {
          nickname = snapshot.data!['nickname'] ?? "환경지킴이";
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("환영합니다", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text("님", style: TextStyle(fontSize: 18)),
              ],
            ),
          ],
        );
      },
    );
  }
}

// 포인트 표시
class _PointDisplay extends StatelessWidget {
  const _PointDisplay();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        int point = snapshot.data?['point'] ?? 0;

        return Row(
          children: [
            Text(
              "현재 포인트: $point P",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
            const SizedBox(width: 5),
            Icon(Icons.store, size: 20, color: Colors.green[700]),
          ],
        );
      },
    );
  }
}
