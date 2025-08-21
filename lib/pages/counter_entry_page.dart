// lib/pages/counter_entry_page.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// OCR servisi importu
import '../services/ocr_service.dart';
// transaction’lı ekleme için service
import '../services/reading_service.dart';

// fotoğraf yolu alarak sayaç girişi yapan sayfa
class CounterEntryPage extends StatefulWidget {
  final String photoPath;
  const CounterEntryPage({super.key, required this.photoPath});

  @override
  State<CounterEntryPage> createState() => _CounterEntryPageState();
}

class _CounterEntryPageState extends State<CounterEntryPage> {
  // form doğrulama için global key
  final _formKey = GlobalKey<FormState>();

  // form alanlı controller'ları
  final _sayacNoCtrl = TextEditingController();
  final _degerCtrl = TextEditingController();
  final _lokasyonCtrl = TextEditingController();
  final _notCtrl = TextEditingController();

  //  OCR servisi ve durum bayrağı
  final OcrService _ocr = OcrService();
  bool _ocring = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Ekran açılır açılmaz görüntüyü tara ve alanı doldur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runOcr();
    });
  }

  @override
  void dispose() {
    // bellek sızıntılarını önlemek için controller'ları serbest bırak
    _sayacNoCtrl.dispose();
    _degerCtrl.dispose();
    _lokasyonCtrl.dispose();
    _notCtrl.dispose();

    // OCR'i kapat
    _ocr.dispose();
    super.dispose();
  }

  // OCR çalıştır ve _degerCtrl'i otomatik doldur
  Future<void> _runOcr() async {
    if (_ocring) return;
    setState(() => _ocring = true);
    try {
      final res = await _ocr.readMeterFromFile(widget.photoPath);
      if (res.bestNumeric != null && res.bestNumeric!.isNotEmpty) {
        _degerCtrl.text = res.bestNumeric!;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Otomatik okuma: ${res.bestNumeric}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Değer tespit edilemedi, manuel girebilirsiniz.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _ocring = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Kullanıcı girişi zorunlu
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce giriş yapın.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = user.uid;

      // 1) Fotoğrafı Base64'e çevir
      final bytes = await File(widget.photoPath).readAsBytes();
      final photoB64 = base64Encode(bytes);

      // 2) Değer mutlaka sayı olsun (virgül nokta dönüşümü dahil)
      final valueText = _degerCtrl.text.trim().replaceAll(',', '.');
      final value = double.tryParse(valueText);
      if (value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Okunan değer sayı olmalı')),
        );
        return;
      }

      // 3) Transaction’lı ekleme (aynı değer engeli service + rules)
      await ReadingService().addReading(
        uid: uid,
        sayacNo: _sayacNoCtrl.text.trim(),
        deger: value,
        extra: {
          'kullanici_id': uid,
          'okuma_tarihi': DateTime.now().toIso8601String().split('T').first,
          'lokasyon': _lokasyonCtrl.text.trim().isEmpty ? null : _lokasyonCtrl.text.trim(),
          'not': _notCtrl.text.trim().isEmpty ? null : _notCtrl.text.trim(),

          // Base64 alanları
          'photo_b64': photoB64,
          'photo_mime': 'image/jpeg',
          'photo_size': bytes.lengthInBytes,

          'created_at': Timestamp.now(),
          'updated_at': Timestamp.now(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sayaç listeye eklendi.')),
      );
      Navigator.pop(context, true); // listeleri tazelemek için true döndü
    } on StateError catch (e) {
      // İş kuralı ihlâli: aynı değer
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Aynı değerle eklenemez.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt başarısız: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sayaç Bilgisi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.photoPath),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _sayacNoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sayaç No',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Sayaç No gerekli' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _degerCtrl,
                      decoration: InputDecoration(
                        labelText: 'Okunan Değer',
                        prefixIcon: const Icon(Icons.speed_outlined),
                        border: const OutlineInputBorder(),
                        //  OCR durum göstergesi / tekrar tara düğmesi
                        suffixIcon: _ocring
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Görüntüyü tekrar tara',
                                icon: const Icon(Icons.document_scanner_outlined),
                                onPressed: _runOcr,
                              ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Okunan değer gerekli' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lokasyonCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lokasyon (opsiyonel)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Not (opsiyonel)',
                        prefixIcon: Icon(Icons.note_outlined),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(_saving ? 'Yükleniyor...' : 'Listeye Ekle'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
