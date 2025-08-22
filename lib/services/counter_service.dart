// lib/services/counter_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CounterService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// Firestore belgesini ve varsa Storage görselini siler.
  /// storagePath: "sayac_fotograflari/abc123.jpg" gibi bir yol tutulduğunu varsayar.
  Future<void> deleteCounter({
    required String uid,        // kullanıcıya özel yol için gerekli
    required String docId,
    String? storagePath,
  }) async {
    // 1) Önce Storage'daki görseli sil (varsa)
    if (storagePath != null && storagePath.trim().isNotEmpty) {
      try {
        await _storage.ref(storagePath).delete();
      } catch (_) {
        // Görsel yoksa ya da yetki yoksa uygulamayı düşürme.
        // Gerekirse log basabilirsin.
      }
    }

    // 2) Firestore belgesini sil (doğru yol: users/{uid}/readings/{docId})
    await _db
        .collection('users')
        .doc(uid)
        .collection('readings')
        .doc(docId)
        .delete();
  }

  /// users/{uid}/readings/{docId} yolundaki okuma kaydını günceller.
  /// Örn. data: {'sayac_no': '123', 'deger': 456.7, 'lokasyon': 'Blok A'}
  Future<void> updateReading({
    required String uid,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    // son düzenleme zamanını otomatik ekle
    data['updated_at'] = FieldValue.serverTimestamp();

    await _db
        .collection('users')
        .doc(uid)
        .collection('readings')
        .doc(docId)
        .update(data);
  }
}
