// lib/models/certification_post.dart (사용하지 않더라도 구조 정의를 위해 생성해두는 것이 좋습니다.)

import 'package:cloud_firestore/cloud_firestore.dart';

class CertificationPost {
  final String id;
  final String uid;
  final String description;
  final String imageUrl;
  final Timestamp timestamp;

  CertificationPost({
    required this.id,
    required this.uid,
    required this.description,
    required this.imageUrl,
    required this.timestamp,
  });

  factory CertificationPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Timestamp ts = data['timestamp'] is Timestamp ? data['timestamp'] as Timestamp : Timestamp.now();

    return CertificationPost(
      id: doc.id,
      uid: data['uid'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: ts,
    );
  }
}