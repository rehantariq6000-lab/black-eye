import 'dart:ui';

/// One recognised word and where it sits on the image (in image pixels).
class OcrWord {
  final String text;
  final Rect box;
  const OcrWord(this.text, this.box);
}

/// One recognised line of text, made up of words. We keep the words so we can
/// blur only the exact words that are sensitive, not the whole line.
class OcrLine {
  final String text;
  final List<OcrWord> words;
  const OcrLine(this.text, this.words);
}
