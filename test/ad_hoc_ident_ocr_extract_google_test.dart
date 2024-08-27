import 'package:ad_hoc_ident_ocr/ad_hoc_ident_ocr.dart';
import 'package:ad_hoc_ident_ocr_extract_google/ad_hoc_ident_ocr_extract_google.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MockRecognizer implements TextRecognizer {
  final List<String> lines;

  MockRecognizer(this.lines);

  @override
  Future<void> close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  // TODO: implement id
  String get id => throw UnimplementedError();

  @override
  Future<RecognizedText> processImage(InputImage inputImage) async {
    return RecognizedText(text: lines.reduce(_mergeString), blocks: [
      TextBlock(
          text: lines.reduce(_mergeString),
          lines: lines
              .map(
                (line) => TextLine(
                    text: line,
                    elements: [],
                    boundingBox: Rect.zero,
                    recognizedLanguages: [],
                    cornerPoints: [],
                    confidence: null,
                    angle: null),
              )
              .toList(),
          boundingBox: Rect.zero,
          recognizedLanguages: [],
          cornerPoints: [])
    ]);
  }

  @override
  // TODO: implement script
  TextRecognitionScript get script => throw UnimplementedError();

  String _mergeString(String a, String b) => a + b;
}

void main() {
  test('detects the MRZ text of an input image', () async {
    const testLines = ['example', 'text'];
    final mockRecognizer = MockRecognizer(testLines);
    final extractor = GoogleOcrTextExtractor(recognizer: mockRecognizer);
    final mockImage = OcrImage(
        singlePlaneBytes: Uint8List.fromList([]),
        singlePlaneBytesPerRow: 0,
        width: 0,
        height: 0,
        rawImageFormat: 17);

    final result = await extractor.extract(mockImage);

    // flatten to lines
    final resultLines = result!.reduce(
      (value, element) => value.followedBy(element).toList(),
    );

    // The result is allowed to deviate slightly,
    // so this test is actually too strict.
    // Adjust it if there is a better way to test this.
    expect(resultLines, containsAllInOrder(testLines));
  });
}
