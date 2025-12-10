// 파일 위치: lib/guide/recycle_model.dart
import 'package:flutter/material.dart';

class RecycleItem {
  final String name;
  final String description;

  RecycleItem({required this.name, required this.description});
}

class RecycleGuide {
  final String id;
  final String title;
  final String subTitle;
  final Color themeColor;
  final IconData icon;
  final List<String> steps;
  final List<RecycleItem> possibleItems;
  final List<RecycleItem> impossibleItems;

  RecycleGuide({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.themeColor,
    required this.icon,
    required this.steps,
    required this.possibleItems,
    required this.impossibleItems,
  });
}