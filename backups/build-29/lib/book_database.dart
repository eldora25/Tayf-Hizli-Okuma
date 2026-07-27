class BookModel {
  final String id;
  final String title;
  final String format;
  final String content;
  final int totalPages;
  int lastPage;
  int savedWpm;
  int savedMode;

  BookModel({
    required this.id,
    required this.title,
    required this.format,
    required this.content,
    required this.totalPages,
    this.lastPage = 0,
    this.savedWpm = 300,
    this.savedMode = 1,
  });
}

class BookDatabase {
  static final BookDatabase instance = BookDatabase._internal();
  BookDatabase._internal() {
    // Başlangıç için örnek e-kitap varlıkları
    _myBooks.add(BookModel(
      id: "1",
      title: "Nutuk.epub",
      format: "EPUB",
      content: "Hızlı okuma stratejileri birinci sayfa içeriğidir. Odaklanma sınırlarınızı geliştirin. İkinci sayfa içeriği: Blok kelime okuma teknikleri göz kasını büyütür. Üçüncü sayfa içeriği: RSVP motoru sıçramaları engeller.",
      totalPages: 3,
      lastPage: 0,
      savedWpm: 300,
      savedMode: 1,
    ));
    _myBooks.add(BookModel(
      id: "2",
      title: "Hızlı_Okuma_Rehberi.txt",
      format: "TXT",
      content: "Bu rehber hızlı okuma becerilerinizi en üst seviyeye çıkarmak için tasarlanmıştır. İlk aşama göz kası antrenmanıdır. İkinci aşama ise kelimeleri seslendirmeden resim olarak görmektir.",
      totalPages: 2,
      lastPage: 0,
      savedWpm: 350,
      savedMode: 2,
    ));
  }

  final List<BookModel> _myBooks = [];

  List<BookModel> getBooks() => _myBooks;

  void addMultipleBooks(List<Map<String, String>> newBooks) {
    for (var bookData in newBooks) {
      final title = bookData['title'] ?? 'Bilinmeyen Kitap.txt';
      final format = bookData['format'] ?? 'TXT';
      final content = bookData['content'] ?? '';
      
      final id = (_myBooks.length + 1).toString();
      int pages = (content.length / 100).ceil();
      if (pages < 1) pages = 1;

      _myBooks.add(BookModel(
        id: id,
        title: title,
        format: format.toUpperCase(),
        content: content,
        totalPages: pages,
        savedWpm: 300,
        savedMode: 1,
      ));
    }
  }

  void saveProgress(String id, int page, int wpm, int mode) {
    final index = _myBooks.indexWhere((b) => b.id == id);
    if (index != -1) {
      _myBooks[index].lastPage = page;
      _myBooks[index].savedWpm = wpm;
      _myBooks[index].savedMode = mode;
    }
  }
}
