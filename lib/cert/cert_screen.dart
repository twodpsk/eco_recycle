import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'cert_upload.dart'; // 글쓰기 화면

// 🚨 [경로 수정 필수] 실제 프로젝트의 services 폴더 경로로 변경하세요.
import 'package:Ecorecycle/services/firestore_service.dart';


// Firestore 문서 목록을 날짜별로 그룹화하는 함수 (CertScreen 클래스 외부에 정의)
Map<String, List<QueryDocumentSnapshot>> groupPostsByDate(List<QueryDocumentSnapshot> docs) {
  final Map<String, List<QueryDocumentSnapshot>> grouped = {};

  // 🚨 [수정] 언어 설정을 'ko' (한국어)로 지정하고, 요일 코드를 (E) 대신 (EEE)로 변경합니다.
  final DateFormat formatter = DateFormat('yyyy-MM-dd (EEE)', 'ko'); // 예: 2025-12-09 (화)

  for (var doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    if (data['timestamp'] is Timestamp) {
      final DateTime date = (data['timestamp'] as Timestamp).toDate();
      final String dateKey = formatter.format(date); // 날짜를 문자열 키로 변환

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(doc);
    }
  }
  return grouped;
}

// ---------------------------------------------------------
// [메인] 에코 인증 게시판 (날짜별 그룹화 화면)
// ---------------------------------------------------------
class CertScreen extends StatelessWidget {
  const CertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("에코 인증 게시판", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. 상단 헤더 (게시물 수 + 글쓰기 버튼)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.eco, color: Colors.green, size: 40),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("#에코 인증", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('certifications').snapshots(),
                      builder: (context, snapshot) {
                        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return Text("게시물 : $count개", style: TextStyle(color: Colors.grey[600]));
                      },
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CertUploadScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("인증하고 포인트 받기", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // 2. 사진 그리드 갤러리 (날짜별 그룹화된 ListView)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // 최신순으로 정렬하여 가져옴
              stream: FirebaseFirestore.instance.collection('certifications').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("아직 인증 게시물이 없어요. 첫 인증을 남겨보세요!", style: TextStyle(color: Colors.grey)));
                }

                // 1. 데이터 그룹화
                final groupedDocs = groupPostsByDate(snapshot.data!.docs);

                // 2. 날짜 키(Key)를 가져와서 최신 날짜 순으로 정렬
                final List<String> dateKeys = groupedDocs.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                // 3. ListView로 날짜 섹션별로 UI 구성
                return ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: dateKeys.length,
                  itemBuilder: (context, dateIndex) {
                    final dateKey = dateKeys[dateIndex];
                    final postsOnDate = groupedDocs[dateKey]!; // 해당 날짜의 게시물 목록

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 📅 날짜 헤더
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Text(
                            dateKey,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        // 🏞️ 해당 날짜의 게시물을 GridView로 표시
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(2),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                            childAspectRatio: 1,
                          ),
                          itemCount: postsOnDate.length,
                          itemBuilder: (context, postIndex) {
                            final doc = postsOnDate[postIndex];
                            final docId = doc.id;
                            final data = doc.data() as Map<String, dynamic>;
                            final imageUrl = data['imageUrl'];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CertDetailScreen(
                                      docId: docId,
                                      data: data,
                                    ),
                                  ),
                                );
                              },
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? Hero(
                                tag: imageUrl,
                                child: Image.network(imageUrl, fit: BoxFit.cover),
                              )
                                  : Container(color: Colors.grey[300], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                            );
                          },
                        ),
                        const Divider(height: 1, thickness: 1, color: Colors.grey),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------
// [추가된 화면] 인증 상세 페이지 (삭제 버튼 및 날짜 표시 포함)
// ---------------------------------------------------------
class CertDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const CertDetailScreen({super.key, required this.docId, required this.data});

  // 🗑️ 삭제 확인 다이얼로그 및 로직 함수
  void _confirmAndDeletePost(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final String postUid = data['uid'] ?? '';

    if (currentUserId == null || currentUserId != postUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제 권한이 없습니다.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ 게시글 삭제'),
          content: const Text('이 인증 게시글을 삭제하면 사진이 영구히 삭제됩니다. 정말로 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  // FirestoreService를 사용하여 삭제 로직 호출
                  await FirestoreService().deletePost(
                    docId,
                    data['imageUrl'],
                    data['uid'],
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('게시글이 성공적으로 삭제되었습니다.')),
                    );
                    Navigator.of(context).pop(); // 상세 화면 닫고 목록으로 돌아가기
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('삭제 실패: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // 📅 [핵심] 날짜 포맷팅
    String dateStr = "날짜 정보 없음";
    if (data['timestamp'] is Timestamp) {
      DateTime date = (data['timestamp'] as Timestamp).toDate();
      dateStr = DateFormat('yyyy년 MM월 dd일 HH:mm (EEE)', 'ko').format(date); // 예: 2025년 12월 09일 14:30 (화)
    }

    // 🗑️ 삭제 버튼 표시 권한 확인
    final postUid = data['uid'];
    final bool canDelete = currentUserId != null && currentUserId == postUid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("인증 상세", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // 삭제 버튼 (작성자에게만 표시)
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => _confirmAndDeletePost(context),
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 큰 이미지
            SizedBox(
              width: double.infinity,
              child: data['imageUrl'] != null
                  ? Hero(
                tag: data['imageUrl'],
                child: Image.network(
                  data['imageUrl'],
                  fit: BoxFit.contain,
                ),
              )
                  : Container(height: 300, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
            ),

            // 2. 내용 및 날짜
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 표시
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        dateStr, // 👈 포맷팅된 날짜 사용
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // 본문 내용
                  Text(
                    data['description'] ?? "내용이 없습니다.",
                    style: const TextStyle(fontSize: 18, height: 1.5, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}