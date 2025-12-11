import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
// [추가] AI 기능을 위해 패키지 추가
import 'package:google_generative_ai/google_generative_ai.dart';

class CertUploadScreen extends StatefulWidget {
  const CertUploadScreen({super.key});

  @override
  State<CertUploadScreen> createState() => _CertUploadScreenState();
}

class _CertUploadScreenState extends State<CertUploadScreen> {
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  // [추가] AI 분석 중인지 확인하는 변수
  bool _isAnalyzing = false;

  // [추가] Gemini API 키 (챗봇과 동일한 키)
  final String _apiKey = 'AIzaSyAkTQaSkER5FfdL03liq-j0gEGa9PwVxv0';

  // [중요] 포인트가 증발하지 않도록 아까 정한 '고정 아이디'를 사용합니다.
  final String fixedUid = 'bJbHdxlvXEYDPTExiZsDz4q96g32 ';

  // ------------------------------------------------------------------------
  // 1. 이미지 선택 및 AI 자동 분석 함수
  // ------------------------------------------------------------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // 용량 최적화
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _textController.text = ""; // 기존 텍스트 초기화
      });

      // ★ 사진을 고르자마자 AI 분석 시작!
      await _analyzeImage(pickedFile);
    }
  }

  // ------------------------------------------------------------------------
  // 2. Gemini AI 이미지 분석 로직
  // ------------------------------------------------------------------------
  Future<void> _analyzeImage(XFile imageFile) async {
    setState(() => _isAnalyzing = true); // 로딩 시작

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );

      final imageBytes = await imageFile.readAsBytes();

      // 프롬프트: 해시태그를 뽑아달라고 요청
      final prompt = TextPart("이 쓰레기 사진을 분석해서 관련된 해시태그를 3개에서 5개 사이로 추천해줘. 예시: #플라스틱 #생수병 #환경보호. 설명 없이 해시태그만 출력해.");

      final content = [
        Content.multi([prompt, DataPart('image/jpeg', imageBytes)])
      ];

      final response = await model.generateContent(content);

      if (response.text != null && mounted) {
        setState(() {
          // AI가 써준 해시태그를 입력창에 자동으로 채워넣기
          _textController.text = response.text!;
        });
      }
    } catch (e) {
      print("AI 분석 실패: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI 분석에 실패했어요. 직접 입력해주세요!")));
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false); // 로딩 끝
      }
    }
  }

  // ------------------------------------------------------------------------
  // 3. 업로드 및 포인트 지급 (고정 아이디 적용)
  // ------------------------------------------------------------------------
  Future<void> _uploadCertification() async {
    if (_textController.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("사진과 내용을 모두 입력해주세요!")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      // (1) 스토리지 업로드
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef = FirebaseStorage.instance.ref().child('certifications/$fileName.jpg');
      await storageRef.putFile(_selectedImage!);
      final String imageUrl = await storageRef.getDownloadURL();

      // (2) DB 저장 (user!.uid 대신 fixedUid 사용!)
      await FirebaseFirestore.instance.collection('certifications').add({
        'uid': fixedUid, // ★ 고정 아이디로 저장해야 내역이 보임
        'description': _textController.text,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // (3) 포인트 지급 (user!.uid 대신 fixedUid 사용!)
      final userRef = FirebaseFirestore.instance.collection('users').doc(fixedUid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (snapshot.exists) {
          int currentPoint = snapshot.data()?['point'] ?? 0;
          transaction.update(userRef, {'point': currentPoint + 100});
        } else {
          // 만약 문서가 없으면 새로 생성 (안전장치)
          transaction.set(userRef, {'point': 100});
        }
      });

      // (4) 내역 저장
      await FirebaseFirestore.instance.collection('point_history').add({
        'uid': fixedUid, // ★ 고정 아이디
        'amount': 100,
        'description': '분리배출 인증 보상',
        'type': 'earn',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("인증 완료! 100P 지급! 🎉")));
        Navigator.pop(context);
      }
    } catch (e) {
      print("오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("업로드 실패")));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("인증 글쓰기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이미지 선택 영역
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_selectedImage!, fit: BoxFit.cover),
                      // 분석 중일 때 이미지 위에 로딩 표시
                      if (_isAnalyzing)
                        Container(
                          color: Colors.black45,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 10),
                                Text("AI가 사진을 분석 중...🤖", style: TextStyle(color: Colors.white))
                              ],
                            ),
                          ),
                        )
                    ],
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_rounded, size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text("터치해서 쓰레기 사진 등록", style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 텍스트 입력창 (AI가 자동 입력)
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "사진을 올리면 AI가 해시태그를 달아줘요! \n(직접 수정도 가능합니다)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
                // 분석 중일 때 입력창 오른쪽에도 로딩 표시
                suffixIcon: _isAnalyzing
                    ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // 업로드 버튼
            ElevatedButton(
              onPressed: (_isUploading || _isAnalyzing) ? null : _uploadCertification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
              ),
              child: _isUploading
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
                  : const Text("업로드하고 100P 받기", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}