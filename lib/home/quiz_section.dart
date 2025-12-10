import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../character/animated_mascot.dart';
import 'quiz_text.dart'; // quizData 가져오기

class QuizSection extends StatelessWidget {
  const QuizSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuizPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.quiz, color: Colors.orange, size: 40),
            const SizedBox(width: 15),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "환경 퀴즈 시작",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "재미있게 환경 지식 테스트",
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentStep = 0;
  int currentQuestionIndex = 0;
  Map<int, int> correctAnswersCount = {};

  Future<void> _givePoints(int points) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) return;
      final currentPoints = snapshot.get('point') ?? 0;
      transaction.update(userDoc, {'point': currentPoints + points});
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("💰 10 포인트 지급!"),
        content: const Text("퀴즈 정답으로 10 포인트가 적립되었습니다!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  void answerQuestion(int selectedIndex) async {
    final currentQuestion = quizData[currentStep][currentQuestionIndex];
    bool isCorrect = selectedIndex == currentQuestion['answer'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          isCorrect ? '정답입니다! 🎉' : '틀렸습니다! 😢',
          style: TextStyle(color: isCorrect ? Colors.green : Colors.red),
        ),
        content: Text(
          currentQuestion['explanation'],
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (isCorrect) {
                correctAnswersCount[currentStep] =
                    (correctAnswersCount[currentStep] ?? 0) + 1;
                await _givePoints(10); // 정답 맞으면 10포인트 지급
              }

              setState(() {
                if (currentQuestionIndex < quizData[currentStep].length - 1) {
                  currentQuestionIndex++;
                } else {
                  currentQuestionIndex = 0;
                }
              });
            },
            child: const Text('다음 문제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = quizData[currentStep][currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("환경 퀴즈", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 단계 선택 버튼
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: quizData.length,
              itemBuilder: (context, step) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentStep == step ? Colors.green : Colors.grey.shade200,
                      foregroundColor: currentStep == step ? Colors.white : Colors.black87,
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() {
                        currentStep = step;
                        currentQuestionIndex = 0;
                      });
                    },
                    child: Text('단계 ${step + 1}'),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 2), // 상단 여백 최소화

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedMascot(
                    imagePath: 'assets/quiz.png',
                    width: 280,
                    height: 280,
                    topPadding: 10,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '단계 ${currentStep + 1}  •  맞춘 문제: ${correctAnswersCount[currentStep] ?? 0} / ${quizData[currentStep].length}',
                    style: const TextStyle(
                        fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      currentQuestion['question'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: List.generate(currentQuestion['options'].length, (index) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => answerQuestion(index),
                          child: Text(
                            currentQuestion['options'][index],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
