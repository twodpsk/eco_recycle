import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:image_picker/image_picker.dart';

import '../mypage/mypage_screen.dart';
import '../widgets/shorts_tips_widget.dart';
import '../chat/chatbot_screen.dart';
import '../community/community_screen.dart';
import '../camera/ai_camera_screen.dart';
import '../widgets/sprout_section.dart';
import '../widgets/tip_menu.dart';
import '../cert/cert_section.dart';
import 'quiz_section.dart';
import 'eco_participation.dart';
import '../shop/shop_screen.dart';
import 'offline_shop.dart';

// ------------------------------
// 닉네임 표시 위젯 (Drawer용)
// ------------------------------
class DrawerNicknameDisplay extends StatelessWidget {
  const DrawerNicknameDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String nickname = "환경지킴이";
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          nickname = data['nickname'] ?? "환경지킴이";
        }
        return Text('$nickname님',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold));
      },
    );
  }
}

// ------------------------------
// 포인트 표시 위젯
// ------------------------------
class RealtimePointDisplay extends StatelessWidget {
  const RealtimePointDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text("로그인 필요", style: TextStyle(color: Colors.white));
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("오류", style: TextStyle(color: Colors.white));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("💰 0 P",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final points = data['point'] ?? 0;
        return Text("💰 $points P",
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white));
      },
    );
  }
}

// ------------------------------
// HomeScreen
// ------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ------------------------------
      // Drawer
      // ------------------------------
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, // 프로필 영역 위로
                children: [
                  const DrawerNicknameDisplay(),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0, top: 4.0),
                    child: RealtimePointDisplay(),
                  ),
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(top: 0.5), // 프로필 약간 아래
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: _profileImage != null
                              ? FileImage(File(_profileImage!.path))
                              : const NetworkImage(
                              "https://i.pravatar.cc/150?img=11") as ImageProvider,
                        ),
                      ),
                      child: const Align(
                        alignment: Alignment.bottomRight,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.camera_alt,
                              size: 16, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Symbols.person_rounded),
              title: const Text('내 프로필'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyPageScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Symbols.store_rounded),
              title: const Text('상점'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopScreen(
                      currentPoints: 0,
                      onPointsChanged: (p) {},
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Symbols.storefront_rounded),
              title: const Text('오프라인 상점'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OfflineShopScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Symbols.group_rounded),
              title: const Text('우리 학교 커뮤니티'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CommunityScreen()),
                );
              },
            ),
          ],
        ),
      ),

      // ------------------------------
      // AppBar
      // ------------------------------
      appBar: AppBar(
        title: const Text('EcoRecycle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Symbols.storefront, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OfflineShopScreen()),
              );
            },
          ),
        ],
      ),

      // ------------------------------
      // Body
      // ------------------------------
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SproutSection(),
                  const SizedBox(height: 16),
                  const TipMenu(),
                  const SizedBox(height: 16),
                  const Text("분리배출 꿀팁 영상",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 400,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SizedBox(
                          width: 200,
                          child: ShortsTipsWidget(
                              videoId: 'jBmjwMbgcQ8',
                              title: '분리수거 간단한 팁'),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 200,
                          child: ShortsTipsWidget(
                              videoId: 'N2SmNNjqjkQ',
                              title: '깨진 유리병 안전하게 버리는 법'),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 200,
                          child: ShortsTipsWidget(
                              videoId: 'J75SzKhnADA',
                              title: '분리수거 꿀템'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const EcoParticipationSection(),
                  const SizedBox(height: 16),
                  const CertSection(),
                  const SizedBox(height: 16),
                  const QuizSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ------------------------------
          // 챗봇 버튼
          // ------------------------------
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: "chatbot",
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChatbotScreen()));
              },
            ),
          ),
        ],
      ),

      // ------------------------------
      // 중앙 카메라 버튼
      // ------------------------------
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: () async {
            try {
              final cameras = await availableCameras();
              if (context.mounted) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AiCameraScreen(cameras: cameras)));
              }
            } catch (e) {
              print("카메라 에러: $e");
            }
          },
          backgroundColor: Colors.green,
          shape: const CircleBorder(),
          elevation: 4.0,
          child: const Icon(Symbols.photo_camera_rounded,
              size: 32, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ------------------------------
      // 하단 네비게이션 바
      // ------------------------------
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Symbols.home_rounded, weight: 600),
                color: Colors.green,
                iconSize: 32,
                onPressed: () {
                  _scrollController.animateTo(0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut);
                },
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: const Icon(Symbols.person_rounded, weight: 600),
                color: Colors.grey,
                iconSize: 32,
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MyPageScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
