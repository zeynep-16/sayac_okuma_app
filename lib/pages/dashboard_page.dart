import 'package:flutter/material.dart';
import 'dart:convert'; // <-- eklendi (Base64 decode için)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'counter_entry_page.dart';
import 'counter_edit_page.dart';
import 'package:intl/intl.dart'; // tarih-saat formatlama

// Silme işlemi için servis
import '../services/counter_service.dart';

// Stateful yapıldı (tarih filtresi durumu için)
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // tarih aralığı (null = filtre yok)
  DateTimeRange? _range;

  // servis örneği
  final _counterService = CounterService();

  Future<void> _pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Fotoğraf Kaynağı Seç"),
          content: const Text("Sayaç fotoğrafını nasıl almak istersiniz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, ImageSource.camera),
              child: const Text("Kamera"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
              child: const Text("Galeri"),
            ),
          ],
        ),
      );
      if (source == null) return;

      final XFile? photo = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 60,
      );
      if (photo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf alınmadı.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf alındı: ${photo.name}')),
      );

      // await ile dönüş değerini yakala
      final changed = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CounterEntryPage(photoPath: photo.path),
        ),
      );

      if (changed == true && mounted) {
        setState(() {}); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Okuma eklendi.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf alınamadı: $e')),
      );
    }
  }

  // tarih aralığı seçtir
  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _range ??
          DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day),
          ),
    );
    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  // stream’i aralığa göre kur
  Stream<QuerySnapshot> _buildStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    Query q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('readings')
        .orderBy('created_at', descending: true); // mevcut sıralama

    if (_range != null) {
      final start = DateTime(_range!.start.year, _range!.start.month, _range!.start.day);
      final endExclusive = DateTime(_range!.end.year, _range!.end.month, _range!.end.day)
          .add(const Duration(days: 1));

      q = q
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('created_at', isLessThan: Timestamp.fromDate(endExclusive));
    }

    return q.snapshots();
  }

  // Silme akışı servisi kullanıyor (uid + storagePath)
  Future<void> _confirmAndDelete({
    required String docId,
    required String sayacNo,
    String? storagePath,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: Text('#$sayacNo kaydı silinecek. Emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _counterService.deleteCounter(
        uid: uid,
        docId: docId,
        storagePath: storagePath, // opsiyonel
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt silindi.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silme hatası: $e')),
        );
      }
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          // filtre ve temizle
          IconButton(
            tooltip: 'Tarih Aralığı Seç',
            icon: const Icon(Icons.filter_alt),
            onPressed: _pickDateRange,
          ),
          if (_range != null)
            IconButton(
              tooltip: 'Filtreyi Temizle',
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _range = null),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hoş geldiniz, ${user?.email ?? 'Kullanıcı'}!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _pickImage(context),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text("Sayaç Oku"),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Okunmuş Sayaçlar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // seçili aralığı bilgi amaçlı göster
            if (_range != null) ...[
              Row(
                children: [
                  const Icon(Icons.date_range, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "${DateFormat('yyyy-MM-dd').format(_range!.start)} — ${DateFormat('yyyy-MM-dd').format(_range!.end)}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // (Base64 thumbnail + Düzenle + Silme)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Veriler alınırken hata oluştu."));
                  }

                  final documents = snapshot.data!.docs;
                  if (documents.isEmpty) {
                    return const Center(child: Text("Henüz okunmuş sayaç yok."));
                  }

                  return ListView.separated(
                    itemCount: documents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final sayacNo = data['sayac_no']?.toString().replaceAll('"', '') ?? 'Bilinmiyor';
                      final deger = data['deger']?.toString() ?? '-';

                      // created_at'tan tarih + saat üret
                      final tarihStrField = data['okuma_tarihi'] as String?;
                      String datePart = '-';
                      String timePart = '--:--';
                      final createdAt = data['created_at'];

                      if (createdAt != null && createdAt is Timestamp) {
                        final dt = createdAt.toDate();
                        datePart = DateFormat('yyyy-MM-dd').format(dt);
                        timePart = DateFormat('HH:mm').format(dt);
                      } else if (tarihStrField != null && tarihStrField.isNotEmpty) {
                        datePart = tarihStrField;
                      }

                      // Base64 varsa küçük görsel göster
                      final b64 = data['photo_b64'] as String?;
                      Widget leadingWidget;
                      if (b64 != null && b64.isNotEmpty) {
                        try {
                          final bytes = base64Decode(b64);
                          leadingWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              bytes,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          );
                        } catch (_) {
                          leadingWidget = const Icon(
                            Icons.speed_outlined,
                            size: 30,
                            color: Colors.deepPurple,
                          );
                        }
                      } else {
                        leadingWidget = const Icon(
                          Icons.speed_outlined,
                          size: 30,
                          color: Colors.deepPurple,
                        );
                      }

                      // Storage path (varsa)
                      final String? storagePath = data['storage_path'] as String?;

                      // Card bloğu Dismissible ile sarıldı ---
                      return Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart, // sağdan sola kaydır
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          // Kaydırınca da aynı onay/silme akışı
                          await _confirmAndDelete(
                            docId: doc.id,
                            sayacNo: sayacNo,
                            storagePath: storagePath,
                          );
                          // Görsel kaldırmayı stream'e bırakıyoruz
                          return false;
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: leadingWidget,
                            title: Text("Sayaç No: $sayacNo", style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text("Değer: $deger • $datePart $timePart"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                  tooltip: 'Düzenle',
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CounterEditPage(
                                          docId: doc.id,
                                          initialData: data,
                                        ),
                                      ),
                                    );
                                    if (result == true && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Kayıt güncellendi.')),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmAndDelete(
                                    docId: doc.id,
                                    sayacNo: sayacNo,
                                    storagePath: storagePath,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
