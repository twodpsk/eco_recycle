import 'dart:convert'; // [추가] JSON 변환용
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // [추가] Gemini 패키지


class CertUploadScreen extends StatefulWidget {
  const CertUploadScreen({super.key});

  @override
  State<CertUploadScreen> createState() => _CertUploadScreenState();
}

class _CertUploadScreenState extends State<CertUploadScreen> {
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;
  final User? user = FirebaseAuth.instance.currentUser;

  // ==========================================
  // ★ [추가 1] Gemini 관련 변수 및 초기화
  // ==========================================
  final String _apiKey = 'AIzaSyDG0mjnHElZ0FZWcZNT1kvD0TB377N7ui0'; // API 키
  late final GenerativeModel _model;

  List<String> _suggestedTags = []; // 추천 태그 저장
  bool _isAnalyzing = false; // 분석 로딩 상태

  @override
  void initState() {
    super.initState();
    // 모델 초기화
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  // ==========================================
  // ★ [추가 2] 이미지 분석 함수
  // ==========================================
  Future<void> _analyzeImageForTags(XFile imageFile) async {
    setState(() {
      _isAnalyzing = true;
      _suggestedTags = []; // 기존 태그 초기화
    });

    try {
      final bytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart('이 사진을 보고 환경 실천 인증에 어울리는 짧은 한글 태그 3~5개를 추천해줘. JSON 형식 {"tags": ["텀블러", "카페", ...]} 으로만 답해.'),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await _model.generateContent(content);

      if (response.text != null) {
        // JSON 파싱
        final data = jsonDecode(response.text!);
        if (mounted) {
          setState(() {
            _suggestedTags = List<String>.from(data['tags']);
          });
        }
      }
    } catch (e) {
      print("태그 생성 실패: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  // 이미지 선택 함수 (수정됨)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      // ★ 사진 선택 후 바로 분석 시작
      _analyzeImageForTags(pickedFile);
    }
  }

  // 업로드 로직 (기존과 동일)
  Future<void> _uploadCertification() async {
    if (_textController.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("사진과 내용을 모두 입력해주세요!")));
      return;
    }
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      // 1. 스토리지 업로드
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef = FirebaseStorage.instance.ref().child('certifications/$fileName.jpg');
      await storageRef.putFile(_selectedImage!);
      final String imageUrl = await storageRef.getDownloadURL();

      // 2. DB 저장
      await FirebaseFirestore.instance.collection('certifications').add({
        'uid': user!.uid,
        'description': _textController.text,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 3. 포인트 지급
      final userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (snapshot.exists) {
          int currentPoint = snapshot.data()?['point'] ?? 0;
          transaction.update(userRef, {'point': currentPoint + 100});
        }
      });

      // 4. 내역 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('recycling_history') // 마이페이지가 찾는 경로
          .add({
        'itemName': '분리배출 인증',
        'point': 100,
        'description': '분리배출 인증 보상',
        'type': 'earn',
        'date': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("인증 완료! 100P 지급! 🎉")));
        Navigator.pop(context);
      }
    } catch (e) {
      print("오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("업로드 실패")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("인증 글쓰기", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이미지 표시 영역
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                )
                    : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
              ),
            ),

            // ==========================================
            // ★ [추가 3] 태그 추천 UI
            // ==========================================
            const SizedBox(height: 10),
            if (_isAnalyzing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)),
                    SizedBox(width: 10),
                    Text("AI가 태그를 분석 중입니다...", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),

            if (!_isAnalyzing && _suggestedTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("💡 추천 태그 (클릭해서 추가)", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _suggestedTags.map((tag) {
                        return ActionChip(
                          label: Text("#$tag"),
                          backgroundColor: Colors.green.shade50,
                          labelStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onPressed: () {
                            // 태그 클릭 시 텍스트 필드에 추가
                            setState(() {
                              String currentText = _textController.text;
                              if (currentText.isNotEmpty && !currentText.endsWith(' ')) {
                                currentText += ' ';
                              }
                              _textController.text = '$currentText#$tag ';
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            // 텍스트 입력 영역
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "인증 내용을 입력하세요...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 업로드 버튼
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadCertification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("업로드하고 포인트 받기", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}