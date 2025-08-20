// lib/services/ocr_service.dart
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String fullText;      // Tüm tanınan metin
  final String? bestNumeric;  // En mantıklı sayaç değeri adayı
  OcrResult({required this.fullText, required this.bestNumeric});
}

class OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Ana akış:
  /// 1) Merkez bandını kırp, ondan oku
  /// 2) Olmazsa tüm görselden oku (yedek)
  Future<OcrResult> readMeterFromFile(String filePath) async {
    // 1) Heuristik merkez bandı kırpma denemesi
    final croppedFile = await _tryCropCentralBand(filePath);
    if (croppedFile != null) {
      final resCrop = await _readFileWithScoring(croppedFile.path);
      if (resCrop.bestNumeric != null && resCrop.bestNumeric!.isNotEmpty) {
        // temp dosyayı temizle
        try { await croppedFile.delete(); } catch (_) {}
        return resCrop;
      }
      // işe yaramazsa sil ve tam görsele düş
      try { await croppedFile.delete(); } catch (_) {}
    }

    // 2) Yedek: tam görsel
    return await _readFileWithScoring(filePath);
  }

  /// ML Kit ile oku + adayları akıllı puanla
  Future<OcrResult> _readFileWithScoring(String path) async {
    final inputImage = InputImage.fromFile(File(path));
    final recognized = await _recognizer.processImage(inputImage);
    final fullText = recognized.text;

    // Satır satır sayısal adayları topla
    final List<_Candidate> cands = [];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();

        // Çöp olma ihtimali yüksek satırları hızlı ele: "No", "m3/h", "G4", "CE" vb.
        final lower = text.toLowerCase();
        if (lower.contains('no') || lower.contains('m3') || lower.contains('g4')) {
          // yine de satır içindeki sayıları tamamen yok saymayalım, ama puanlamada eksi vereceğiz
        }

        // 12,3  563.0  7265 gibi adayları bul
        final matches = RegExp(r'\d+(?:[.,]\d+)?').allMatches(text);
        for (final m in matches) {
          var token = m.group(0)!;
          // Tek/iki haneli çok gürültü -> atla
          final digitsOnly = token.replaceAll(RegExp(r'\D'), '');
          if (digitsOnly.length < 3) continue;

          // Onluk ayracı normalize et
          token = token.replaceAll(',', '.');

          final cand = _Candidate(
            raw: token,
            ctx: text,
          );

          // Puanlama (0-100 arası değil ama göreli):
          int score = 0;

          // Uzunluk (5-8 hane genelde sayaç için iyi bir sinyal)
          final len = digitsOnly.length;
          if (len >= 5 && len <= 8) score += 20;
          else if (len == 4) score += 8; // bazen 4 hane de olabilir
          else score += 5; // çok kısa/çok uzun zayıf

          // Ondalık sayı ise bonus (örn. "563.0")
          if (token.contains('.')) score += 10;

          // 1900-2100 arası "yıl" gibi görünen 4 hane -> ağır ceza
          final asInt = int.tryParse(digitsOnly);
          if (len == 4 && asInt != null && asInt >= 1900 && asInt <= 2100) {
            score -= 25;
          }

          // "No" gibi serino bağlamı -> ceza
          if (lower.contains('no')) score -= 12;

          // Başında uzun 0 dizileri -> ceza (örn. 07123456)
          if (digitsOnly.length >= 5 && digitsOnly.startsWith('0')) {
            score -= 10;
          }

          // m3/h, G4 vb. teknik ifadeler varsa hafif ceza
          if (lower.contains('m3') || lower.contains('g4') || lower.contains('ce')) {
            score -= 6;
          }

          // Çok fazla nokta/virgül -> ceza
          if (RegExp(r'[.,].*[.,]').hasMatch(token)) score -= 8;

          cand.score = score;
          cands.add(cand);
        }
      }
    }

    // Skora göre sırala ve en iyisini seç
    cands.sort((a, b) => b.score.compareTo(a.score));
    String? best;
    if (cands.isNotEmpty) {
      best = cands.first.raw;
      // Ondalık ayırıcıyı hep '.' olarak döndürdük; istersen burada yerelleştirebilirsin
    }

    return OcrResult(fullText: fullText, bestNumeric: best);
  }

  /// Görselin merkezindeki yatay bandı kırpar.
  /// Heuristik: genişliğin %86'sı, yüksekliğin orta %52'lik bandı.
  /// (Mekanik sayaç penceresi genelde merkezde olduğu için serinoyu dışarıda bırakmayı hedefler)
  Future<File?> _tryCropCentralBand(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) return null;

      final w = src.width;
      final h = src.height;

      final cropW = (w * 0.86).round();
      final cropH = (h * 0.52).round();
      final left = ((w - cropW) / 2).round();
      final top  = ((h - cropH) / 2).round();

      final cropped = img.copyCrop(src, x: left, y: top, width: cropW, height: cropH);
      final jpg = img.encodeJpg(cropped, quality: 92);

      final tmpPath =
          '${Directory.systemTemp.path}/ocr_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final f = File(tmpPath);
      await f.writeAsBytes(jpg, flush: true);
      return f;
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}

class _Candidate {
  final String raw;
  final String ctx; // bulunduğu satır (bağlam)
  int score;
  _Candidate({required this.raw, required this.ctx, this.score = 0});
}
