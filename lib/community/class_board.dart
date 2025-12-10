import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ----------------------------------------------------------------------
// [화면 1] 게시글 목록 (우리 반 게시판)
// ----------------------------------------------------------------------
class ClassBoardScreen extends StatelessWidget {
  final int grade;
  final int classNumber;

  const ClassBoardScreen({
    super.key,
    required this.grade,
    required this.classNumber,
  });

  // 게시글 삭제 함수
  void _deletePost(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("삭제 확인"),
        content: const Text("정말 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('class_posts').doc(docId).delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제되었습니다.")));
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("$grade학년 $classNumber반 게시판", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.edit, color: Colors.white),
        onPressed: () {
          // 새 글 작성 모드로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassBoardWriteScreen(grade: grade, classNumber: classNumber),
            ),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        // [중요] 색인(Index)이 필요합니다! 에러 로그의 링크를 클릭하세요.
        stream: FirebaseFirestore.instance
            .collection('class_posts')
            .where('grade', isEqualTo: grade)
            .where('classNumber', isEqualTo: classNumber)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("오류 발생: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("아직 게시글이 없습니다."));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isMyPost = user != null && data['uid'] == user.uid;

              // 날짜 포맷팅
              String dateStr = "";
              if (data['timestamp'] != null) {
                DateTime date = (data['timestamp'] as Timestamp).toDate();
                dateStr = "${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                onTap: () {
                  // [추가됨] 게시글 상세(댓글) 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(docId: doc.id, data: data),
                    ),
                  );
                },
                title: Text(data['title'] ?? "제목 없음", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(data['content'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(data['nickname'] ?? "익명", style: TextStyle(fontSize: 12, color: Colors.green[800], fontWeight: FontWeight.bold)),
                        const SizedBox(width: 10),
                        Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
                // [추가됨] 내 글일 때만 수정/삭제 버튼 보이기
                trailing: isMyPost
                    ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      // 수정 모드로 이동 (기존 내용 전달)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassBoardWriteScreen(
                            grade: grade,
                            classNumber: classNumber,
                            docId: doc.id,
                            initialTitle: data['title'],
                            initialContent: data['content'],
                          ),
                        ),
                      );
                    } else if (value == 'delete') {
                      _deletePost(context, doc.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('수정')),
                    const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
                  ],
                )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------
// [화면 2] 글쓰기 및 수정 화면
// ----------------------------------------------------------------------
class ClassBoardWriteScreen extends StatefulWidget {
  final int grade;
  final int classNumber;
  final String? docId; // 수정일 경우 문서 ID
  final String? initialTitle; // 수정일 경우 기존 제목
  final String? initialContent; // 수정일 경우 기존 내용

  const ClassBoardWriteScreen({
    super.key,
    required this.grade,
    required this.classNumber,
    this.docId,
    this.initialTitle,
    this.initialContent,
  });

  @override
  State<ClassBoardWriteScreen> createState() => _ClassBoardWriteScreenState();
}

class _ClassBoardWriteScreenState extends State<ClassBoardWriteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // 기존 내용이 있으면 채워넣기 (수정 모드)
    _titleController = TextEditingController(text: widget.initialTitle ?? "");
    _contentController = TextEditingController(text: widget.initialContent ?? "");
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _savePost() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("제목과 내용을 모두 입력해주세요.")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 수정 모드인지 확인
      if (widget.docId != null) {
        // [수정] 기존 문서 업데이트
        await FirebaseFirestore.instance.collection('class_posts').doc(widget.docId).update({
          'title': _titleController.text,
          'content': _contentController.text,
          'isEdited': true, // 수정됨 표시 (선택)
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정되었습니다.")));
          Navigator.pop(context);
        }
      } else {
        // [새 글 작성]
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final nickname = userDoc.data()?['nickname'] ?? "익명";

        await FirebaseFirestore.instance.collection('class_posts').add({
          'grade': widget.grade,
          'classNumber': widget.classNumber,
          'uid': user.uid,
          'nickname': nickname,
          'title': _titleController.text,
          'content': _contentController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'commentCount': 0, // 댓글 수 초기화
        });
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print("저장 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장 실패")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId != null ? "글 수정" : "글쓰기", style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _savePost,
            child: const Text("완료", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "제목을 입력하세요",
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "내용을 입력하세요.",
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_isUploading) const LinearProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// [화면 3] 게시글 상세 & 댓글 화면 (추가됨!)
// ----------------------------------------------------------------------
class PostDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const PostDetailScreen({super.key, required this.docId, required this.data});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  // 댓글 등록 함수
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || user == null) return;

    final commentText = _commentController.text;
    _commentController.clear(); // 입력창 비우기
    FocusScope.of(context).unfocus(); // 키보드 내리기

    try {
      // 내 닉네임 가져오기
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final nickname = userDoc.data()?['nickname'] ?? "익명";

      // 'comments' 하위 컬렉션에 추가
      await FirebaseFirestore.instance
          .collection('class_posts')
          .doc(widget.docId)
          .collection('comments')
          .add({
        'uid': user!.uid,
        'nickname': nickname,
        'content': commentText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("댓글이 등록되었습니다.")));
    } catch (e) {
      print("댓글 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("댓글 등록 실패")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 날짜 포맷팅
    String dateStr = "";
    if (widget.data['timestamp'] != null) {
      DateTime date = (widget.data['timestamp'] as Timestamp).toDate();
      dateStr = "${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("게시글", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. 게시글 본문 영역
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data['title'] ?? "제목 없음", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const CircleAvatar(radius: 16, backgroundColor: Colors.green, child: Icon(Icons.person, size: 20, color: Colors.white)),
                      const SizedBox(width: 8),
                      Text(widget.data['nickname'] ?? "익명", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Text(dateStr, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  Text(widget.data['content'] ?? "", style: const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 40),

                  // 댓글 섹션 타이틀
                  const Text("댓글", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),

                  // 댓글 리스트 (StreamBuilder)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('class_posts')
                        .doc(widget.docId)
                        .collection('comments')
                        .orderBy('timestamp', descending: false) // 오래된 댓글이 위로
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final comments = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true, // 스크롤뷰 안이라 필수
                        physics: const NeverScrollableScrollPhysics(), // 이중 스크롤 방지
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final cData = comments[index].data() as Map<String, dynamic>;
                          final bool isMyComment = user != null && cData['uid'] == user!.uid;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(cData['nickname'] ?? "익명", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    if(isMyComment)
                                      GestureDetector(
                                        onTap: () {
                                          // 댓글 삭제 기능
                                          comments[index].reference.delete();
                                        },
                                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(cData['content'] ?? ""),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 2. 하단 댓글 입력창
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "댓글을 입력하세요...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}