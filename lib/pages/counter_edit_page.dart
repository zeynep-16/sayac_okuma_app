// lib/pages/counter_edit_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/counter_service.dart';
import 'package:geolocator/geolocator.dart';
// ters geokodlama için
import 'package:geocoding/geocoding.dart';

class CounterEditPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const CounterEditPage({
    super.key,
    required this.docId,
    required this.initialData,
  });

  @override
  State<CounterEditPage> createState() => _CounterEditPageState();
}

class _CounterEditPageState extends State<CounterEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _sayacNoCtrl = TextEditingController();
  final _degerCtrl = TextEditingController();
  final _lokasyonCtrl = TextEditingController();
  
  //konum butonuna basıldığında yükleniyor durumunu tutmak için
  bool _locLoading = false; 

  late final CounterService _service;

  @override
  void initState() {
    super.initState();
    _service = CounterService();

    _sayacNoCtrl.text =
        (widget.initialData['sayac_no']?.toString() ?? '').replaceAll('"', '');
    _degerCtrl.text = widget.initialData['deger']?.toString() ?? '';
    _lokasyonCtrl.text = widget.initialData['lokasyon']?.toString() ?? '';
  }

  @override
  void dispose() {
    _sayacNoCtrl.dispose();
    _degerCtrl.dispose();
    _lokasyonCtrl.dispose();
    super.dispose();
  }
  
  //Lokasyon izin kontrol fonksiyonu
  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum servisleri kapalı. Lütfen açın.')),
        );
      }
      return false;
    }
    //Uygulamanın konum izni var mı?
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum izni verilmedi.')),
        );
      }
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum izni kalıcı olarak reddedildi. Ayarlardan değiştirin.'),
          ),
        );
      }
      return false;
    }
    return true;
  }

  // Koordinatı şehir/ilçe adına çevirir, bulunamazsa koordinatı yazar
  Future<void> _getAndFillLocation() async {
    if (_locLoading) return;
    setState(() => _locLoading = true);
    try {
      final ok = await _ensureLocationPermission();
      if (!ok) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String display = '${pos.latitude}, ${pos.longitude}'; // varsayılan
      try {
        final placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;

          // şehir ve ilçe için güvenli alan seçimi
          final city =
              (p.administrativeArea != null && p.administrativeArea!.trim().isNotEmpty)
                  ? p.administrativeArea
                  : p.locality;
          final district = (p.subAdministrativeArea != null &&
                  p.subAdministrativeArea!.trim().isNotEmpty)
              ? p.subAdministrativeArea
              : p.locality;

          final parts = <String>[
            if (city != null && city!.trim().isNotEmpty) city!,
            if (district != null && district!.trim().isNotEmpty) district!,
          ];
          if (parts.isNotEmpty) {
            display = parts.join(' / ');
          }
        }
      } catch (_) {
        // ters geokodlama başarısızsa koordinat göster
      }

      _lokasyonCtrl.text = display;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konum alınamadı: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = widget.initialData['created_at'];
    String createdInfo = '-';
    if (createdAt != null) {
      try {
        final dt = (createdAt as dynamic).toDate();
        createdInfo =
            '${DateFormat('yyyy-MM-dd').format(dt)} ${DateFormat('HH:mm').format(dt)}';
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sayaç Düzenle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _LabeledField(
                label: 'Sayaç No',
                child: TextFormField(
                  controller: _sayacNoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Örn: 123456',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Sayaç numarası zorunludur';
                    }
                    if (RegExp(r'[^0-9]').hasMatch(v)) {
                      return 'Sadece rakam giriniz';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Değer',
                child: TextFormField(
                  controller: _degerCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'Örn: 456.78',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Değer zorunludur';
                    }
                    if (double.tryParse(v.replaceAll(',', '.')) == null) {
                      return 'Geçerli bir sayı giriniz';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Lokasyon',
                child: TextFormField(
                  controller: _lokasyonCtrl,
                  decoration: InputDecoration(
                    hintText: 'Örn: Blok A - Kat 2 veya otomatik doldur',
                    border: const OutlineInputBorder(),
                    suffixIcon: _locLoading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'GPS ile doldur',
                            icon: const Icon(Icons.my_location),
                            onPressed: _getAndFillLocation,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Text('Oluşturulma: ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(createdInfo),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Kaydet'),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final uid = FirebaseAuth.instance.currentUser!.uid;

                    final sayacNo = _sayacNoCtrl.text.trim();
                    final degerRaw =
                        _degerCtrl.text.trim().replaceAll(',', '.');
                    final degerNum = double.tryParse(degerRaw);

                    final updates = <String, dynamic>{
                      'sayac_no': sayacNo,
                      'deger': degerNum ?? _degerCtrl.text.trim(),
                      'lokasyon': _lokasyonCtrl.text.trim(),
                    };

                    try {
                      await _service.updateReading(
                        uid: uid,
                        docId: widget.docId,
                        data: updates,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kayıt güncellendi')),
                      );
                      Navigator.pop(context, true);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Güncelleme hatası: $e')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
