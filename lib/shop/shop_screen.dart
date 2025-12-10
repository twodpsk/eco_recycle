import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShopScreen extends StatefulWidget {
  final int currentPoints;
  final ValueChanged<int> onPointsChanged;

  const ShopScreen({
    super.key,
    required this.currentPoints,
    required this.onPointsChanged,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late int points;
  String topImage = 'assets/sprout.png';

  // 0: 착용해보기, 1: 구매하기, 2: 착용중
  late List<int> dressState;

  // 스프레이 아이템 목록 (+ 성장량 추가)
  final List<Map<String, dynamic>> sprays = [
    {'image': 'assets/spray1.png', 'price': 100, 'grow': '성장량 +5%'},
    {'image': 'assets/spray2.png', 'price': 200, 'grow': '성장량 +7%'},
    {'image': 'assets/spray3.png', 'price': 300, 'grow': '성장량 +9%'},
  ];

  // 드레스 아이템 목록
  final List<Map<String, dynamic>> dresses = [
    {'image': 'assets/dress1.png', 'price': 300, 'name': '스트로베리 드레스'},
    {'image': 'assets/dress2.png', 'price': 300, 'name': '허니벌 드레스'},
    {'image': 'assets/dress3.png', 'price': 400, 'name': '외계뿅뿅'},
    {'image': 'assets/dress4.png', 'price': 150, 'name': '퐁실니트'},
  ];

  @override
  void initState() {
    super.initState();
    points = widget.currentPoints;
    dressState = List<int>.filled(dresses.length, 0);
  }

  @override
  void didUpdateWidget(covariant ShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPoints != oldWidget.currentPoints) {
      setState(() {
        points = widget.currentPoints;
      });
    }
  }

  // ------------------------
  // 포인트 업데이트
  // ------------------------
  Future<void> updatePoints(int newPoints) async {
    if (!mounted) return;

    setState(() {
      points = newPoints;
    });

    widget.onPointsChanged(points);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'point': points});
    }
  }

  // ------------------------
  // 드레스 구매
  // ------------------------
  Future<bool> buyDress(int index, int price) async {
    if (points < price) return false;

    await updatePoints(points - price);

    if (!mounted) return false;

    setState(() {
      for (int i = 0; i < dressState.length; i++) {
        if (dressState[i] == 2) dressState[i] = 0;
      }
      dressState[index] = 2; // 착용중
      topImage = dresses[index]['image'];
    });

    return true;
  }

  // ------------------------
  // 스프레이 구매
  // ------------------------
  Future<bool> buySpray(int index) async {
    final int price = sprays[index]['price'] as int;
    if (points < price) return false;

    await updatePoints(points - price);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Shop', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          // -------------------------------------
          // 상단 캐릭터 미리보기
          // -------------------------------------
          Container(
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      topImage = 'assets/sprout.png';
                      dressState = List<int>.filled(dresses.length, 0);
                    });
                  },
                ),

                Expanded(
                  child: Center(
                    child: Image.asset(topImage, fit: BoxFit.contain),
                  ),
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("포인트", style: TextStyle(fontSize: 12)),
                    Text(
                      "$points P",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),

              children: [
                //------------------------------------
                //        스프레이 섹션
                //------------------------------------
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: sprays.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final s = sprays[index];

                      return Container(
                        width: 160,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.asset(s['image'], fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s['grow'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text("${s['price']}P",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.green)),
                            const SizedBox(height: 6),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size(double.infinity, 36)),
                              onPressed: () async {
                                bool ok = await buySpray(index);
                                if (!ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("포인트가 부족합니다.")),
                                  );
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("스프레이 구매 완료!")),
                                );
                              },
                              child: const Text("구매하기",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 13)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                //------------------------------------
                //        드레스 섹션
                //------------------------------------
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dresses.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 24,
                  ),
                  itemBuilder: (context, index) {
                    final dress = dresses[index];
                    final int state = dressState[index];

                    String btnText;
                    Color btnColor = Colors.green;

                    if (state == 0) {
                      btnText = "착용해보기";
                    } else if (state == 1) {
                      btnText = "구매하기";
                    } else {
                      btnText = "착용 중";
                      btnColor = Colors.grey;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: state == 2 ? Colors.green : Colors.grey.shade300,
                            width: state == 2 ? 3 : 1),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(18)),
                              child: Image.asset(
                                dress['image'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(dress['name'],
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),

                          const SizedBox(height: 4),

                          Text("${dress['price']}P",
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),

                          const SizedBox(height: 8),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: btnColor,
                                minimumSize: const Size(double.infinity, 40),
                              ),
                              onPressed: state == 2
                                  ? null
                                  : () async {
                                if (state == 0) {
                                  // 착용해보기 → 구매하기
                                  setState(() {
                                    for (int i = 0; i < dressState.length; i++) {
                                      if (dressState[i] != 2) dressState[i] = 0;
                                    }
                                    dressState[index] = 1;
                                    topImage = dress['image'];
                                  });
                                  return;
                                }

                                if (state == 1) {
                                  bool ok = await buyDress(index, dress['price']);
                                  if (!ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text("포인트 부족!")));
                                    return;
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                          Text("${dress['name']} 구매 완료!")));
                                }
                              },
                              child: Text(btnText,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
