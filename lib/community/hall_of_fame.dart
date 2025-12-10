import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // [필수] 내 정보 확인용
import 'package:material_symbols_icons/symbols.dart';
import 'ranking_screen.dart';

class HallOfFameSection extends StatelessWidget {
  const HallOfFameSection({super.key});

  // [시연용 가짜 데이터]
  static final List<Map<String, dynamic>> _fakeUsers = [
    {'nickname': '환경왕김철수', 'grade': 2, 'classNumber': 3, 'point': 2500, 'uid': 'fake1'},
    {'nickname': '지구지킴이', 'grade': 2, 'classNumber': 1, 'point': 1850, 'uid': 'fake2'},
    {'nickname': '분리수거고수', 'grade': 2, 'classNumber': 5, 'point': 1620, 'uid': 'fake3'},
    {'nickname': '에코프렌즈', 'grade': 2, 'classNumber': 2, 'point': 950, 'uid': 'fake4'},
    {'nickname': '초록이', 'grade': 2, 'classNumber': 4, 'point': 880, 'uid': 'fake5'},
  ];

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid; // 내 아이디 가져오기

    return Column(
      children: [
        // 1. 헤더
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Symbols.emoji_events_rounded, color: Colors.amber, size: 28, fill: 1.0),
                  SizedBox(width: 8),
                  Text("2학년 명예의 전당", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingScreen()));
                },
                child: const Text("전체 순위 보기 >", style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),

        // 2. 랭킹 로직 및 UI
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('grade', isEqualTo: 2)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildEmptyBox();
            }

            // 1) 데이터 합치기
            List<Map<String, dynamic>> allUsers = [];
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                data['uid'] = doc.id; // 내 진짜 UID를 데이터에 포함
                allUsers.add(data);
              }
            }
            allUsers.addAll(_fakeUsers); // 가짜 데이터 추가

            // 2) 점수 순 정렬
            allUsers.sort((a, b) {
              int pointA = a['point'] ?? 0;
              int pointB = b['point'] ?? 0;
              return pointB.compareTo(pointA);
            });

            // 3) 상위 3명 추출
            final top3 = allUsers.take(3).toList();

            // 4) [핵심] 내 순위 찾기
            int myRank = -1;
            Map<String, dynamic>? myData;

            if (myUid != null) {
              for (int i = 0; i < allUsers.length; i++) {
                if (allUsers[i]['uid'] == myUid) {
                  myRank = i + 1; // 0번 인덱스가 1등
                  myData = allUsers[i];
                  break;
                }
              }
            }

            if (top3.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("랭킹 데이터 없음"));

            return Column(
              children: [
                // TOP 3 카드
                Container(
                  height: 220,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (top3.length > 1) _buildRankItem(top3[1], 2), // 2등
                      if (top3.isNotEmpty) _buildRankItem(top3[0], 1), // 1등
                      if (top3.length > 2) _buildRankItem(top3[2], 3), // 3등
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // [추가됨] 나의 순위 보여주는 카드
                if (myData != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50, // 연한 초록 배경
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green), // 초록 테두리
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text("내 순위 : ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text("$myRank위", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                          ],
                        ),
                        Text("${myData['nickname']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("${myData['point']} P", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyBox() {
    return Container(
      height: 210,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildRankItem(Map<String, dynamic> data, int rank) {
    final nickname = data['nickname'] ?? '익명';
    final points = data['point'] ?? 0;

    final bool isFirst = rank == 1;
    final double size = isFirst ? 80 : 60;
    final Color color = rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey : Colors.brown);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isFirst) const SizedBox(height: 10),
        if (isFirst) const Icon(Symbols.emoji_events_rounded, color: Colors.amber, size: 28, fill: 1.0),

        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: size / 2,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(Symbols.person_rounded, size: size / 2, color: color, weight: 600),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text("$rank", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            nickname,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: isFirst ? 16 : 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text("$points P", style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}