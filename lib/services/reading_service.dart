// lib/services/reading_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  /// Yeni okuma eklerken, aynı sayaç için son değerle tamamen aynıysa ekleme.
  /// - Şema: users/{uid}/readings
  Future<void> addReading({
    required String uid,
    required String sayacNo,
    required double deger,
    required Map<String, dynamic> extra, // created_at, okuma_tarihi, foto vs.
  }) async {
    final userRef = _userRef(uid);
    final meterRef = userRef.collection('meters').doc(sayacNo);
    final newReadingRef = userRef.collection('readings').doc(); // yeni id

    await _db.runTransaction((tx) async {
      // 1) sayaç özetini oku
      final meterSnap = await tx.get(meterRef);
      final double? lastValue =
          (meterSnap.data()?['last_value'] as num?)?.toDouble();

      // 2) aynı değer ise reddet
      if (lastValue != null && lastValue == deger) {
        throw StateError(
            'Aynı sayaç için son okuma ile tamamen aynı değer eklenemez.');
      }

      // 3) readings'e yaz
      tx.set(newReadingRef, {
        'sayac_no': sayacNo,
        'deger': deger,
        ...extra, // created_at, okuma_tarihi, photo_b64, mime, size, not, lokasyon, kullanici_id...
      });

      // 4) meters/{sayac_no} özetini oluştur/güncelle
      tx.set(
        meterRef,
        {
          'last_value': deger,
          'last_at': extra['created_at'] ?? FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Geçmiş okumaları tarar, her sayaç için son değeri meters/{sayac_no} içine yazar.
  /// Dönüş: güncellenen sayaç sayısı.
  Future<int> backfillMeters({required String uid}) async {
    final userRef = _userRef(uid);
    final readingsRef = userRef.collection('readings');

    final snap = await readingsRef.get(); // küçük/orta veri için yeterli
    if (snap.docs.isEmpty) return 0;

    // sayac_no -> (time, value)
    final Map<String, ({DateTime at, double value})> lastByMeter = {};

    DateTime? _extractTime(Map<String, dynamic> d) {
      final created = d['created_at'];
      if (created is Timestamp) return created.toDate();

      final updated = d['updated_at'];
      if (updated is Timestamp) return updated.toDate();

      final s = d['okuma_tarihi'];
      if (s is String) {
        try {
          return DateTime.parse(s);
        } catch (_) {}
      }
      return null;
    }

    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final sNo = d['sayac_no'];
      final valRaw = d['deger'];
      if (sNo is! String) continue;
      if (valRaw is! num) continue;

      final t = _extractTime(d) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final v = (valRaw).toDouble();

      final curr = lastByMeter[sNo];
      if (curr == null || t.isAfter(curr.at)) {
        lastByMeter[sNo] = (at: t, value: v);
      }
    }

    if (lastByMeter.isEmpty) return 0;

    final batch = _db.batch();
    lastByMeter.forEach((sNo, rec) {
      final meterRef = userRef.collection('meters').doc(sNo);
      batch.set(
        meterRef,
        {
          'last_value': rec.value,
          'last_at': Timestamp.fromDate(rec.at),
        },
        SetOptions(merge: true),
      );
    });

    await batch.commit();
    return lastByMeter.length;
  }
}
