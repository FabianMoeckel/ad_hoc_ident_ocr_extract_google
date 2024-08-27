import 'dart:io';
import 'dart:ui';

import 'package:ad_hoc_ident_ocr/ad_hoc_ident_ocr.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Tries to extract text data from an [OcrImage]
/// using the Google ML Kit OCR engine.
///
/// Accepts only nv21 format for Android or bgra8888 format for iOS.
class GoogleOcrTextExtractor implements OcrTextExtractor {
  final TextRecognizer _textRecognizer;

  /// Creates a [GoogleOcrTextExtractor].
  ///
  /// If no [recognizer] is provided, the extractor defaults to a
  /// [TextRecognizer] with [TextRecognitionScript.latin].
  GoogleOcrTextExtractor({TextRecognizer? recognizer})
      : _textRecognizer =
            recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  /// Extracts text data from an [OcrImage].
  ///
  /// Accepts only nv21 format for Android or bgra8888 format for iOS.
  @override
  Future<List<List<String>>?> extract(OcrImage image) async {
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
    final sensorOrientation = image.cameraSensorOrientation.toInt();
    InputImageRotation? rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.rawImageFormat);

    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    // compose InputImage using bytes
    final inputImage = InputImage.fromBytes(
      bytes: image.singlePlaneBytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: image.singlePlaneBytesPerRow, // used only in iOS
      ),
    );

    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.blocks
        .map((e) => e.lines.map((line) => line.text).toList())
        .toList();
  }

  @override
  Future<void> close() async => await _textRecognizer.close();
}
