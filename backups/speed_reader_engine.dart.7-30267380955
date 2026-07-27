class SpeedReaderEngine {
  final String text;
  List<String> _words = [];

  SpeedReaderEngine({required this.text}) {
    _prepareWords();
  }

  void _prepareWords() {
    if (text.isEmpty) {
      _words = ['Metin', 'bulunamadı!'];
      return;
    }
    // Metni boşluklardan ve yeni satırlardan arındırarak kelimelere böler
    _words = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
  }

  List<String> get words => _words;

  /// Kelimenin uzunluğuna göre odaklanılacak harfin indeksini verir (Spritz standardı)
  static int getOptimalFocusIndex(String word) {
    int length = word.length;
    if (length <= 1) return 0;
    if (length <= 5) return 1;
    if (length <= 9) return 2;
    if (length <= 13) return 3;
    return 4;
  }
}
