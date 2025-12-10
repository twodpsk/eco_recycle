import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final ImagePicker _picker = ImagePicker();

  XFile? _profileImage;

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = image;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("프로필 사진이 선택되었습니다.")),
          );
        }
      }
    } catch (e) {
      print("이미지 선택 오류: $e");
    }
  }

  // 🏆 랭킹 계산 함수
  String _getRankingText(int point) {
    if (point >= 10000) return "상위 1%";
    if (point >= 7000) return "상위 5%";
    if (point >= 5000) return "상위 10%";
    if (point >= 3000) return "상위 20%";
    if (point >= 1000) return "상위 40%";
    return "씨앗 랭킹";
  }

  // 🌱 등급 이름 계산 함수
  String _getGradeName(int point) {
    if (point >= 10000) return "숲의지기 등급";
    if (point >= 7000) return "열매왕 등급";
    if (point >= 5000) return "꽃송이 등급";
    if (point >= 3000) return "몽우리 등급";
    if (point >= 1000) return "파릇잎 등급";
    return "씨앗 등급";
  }

  // 🎨 등급 색상 계산 함수
  Color _getGradeColor(int point) {
    if (point >= 10000) return Colors.purple;
    if (point >= 7000) return Colors.blueAccent;
    if (point >= 5000) return Colors.cyan;
    if (point >= 3000) return Colors.amber;
    if (point >= 1000) return Colors.grey;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("마이페이지", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final int point = data?['point'] ?? 0;
          final String nickname = data?['nickname'] ?? "환경지킴이";

          // 📊 목표 점수 설정
          final int maxPoint = 10000;
          final double progress = (point / maxPoint).clamp(0.0, 1.0);
          final int percentage = (progress * 100).toInt();

          // 랭킹 및 등급 정보 가져오기
          final String ranking = _getRankingText(point);
          final String gradeName = _getGradeName(point);
          final Color gradeColor = _getGradeColor(point);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. 상단 프로필 카드
                _buildProfileCard(nickname, point, maxPoint, progress, percentage, gradeName, gradeColor),

                const SizedBox(height: 20),

                // 2. 포인트 & 랭킹 카드
                Row(
                  children: [
                    Expanded(child: _buildStatCard("보유 포인트", "$point P", Icons.monetization_on, Colors.amber)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard("나의 랭킹", ranking, Icons.emoji_events, Colors.purpleAccent)),
                  ],
                ),

                const SizedBox(height: 30),

                // 3. 활동 관리 메뉴
                _buildSectionHeader("활동 관리"),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(Icons.history, "분리배출 인증 내역", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RecyclingHistoryPage()));
                      }),
                      // 리스트 사이 구분선
                      Divider(height: 1, thickness: 1, color: Colors.grey[300]),

                      _buildMenuItem(Icons.shopping_bag_outlined, "포인트 사용 내역", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PointHistoryPage()));
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 4. 계정 설정 메뉴
                _buildSectionHeader("계정 설정"),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(Icons.logout, "로그아웃", () async {
                        // ★ 로그아웃 핵심 로직
                        await FirebaseAuth.instance.signOut();
                      }, isDestructive: true),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // [위젯] 프로필 카드
  Widget _buildProfileCard(String nickname, int currentPoint, int maxPoint, double progress, int percentage, String gradeName, Color gradeColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: gradeColor.withOpacity(0.5), width: 2),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: _profileImage != null
                        ? FileImage(File(_profileImage!.path)) as ImageProvider
                        : const NetworkImage("https://i.pravatar.cc/150?img=11"),
                  ),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco, size: 16, color: gradeColor),
              const SizedBox(width: 4),
              Text(gradeName, style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),

          Text(nickname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),

          const SizedBox(height: 24),

          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("최고 등급까지", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text("$percentage%", style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("$currentPoint / $maxPoint P", style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.black54),
      title: Text(
          title,
          style: TextStyle(
              color: isDestructive ? Colors.redAccent : Colors.black87,
              fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
              fontSize: 15
          )
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, color: Colors.grey, indent: 20, endIndent: 20);
  }
}

class RecyclingHistoryPage extends StatelessWidget {
  const RecyclingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("분리배출 인증 내역", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: uid == null
          ? const Center(child: Text("로그인이 필요합니다."))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('recycling_history')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("아직 인증 내역이 없어요! 🌱"));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final dateRaw = data['date'];
              DateTime date = DateTime.now();
              if (dateRaw is Timestamp) date = dateRaw.toDate();

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.greenAccent,
                  child: Icon(Icons.check, color: Colors.white),
                ),
                title: Text(data['itemName'] ?? "분리배출 인증"),
                subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
                trailing: Text("+${data['point'] ?? 0} P", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              );
            },
          );
        },
      ),
    );
  }
}

class PointHistoryPage extends StatelessWidget {
  const PointHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("포인트 사용 내역", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: uid == null
          ? const Center(child: Text("로그인이 필요합니다."))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('point_history')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("포인트 사용 내역이 없어요."));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final dateRaw = data['date'];
              DateTime date = DateTime.now();
              if (dateRaw is Timestamp) date = dateRaw.toDate();

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.shopping_bag, color: Colors.white),
                ),
                title: Text(data['description'] ?? "포인트 사용"),
                subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
                trailing: Text("-${data['amount'] ?? 0} P", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
              );
            },
          );
        },
      ),
    );
  }
}