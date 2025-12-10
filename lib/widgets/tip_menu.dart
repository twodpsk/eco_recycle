import 'package:flutter/material.dart';

// [중요] 여기 Import 경로를 수정했습니다.
// 만약 아래 줄에서 에러가 나면 Ecorecycle 을 ecorecycle (소문자)로 바꿔보세요.
import 'package:Ecorecycle/guide/recycle_data.dart';
import 'package:Ecorecycle/guide/recycle_detail_screen.dart';
import 'package:Ecorecycle/guide/recycle_model.dart';

class TipMenu extends StatelessWidget {
  const TipMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        // 이제 recycleData를 정상적으로 찾을 수 있을 겁니다.
        itemCount: recycleData.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final guide = recycleData[index];
          return _buildTipCard(context, guide);
        },
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, RecycleGuide guide) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecycleDetailScreen(guide: guide),
          ),
        );
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: guide.themeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: guide.themeColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.grey.withOpacity(0.15),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    color: guide.themeColor.withOpacity(0.2),
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Icon(
                guide.icon,
                size: 32,
                color: guide.themeColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              guide.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}