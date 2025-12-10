import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  // [시연용 가짜 데이터] 발표할 때 꽉 차 보이게 하려고 만듦
  static final List<Map<String, dynamic>> _fakeUsers = [
    {'nickname': '환경왕김철수', 'grade': 2, 'classNumber': 3, 'point': 2500},
    {'nickname': '지구지킴이', 'grade': 2, 'classNumber': 1, 'point': 1850},
    {'nickname': '분리수거고수', 'grade': 2, 'classNumber': 5, 'point': 1620},
    {'nickname': '에코프렌즈', 'grade': 2, 'classNumber': 2, 'point': 950},
    {'nickname': '초록이', 'grade': 2, 'classNumber': 4, 'point': 880},
    {'nickname': '플라스틱NO', 'grade': 2, 'classNumber': 1, 'point': 700},
    {'nickname': '텀블러사용', 'grade': 2, 'classNumber': 3, 'point': 450},
    {'nickname': '깨끗한학교', 'grade': 2, 'classNumber': 2, 'point': 320},
    {'nickname': '새싹이', 'grade': 2, 'classNumber': 5, 'point': 150},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("2학년 전체 랭킹", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 실제 DB 데이터 가져오기 (2학년만)
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('grade', isEqualTo: 2)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 1. 실제 데이터 리스트로 변환
          List<Map<String, dynamic>> allUsers = [];

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              allUsers.add(doc.data() as Map<String, dynamic>);
            }
          }

          // 2. 가짜 데이터 합치기
          allUsers.addAll(_fakeUsers);

          // 3. 점수 높은 순으로 정렬 (내림차순)
          allUsers.sort((a, b) {
            int pointA = a['point'] ?? 0;
            int pointB = b['point'] ?? 0;
            return pointB.compareTo(pointA); // 큰 게 위로
          });

          if (allUsers.isEmpty) {
            return const Center(child: Text("데이터가 없습니다."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: allUsers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = allUsers[index];
              final rank = index + 1;

              // 1~3등은 하이라이트 배경색 & 아이콘
              Color? bgColor;
              Icon? rankIcon;

              if (rank == 1) {
                bgColor = Colors.amber[50];
                rankIcon = const Icon(Icons.emoji_events, color: Colors.amber);
              } else if (rank == 2) {
                bgColor = Colors.grey[100];
                rankIcon = const Icon(Icons.emoji_events, color: Colors.grey);
              } else if (rank == 3) {
                bgColor = Colors.brown[50];
                rankIcon = const Icon(Icons.emoji_events, color: Colors.brown);
              }

              return Container(
                color: bgColor ?? Colors.transparent, // 1~3등 아니면 투명
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: rank <= 3 ? Colors.transparent : Colors.green[100],
                    child: rank <= 3
                        ? Text("$rank", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18))
                        : Text("$rank", style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                  ),
                  title: Row(
                    children: [
                      Text(
                        data['nickname'] ?? '익명',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (rankIcon != null) ...[
                        const SizedBox(width: 5),
                        rankIcon, // 왕관 아이콘 표시
                      ]
                    ],
                  ),
                  subtitle: Text("${data['grade']}학년 ${data['classNumber']}반"),
                  trailing: Text(
                    "${data['point']} P",
                    style: TextStyle(
                        color: rank <= 3 ? Colors.redAccent : Colors.green[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}