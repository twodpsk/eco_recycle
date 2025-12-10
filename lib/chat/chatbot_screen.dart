import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  // 1. 변수 선언부
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();

  // ★ API 키 (본인 키 유지)
  final String _apiKey = 'AIzaSyDG0mjnHElZ0FZWcZNT1kvD0TB377N7ui0';

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  int _currentPoints = 0;
  bool _isTyping = false;
  bool _isSpeaking = false;

  late AnimationController _confettiController;
  late AnimationController _sproutController;
  bool _showConfetti = false;
  bool _showSprout = false;

  List<Map<String, dynamic>> _messages = [];

  List<String> _questionChips = [
    "💰 내 포인트 확인",
    "생수병 버리는 법",
    "깨진 유리 어떻게 버려?",
    "치킨 박스 분리수거",
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserPoints();
    _initGemini();
    _initTts();
    _initAnimations();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _controller.dispose();
    _scrollController.dispose();
    _confettiController.dispose();
    _sproutController.dispose();
    super.dispose();
  }

  // ==========================================
  // ★ [수정 완료] 레벨 시스템 (만렙 10000점 기준)
  // ==========================================
  Map<String, dynamic> _getLevelInfo() {
    if (_currentPoints < 101) {
      // Lv.1 씨앗 (0 ~ 100)
      return {
        "level": "Lv.1 씨앗 🌱",
        "file": "assets/lottie/seed.json",
        "next_point": 101,
        "msg": "아직은 작지만 큰 꿈을 품고 있어요!"
      };
    } else if (_currentPoints < 501) {
      // Lv.2 새싹 (101 ~ 500)
      return {
        "level": "Lv.2 새싹 🌿",
        "file": "assets/lottie/sprout.json",
        "next_point": 501,
        "msg": "무럭무럭 자라나고 있네요!"
      };
    } else if (_currentPoints < 8001) {
      // ★ [수정됨] Lv.3 묘목 (501 ~ 8001) - 구간 대폭 확대!
      return {
        "level": "Lv.3 묘목 🌳",
        "file": "assets/lottie/sapling.json",
        "next_point": 8000, // ★ 목표 점수도 8000으로 변경
        "msg": "이제 제법 나무 태가 나는데요?"
      };
    } else {
      // Lv.4 울창한 나무 (8001점 이상)
      return {
        "level": "Lv.4 울창한 나무 🌲",
        "file": "assets/lottie/tree.json",
        "next_point": 8001, // 만렙
        "msg": "환경부 장관님도 놀랄 훌륭한 숲지킴이!"
      };
    }
  }

  // 내 숲 보기 다이얼로그
  void _showMyForestDialog() {
    final info = _getLevelInfo();
    // 0으로 나누기 방지 및 게이지 계산
    final double target = info['next_point'] == 99999 ? 1.0 : info['next_point'].toDouble();
    final double current = _currentPoints.toDouble();
    final double progress = (current / target).clamp(0.0, 1.0);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("나의 환경 숲", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal[800])),
              const SizedBox(height: 10),

              SizedBox(
                height: 150,
                child: Lottie.asset(
                  info['file'],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.park, size: 80, color: Colors.green);
                  },
                ),
              ),

              Text(info['level'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(info['msg'], style: TextStyle(color: Colors.grey[600], fontSize: 14), textAlign: TextAlign.center),

              const SizedBox(height: 20),
              if (info['next_point'] != 99999) ...[
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  color: Colors.teal,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 5),
                Text(
                  "다음 단계까지 ${_currentPoints} / ${info['next_point']} P",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ] else
                const Text("🏆 최고 레벨 달성! 축하합니다!", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                child: const Text("닫기"),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 기존 기능 함수들 (저장, 초기화 등)
  // ==========================================

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(_messages);
    await prefs.setString('chat_history', jsonString);
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('chat_history');
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        List<dynamic> decoded = jsonDecode(jsonString);
        setState(() {
          _messages = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      } catch (e) { print("대화 로드 실패: $e"); }
    } else {
      setState(() {
        _messages = [{"role": "bot", "text": "안녕하세요! 🌱\n저는 환경부 베테랑 AI 상담사 '에코봇'입니다.", "isJson": false}];
      });
    }
  }

  Future<void> _clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
    setState(() {
      _messages = [{"role": "bot", "text": "대화 내용이 초기화되었습니다. ✨", "isJson": false}];
    });
  }

  void _initAnimations() {
    _confettiController = AnimationController(vsync: this);
    _sproutController = AnimationController(vsync: this);

    _confettiController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() { _showConfetti = false; _confettiController.reset(); });
      }
    });
    _sproutController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() { _showSprout = false; _sproutController.reset(); });
      }
    });
  }

  void _triggerAnimation(String type) {
    setState(() {
      if (type == 'confetti') {
        _showConfetti = true;
        _confettiController.forward(from: 0);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() { _showConfetti = false; _confettiController.reset(); });
        });
      } else if (type == 'sprout') {
        _showSprout = true;
        _sproutController.forward(from: 0);
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (mounted) setState(() { _showSprout = false; _sproutController.reset(); });
        });
      }
    });
  }

  void _initTts() async {
    await _flutterTts.setLanguage("ko-KR");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

// Gemini 설정
  void _initGemini() {
    final systemPrompt = '''
**Role & Persona:**
당신은 환경부에서 30년간 근무한 베테랑 분리배출 상담사 '에코봇'입니다.
사용자가 사진이나 글로 쓰레기 처리법을 물어보면, 정확한 분리배출 방법을 친절하고 전문적으로 안내해야 합니다.

**Response Rules:**
1. 모든 답변은 반드시 **JSON 포맷**으로 출력해야 합니다.
2. 마크다운(```json)이나 사족을 절대 붙이지 말고 **순수 JSON 문자열**만 반환하세요.
3. 답변은 한국어(Korean)로 작성하세요.

**JSON Structure:**
{
"category": "String (예: 일반쓰레기, 플라스틱, 비닐류, 캔류, 불가능 등)",
"short_answer": "String (카드 상단 핵심 요약)",
"detail_explanation": "String (구체적인 설명)",
"veteran_tip": "String (베테랑의 꿀팁)",
"suggestion_chips": ["질문1", "질문2", "질문3"]
}

**Content Guideline:**
- 분리배출과 관련 없는 질문이면 "category": "기타", "short_answer": "상담 불가"로 답하세요.
''';
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json', temperature: 0.7),
      systemInstruction: Content.system(systemPrompt),
    );
    _chatSession = _model.startChat();
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _flutterTts.speak(text);
      await _flutterTts.awaitSpeakCompletion(true);
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _fetchUserPoints() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() { _currentPoints = doc.data()?['point'] ?? 0; });
        }
      }
    } catch (e) { print("포인트 로드 실패: $e"); }
  }

  Future<void> _pickImageAndSend() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _messages.add({"role": "user", "text": "[사진을 전송했습니다] 📷", "isJson": false});
        _isTyping = true;
        _questionChips = [];
      });
      _saveChatHistory();
      _scrollToBottom();
      try {
        final content = Content.multi([TextPart("분리배출 방법 (JSON)"), DataPart('image/jpeg', bytes)]);
        final response = await _chatSession.sendMessage(content);
        _handleResponse(response.text);
      } catch (e) { _handleError(e); }
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({"role": "user", "text": text, "isJson": false});
      _isTyping = true;
      _questionChips = [];
      _controller.clear();
    });
    _saveChatHistory();
    _scrollToBottom();

    if (text.contains("포인트") || text.contains("점수")) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _messages.add({"role": "bot", "text": "현재 회원님의 환경 포인트는\n총 $_currentPoints P 입니다! 🌱", "isJson": false});
          _isTyping = false;
        });
        _saveChatHistory();
        _scrollToBottom();
        _triggerAnimation('confetti');
        _speak("와우! 대단해요. $_currentPoints 포인트나 모으셨네요!");
      }
      return;
    }
    try {
      final response = await _chatSession.sendMessage(Content.text(text));
      _handleResponse(response.text);
    } catch (e) { _handleError(e); }
  }

  void _handleError(dynamic e) {
    if (mounted) {
      setState(() { _isTyping = false; _messages.add({"role": "bot", "text": "오류: $e", "isJson": false}); });
      _saveChatHistory();
    }
  }

  void _handleResponse(String? responseText) {
    if (responseText == null) return;
    try {
      String cleanText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      if (!cleanText.contains('"category"') && cleanText.contains("'category'")) {
        cleanText = cleanText.replaceAll("'", '"');
      }
      final data = jsonDecode(cleanText);
      if (mounted) {
        setState(() {
          _messages.add({"role": "bot", "isJson": true, "data": data});
          if (data['suggestion_chips'] != null) _questionChips = List<String>.from(data['suggestion_chips']);
          _isTyping = false;
        });
        _saveChatHistory();
        if (data['category'] != null && !data['category'].toString().contains("기타")) _triggerAnimation('sprout');
      }
    } catch (e) {
      if (mounted) {
        setState(() { _messages.add({"role": "bot", "text": responseText, "isJson": false}); _isTyping = false; });
        _saveChatHistory();
      }
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("AI 상담사 에코봇", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal[600],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.park, color: Colors.white),
            tooltip: "나의 숲 레벨 보기",
            onPressed: _showMyForestDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: "대화 삭제",
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("대화 삭제"),
                  content: const Text("모든 기록을 지우시겠습니까?"),
                  actions: [
                    TextButton(child: const Text("취소"), onPressed: () => Navigator.of(ctx).pop()),
                    TextButton(child: const Text("삭제", style: TextStyle(color: Colors.red)), onPressed: () { _clearChatHistory(); Navigator.of(ctx).pop(); }),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) return _buildLoadingBubble();
                    final msg = _messages[index];
                    final isBot = msg['role'] == 'bot';
                    if (isBot && msg['isJson'] == true) return _buildRecycleInfoCard(msg['data']);
                    else return _buildSimpleMessageBubble(isBot, msg['text'] ?? "");
                  },
                ),
              ),
              if (!_isTyping && _questionChips.isNotEmpty)
                Container(
                  height: 50, margin: const EdgeInsets.only(bottom: 10),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _questionChips.length, separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return ActionChip(label: Text(_questionChips[index]), backgroundColor: Colors.white, onPressed: () => _sendMessage(_questionChips[index]));
                    },
                  ),
                ),
              _buildInputArea(),
            ],
          ),
          if (_showConfetti) Positioned.fill(child: IgnorePointer(child: Lottie.asset('assets/lottie/confetti.json', controller: _confettiController, fit: BoxFit.cover, repeat: false, onLoaded: (c) => _confettiController.duration = c.duration))),
          if (_showSprout) Center(child: IgnorePointer(child: Lottie.asset('assets/lottie/sprout.json', controller: _sproutController, width: 250, height: 250, repeat: false, onLoaded: (c) => _sproutController.duration = c.duration))),
        ],
      ),
    );
  }

  // (하단 UI 빌드 함수들 유지)
  Widget _buildInputArea() {
    return Container(padding: const EdgeInsets.fromLTRB(10, 5, 10, 20), color: Colors.white, child: Row(children: [IconButton(icon: const Icon(Icons.camera_alt_rounded, color: Colors.teal, size: 28), onPressed: _pickImageAndSend), Expanded(child: TextField(controller: _controller, decoration: InputDecoration(hintText: "궁금한 쓰레기를 물어보세요", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)), onSubmitted: _sendMessage)), const SizedBox(width: 8), CircleAvatar(backgroundColor: Colors.teal[600], child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: () => _sendMessage(_controller.text)))]));
  }
  Widget _buildSimpleMessageBubble(bool isBot, String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end, children: [if (isBot) ...[const CircleAvatar(backgroundColor: Colors.teal, radius: 16, child: Icon(Icons.smart_toy, size: 20, color: Colors.white)), const SizedBox(width: 8)], Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: isBot ? Colors.white : Colors.teal[600], borderRadius: BorderRadius.circular(18).copyWith(topLeft: isBot ? Radius.zero : const Radius.circular(18), bottomRight: isBot ? const Radius.circular(18) : Radius.zero), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))]), child: Text(text, style: TextStyle(color: isBot ? Colors.black87 : Colors.white, fontSize: 15))))]));
  }
  Widget _buildRecycleInfoCard(Map<String, dynamic> data) {
    final String category = data['category'] ?? "정보 없음";
    final String shortAnswer = data['short_answer'] ?? "";
    final String detail = data['detail_explanation'] ?? "";
    final String tip = data['veteran_tip'] ?? "";
    final speakText = "$category. $shortAnswer. $detail. $tip";
    bool isDanger = category.contains("불가") || category.contains("일반");
    final Color themeColor = isDanger ? Colors.redAccent : Colors.teal;
    return Padding(padding: const EdgeInsets.only(bottom: 20, left: 40, right: 10), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: themeColor.withOpacity(0.3)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Column(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: isDanger ? Colors.red.shade50 : Colors.teal.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))), child: Row(children: [Icon(isDanger ? Icons.warning_amber : Icons.recycling, color: themeColor), const SizedBox(width: 8), Text(category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor)), const Spacer(), IconButton(icon: Icon(Icons.volume_up, color: themeColor), onPressed: () => _speak(speakText))])), Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(shortAnswer, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8), Text(detail, style: const TextStyle(fontSize: 14, height: 1.4)), if (tip.isNotEmpty) ...[const SizedBox(height: 12), Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)), child: Row(children: [const Text("💡", style: TextStyle(fontSize: 16)), const SizedBox(width: 8), Expanded(child: Text(tip, style: const TextStyle(fontSize: 13)))])),]]))])));
  }
  Widget _buildLoadingBubble() {
    return Padding(padding: const EdgeInsets.only(left: 10, bottom: 10), child: Row(children: [const CircleAvatar(radius: 16, backgroundColor: Colors.teal, child: Icon(Icons.smart_toy, size: 20, color: Colors.white)), const SizedBox(width: 10), const Text("생각 중...", style: TextStyle(color: Colors.grey))]));
  }
}