// 파일 위치: lib/guide/recycle_detail_screen.dart
import 'package:flutter/material.dart';
import 'recycle_model.dart';

class RecycleDetailScreen extends StatelessWidget {
  final RecycleGuide guide;

  const RecycleDetailScreen({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(guide.title),
        backgroundColor: guide.themeColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: guide.themeColor,
              padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              child: Column(
                children: [
                  Icon(guide.icon, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    guide.subTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("♻️ 분리배출 4원칙", style: _headerStyle()),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: guide.steps.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    color: Colors.grey[100],
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: guide.themeColor.withOpacity(0.2),
                            radius: 12,
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                  color: guide.themeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            guide.steps[index],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 40, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text("이건 재활용 돼요!", style: _headerStyle()),
                ],
              ),
            ),
            _buildItemList(guide.possibleItems, true),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.cancel, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text("이건 쓰레기통으로!", style: _headerStyle()),
                ],
              ),
            ),
            _buildItemList(guide.impossibleItems, false),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(List<RecycleItem> items, bool isPossible) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 2,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Icon(
              isPossible ? Icons.check_circle_outline : Icons.highlight_off,
              color: isPossible ? Colors.green : Colors.redAccent,
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item.description),
          ),
        );
      },
    );
  }

  TextStyle _headerStyle() {
    return const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  }
}