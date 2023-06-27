import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ibandetector/views/text_recognizer/text_painter.dart';
import 'package:ibandetector/views/camera_view.dart';

/// Iban tanıma işlemini yapan metotları içeren, sonuçların ekrana çizilmesinden
/// sorumlu olan sınıftır. Arayüzü [CameraView] sınıfı oluşturur.
class TextRecognizerView extends StatefulWidget {
  const TextRecognizerView({super.key});

  @override
  State<TextRecognizerView> createState() => _TextRecognizerViewState();
}

class _TextRecognizerViewState extends State<TextRecognizerView> {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Türkiyede kullanılan IBAN formatını tanımlayan regex ifadesi.
  final _regexp = RegExp(r'TR\s*([0-9]+\s*)+');
  bool _canProcess = true;

  /// Tanıma işlemi yapılırken ve bittiğinde ayarlanan değişkendir.
  /// Tanıma işlemi yapılırken [true] değerini alır, işlem bittiğinde [false]
  /// değerini alır. Bu değişkenin değeri [true] olduğu sürece tanıma işlemi
  /// yapılmaz.
  bool _isBusy = false;

  /// Ekrana çizilecek olan [CustomPaint] nesnesini tutar.
  /// [CustomPaint] nesnesi, ekrana çizilecek olan metinleri içerir.
  /// Ekrana çizilecek metin yoksa [null] değerini alır.
  CustomPaint? _customPaint;

  /// Ekrana çizilecek olan metinleri tutar. Ekrana çizilecek metin yoksa
  /// [null] değerini alır.
  String? _text;

  @override
  void dispose() async {
    _canProcess = false;
    _textRecognizer.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Iban Detector',
      customPaint: _customPaint,
      text: _text,
      onImage: processImage,
    );
  }

  /// Kamera görüntüsünden veya galeriden alınan fotoğraftaki metinlerin
  /// tanınmasını sağlayan metottur.
  ///
  /// [InputImage] nesnesi içerisinde fotoğrafın boyutu ve rotasyonu bilgileri
  /// bulunur. Bu bilgiler kullanılarak ekrana çizilecek olan metinlerin
  /// konumları hesaplanır.
  ///
  /// Fotoğraftaki metinlerin tanınması için [TextRecognizer] sınıfının
  /// [processImage] metodu kullanılır. Bu metot, [InputImage] nesnesi
  /// parametre olarak alır ve [RecognizedText] nesnesi döndürür. Bu nesne
  /// içerisinde tanınan metinlerin bilgileri bulunur.
  ///
  /// Tanınan metinler içerisinde Türkiyede kullanılan IBAN formatına uygun olan
  /// metin varsa, bu metin ekrana çizilir.
  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy) return;
    _isBusy = true;
    setState(() => _text = '');

    // Görüntüden metinler tanınır.
    final recognizedText = await _textRecognizer.processImage(inputImage);

    // Tanınan metinlerdeki boşluklar ve satır sonları kaldırılır.
    final text = recognizedText.text.replaceAll('\n', '').replaceAll(' ', '');

    // Tanınan metinler içerisinde Türkiyede kullanılan IBAN formatına uygun
    // olan metin varsa olup olmadığı kontrol edilir.
    final hasMatch = _regexp.hasMatch(text);

    if (hasMatch) {
      // Tanınan metinler içerisindeki IBAN çıkartılır.
      final iban = _regexp.allMatches(text).first.group(0)!;

      // IBAN uzunluğu 26 karakter olup olmadığı kontrol edilir.
      if (iban.length == 26) {
        // Tanınan metinler içerisindeki IBAN'ın görüntüdeki konumu block
        // bulunarak tespit edilir.
        final block = recognizedText.blocks.firstWhere(
          (element) => element.text.contains('TR'),
        );

        // Girdi olarak verilen görüntünün boyutu ve rotasyonu bilgileri
        // bilgileri varsa ekrana çizilmesi için bir custom painter kullanılır.
        // Bu bilgiler yoksa ekrana tespit edilen metin yazılır.
        if (inputImage.metadata?.size != null &&
            inputImage.metadata?.rotation != null) {
          final painter = TextRecognizerPainter(
            RecognizedText(
              blocks: [
                TextBlock(
                  text: iban,
                  lines: block.lines,
                  boundingBox: block.boundingBox,
                  recognizedLanguages: block.recognizedLanguages,
                  cornerPoints: block.cornerPoints,
                ),
              ],
              text: iban,
            ),
            inputImage.metadata!.size,
            inputImage.metadata!.rotation,
          );
          _customPaint = CustomPaint(painter: painter);
        } else {
          _text = 'Recognized iban:\n\n$iban';
          _customPaint = null;
        }
      }
    } else {
      // Tanınan metinler içerisinde Türkiyede kullanılan IBAN formatına uygun
      // olan metin yoksa önceden tanınan iban bilgisi silinir.
      _customPaint = null;
      _text = null;
    }

    _isBusy = false;
    if (mounted) setState(() {});
  }
}
