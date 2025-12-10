// lib/home/basket.dart
import 'package:flutter/material.dart';

class BasketScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  const BasketScreen({super.key, required this.cart});

  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  String selectedCity = "서울특별시";
  String detailAddress = "";

  int get totalPrice {
    return widget.cart.fold(0, (sum, item) => sum + (item['price'] as int));
  }

  void checkout() async {
    final addrController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("주소 입력"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedCity,
                  items: const [
                    "서울특별시",
                    "부산광역시",
                    "대구광역시",
                    "인천광역시",
                    "광주광역시",
                    "대전광역시",
                    "울산광역시",
                    "세종특별자치시",
                  ].map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedCity = value!;
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addrController,
                  decoration: const InputDecoration(hintText: "상세주소 입력"),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("취소")),
              TextButton(
                  onPressed: () {
                    detailAddress = addrController.text;
                    Navigator.pop(context);
                  },
                  child: const Text("확인")),
            ],
          );
        });
      },
    );

    if (detailAddress.isEmpty) return;

    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("구매 확인"),
        content: Text(
            "주소: $selectedCity $detailAddress\n총 금액: $totalPrice 원\n구매하시겠습니까?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("아니요")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("예")),
        ],
      ),
    );

    if (confirm == true) {
      await showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("구매 완료"),
          content: Text("구매가 완료되었습니다!"),
        ),
      );
      setState(() {
        widget.cart.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("장바구니"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.cart.length,
              itemBuilder: (context, index) {
                final item = widget.cart[index];
                final imagePath = 'assets/shop/${item['image']}';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                                child: Text(item['text'] ?? '',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 10)));
                          },
                        ),
                      ),
                    ),
                    title: Text(item['text'] ?? ''),
                    trailing: Text("${item['price']}원"),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.green[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("총합계: $totalPrice 원",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: widget.cart.isEmpty ? null : checkout,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20)),
                  child: const Text("결제하기", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
