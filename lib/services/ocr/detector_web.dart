import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:ui';

import '../../models/detection_match.dart';
import 'classifier.dart';
import 'detector.dart';
import 'ocr_models.dart';

/// Creates the web detector, which runs OCR in the browser with Tesseract.js.
Detector createDetector() => WebDetector();

/// OCR using Tesseract.js. It runs entirely in the browser (no upload), reads
/// English and German, and returns the position of every word so we can blur
/// tightly. QR detection is only available on mobile (ML Kit).
class WebDetector implements Detector {
  @override
  Future<List<DetectionMatch>> detect({
    required Uint8List bytes,
    String? filePath,
    required Set<String> enabledKeys,
    required List<String> keywords,
    required bool german,
  }) async {
    // Pass the image to Tesseract as a data URL.
    final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
    final langs = german ? 'eng+deu' : 'eng';

    // Tesseract.js v5 only returns `data.text` unless we explicitly ask for the
    // block/line/word structure. Passing `{ blocks: true }` makes it include
    // `data.lines[].words[].bbox`, which we need to blur each word tightly.
    final options = JSObject();
    options.setProperty('blocks'.toJS, true.toJS);
    final result = await _recognize(dataUrl.toJS, langs.toJS, options).toDart;

    // Build our shared line/word model from Tesseract's result.
    final lines = <OcrLine>[];
    final jsLinesRaw = result.data.lines;
    final jsLines = jsLinesRaw == null ? <_TLine>[] : jsLinesRaw.toDart;
    for (final jsLine in jsLines) {
      final words = <OcrWord>[];
      final jsWords = jsLine.words.toDart;
      for (final jsWord in jsWords) {
        final b = jsWord.bbox;
        words.add(OcrWord(
          jsWord.text,
          Rect.fromLTRB(
            b.x0.toDouble(),
            b.y0.toDouble(),
            b.x1.toDouble(),
            b.y1.toDouble(),
          ),
        ));
      }
      lines.add(OcrLine(jsLine.text, words));
    }

    return classifyLines(lines, enabledKeys, keywords);
  }

  @override
  void dispose() {}
}

// ---- Tesseract.js interop ------------------------------------------------

@JS('Tesseract.recognize')
external JSPromise<_TResult> _recognize(
    JSString image, JSString langs, JSObject options);

extension type _TResult(JSObject _) implements JSObject {
  external _TData get data;
}

extension type _TData(JSObject _) implements JSObject {
  external JSArray<_TLine>? get lines;
}

extension type _TLine(JSObject _) implements JSObject {
  external String get text;
  external JSArray<_TWord> get words;
}

extension type _TWord(JSObject _) implements JSObject {
  external String get text;
  external _TBox get bbox;
}

extension type _TBox(JSObject _) implements JSObject {
  external int get x0;
  external int get y0;
  external int get x1;
  external int get y1;
}
