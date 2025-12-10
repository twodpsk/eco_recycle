import 'package:flutter/material.dart';
import 'basket.dart';

class OfflineShopScreen extends StatefulWidget {
  const OfflineShopScreen({super.key});

  @override
  State<OfflineShopScreen> createState() => _OfflineShopScreenState();
}

class _OfflineShopScreenState extends State<OfflineShopScreen> {
  int selectedTab = 0; // 0: 굿즈, 1: 교육
  List<Map<String, dynamic>> cart = []; // 장바구니

  final tabNames = ["굿즈", "교육"];

  final List<List<Map<String, dynamic>>> products = [
    // 굿즈
    [
      {"image": "goods1.png", "text": "키링", "price": 3000},
      {"image": "goods2.png", "text": "인형", "price": 4000},
      {"image": "goods3.png", "text": "스트레스볼", "price": 2000},
      {"image": "goods4.png", "text": "노트", "price": 2000},
      {"image": "goods5.png", "text": "장바구니", "price": 2500},
      {"image": "goods6.png", "text": "샤프", "price": 4500},
    ],
    // 교육
    [
      {"image": "education1.png", "text": "미니태양광 만들기 키트", "price": 6000},
      {"image": "education2.png", "text": "나만의 에코백 꾸미기 키트", "price": 6000},
      {"image": "education3.png", "text": "분리수거함", "price": 20000},
      {"image": "education4.png", "text": "색칠공부", "price": 4000},
      {"image": "education5.png", "text": "허브 키우기 키트", "price": 5500},
      {"image": "education6.png", "text": "천연 비누 만들기 키트", "price": 6500},
    ],
  ];

  void addToCart(Map<String, dynamic> item) {
    setState(() {
      cart.add(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("오프라인 상점"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: List.generate(tabNames.length, (index) {
                final isSelected = selectedTab == index;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedTab = index;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        isSelected ? Colors.green : Colors.grey[200],
                        foregroundColor:
                        isSelected ? Colors.white : Colors.green[800],
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        tabNames[index],
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.52,
              ),
              itemCount: products[selectedTab].length,
              itemBuilder: (context, index) {
                final item = products[selectedTab][index];
                final imagePath = 'assets/shop/${item['image']}';

                bool isGoods5 =
                    selectedTab == 0 && item['text'] == "장바구니";

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.green[50], // 연두색 배경 통일
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 7,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50], // 연두색 배경
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: isGoods5
                                ? Center(
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, stackTrace) {
                                  return const SizedBox();
                                },
                              ),
                            )
                                : Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return const SizedBox();
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item['text'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 5),
                            Text("${item['price']}원",
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              onPressed: () => addToCart(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.green[800],
                                minimumSize: const Size(100, 30),
                                side: BorderSide(color: Colors.green.shade700),
                              ),
                              child: const Text("장바구니 담기",
                                  style: TextStyle(fontSize: 12)),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        alignment: Alignment.topRight,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BasketScreen(cart: cart)));
            },
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shopping_cart),
          ),
          if (cart.isNotEmpty)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(1, 2))
                  ],
                ),
                child: Text(
                  "${cart.length}",
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
