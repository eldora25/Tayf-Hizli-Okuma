import 'dart:convert';

class BookModel {
  final String id;
  final String title;
  final String format;
  final String content;
  final int totalPages;
  int lastPage;
  int savedWpm;

  BookModel({
    required this.id,
    required this.title,
    required this.format,
    required this.content,
    required this.totalPages,
    this.lastPage = 0,
    this.savedWpm = 300,
  });
}

class BookDatabase {
  static final BookDatabase instance = BookDatabase._internal();
  BookDatabase._internal() {
    // Hazır simüle veritabanı başlangıcı
    _myBooks.add(BookModel(
      id: "1",
      title: "Hızlı Okuma Sanatı.epub",
      format: "EPUB",
      content: "Hızlı okuma stratejileri sayfa bir içeriğidir. Algılama sınırlarınızı zorlayın. Sayfa iki içeriği: Göz kaslarınızı yatay genişletin. Sayfa üç içeriği: Blok odaklama yapın.",
      totalPages: 3,
      lastPage: 0,
    ));
  }

  final List<BookModel> _myBooks = [];

  List<BookModel> getBooks() => _myBooks;

  void addBook(String title, String format, String content) {
    final id = (激myBooks.length + 1).toString();
    // Metin uzunluğuna göre sayfa sayısı simülasyonu
    int pages = (content.length / 80).ceil();
    if (pages < 1) pages = 1;
    
    _myBooks.add(BookModel(
      id: id,
      title: title,
      format: format.toUpperCase(),
      content: content,
      totalPages: pages,
    ));
  }

  void saveProgress(String id, int page, int wpm) {
    final index = _myBooks.indexWhere((b) => b.id == id);
    if (index != -1) {
      _myBooks[index].lastPage = page;
      _myBooks[index].savedWpm = wpm;
    }
  }
}
