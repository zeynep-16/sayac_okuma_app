// lib/services/user_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data();
  }

  /// Profil ekle/güncelle. photoFile verildiyse Storage'a yükler, URL'yi kaydeder.
  Future<void> upsertProfile({
    required String uid,
    required String displayName,
    required String phone,
    String? email,                 // ilk set'te ekleyebilirsin
    File? photoFile,               // opsiyonel
  }) async {
    String? photoUrl;

    if (photoFile != null) {
      final ref = _storage.ref().child('avatars/$uid.jpg');
      await ref.putFile(photoFile);
      photoUrl = await ref.getDownloadURL();
    }

    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'display_name': displayName,
      'phone': phone,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photo_url': photoUrl,
      'updated_at': now,
    };

    // Belge yoksa created_at de bas
    final docRef = _db.collection('users').doc(uid);
    final exists = (await docRef.get()).exists;
    if (!exists) data['created_at'] = now;

    await docRef.set(data, SetOptions(merge: true));
  }

  /// Toplam okuma sayısı (isteğe bağlı tarih filtresiyle)
  /// UI bağımlılığı olmaması için DateTimeRange yerine start/end alıyoruz.
  Future<int> getReadingsCount(
    String uid, {
    DateTime? start,
    DateTime? end,
  }) async {
    Query q = _db.collection('users').doc(uid).collection('readings');

    // Tarih sınırlarını gün başı / ertesi gün başı olacak şekilde normalize et
    final DateTime? s = (start != null) ? DateTime(start.year, start.month, start.day) : null;
    final DateTime? e = (end != null) ? DateTime(end.year, end.month, end.day).add(const Duration(days: 1)) : null;

    if (s != null) {
      q = q.where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(s));
    }
    if (e != null) {
      q = q.where('created_at', isLessThan: Timestamp.fromDate(e));
    }

    final agg = await q.count().get(); // Aggregate query
    return agg.count ?? 0; // bazı sürümlerde nullable
  }
}
