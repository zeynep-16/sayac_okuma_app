// lib/pages/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/user_service.dart';
import 'profile_edit_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _service = UserService();
  Map<String, dynamic>? _profile;
  DateTimeRange? _range;
  int? _count;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final p = await _service.getProfile(uid);

    // GÜNCELLEME: start/end parametreleri
    final c = await _service.getReadingsCount(
      uid,
      start: _range?.start,
      end: _range?.end,
    );

    if (!mounted) return;
    setState(() {
      _profile = p;
      _count = c;
    });
  }

  Future<void> _pickRange() async {
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
      await _load(); // sayıyı range ile yeniden çek
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '-';
    final name = _profile?['display_name'] ?? '';
    final phone = _profile?['phone'] ?? '';
    final photoUrl = _profile?['photo_url'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final changed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileEditPage(
                    initialName: name,
                    initialPhone: phone,
                  ),
                ),
              );

              // context guard (uyarıyı önler)
              if (!mounted) return;

              if (changed == true) {
                await _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil güncellendi.')),
                  );
                }
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? const Icon(Icons.person, size: 36)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'İsimsiz' : name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(color: Colors.grey)),
                      if (phone.isNotEmpty) Text(phone),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Okuma Sayım',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Tarih Filtresi'),
                ),
                if (_range != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    "${DateFormat('yyyy-MM-dd').format(_range!.start)} — "
                    "${DateFormat('yyyy-MM-dd').format(_range!.end)}",
                  ),
                  IconButton(
                    tooltip: 'Temizle',
                    icon: const Icon(Icons.clear),
                    onPressed: () async {
                      setState(() => _range = null);
                      await _load();
                    },
                  )
                ]
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: Text(
                  _count == null ? '-' : _count.toString(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Toplam okunan sayaç kaydı'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
