// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 게시글 (Firestore 문서)과 연결된 Storage 이미지 파일을 모두 삭제하는 함수
  Future<void> deletePost(String postId, String imageUrl, String postUserId) async {
    final currentUserId = _auth.currentUser?.uid;

    // 1. 권한 확인 (보안 강화)
    if (currentUserId == null || currentUserId != postUserId) {
      throw Exception('삭제 권한이 없습니다. 이 게시글의 작성자만 삭제할 수 있습니다.');
    }

    try {
      // 2. Firestore 문서 삭제
      await _db.collection('certifications').doc(postId).delete();
      print('Firestore 문서 삭제 성공: $postId');

      // 3. Storage 이미지 파일 삭제
      final storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
      print('Storage 파일 삭제 성공');

    } on FirebaseException catch (e) {
      print('Firebase 삭제 오류: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('일반 삭제 오류 발생: $e');
      rethrow;
    }
  }
}