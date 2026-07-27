import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:archive/archive.dart';

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
  BookDatabase._internal();

  final List<BookModel> _myBooks = [];
  bool _assetsLoaded = false;

  List<BookModel> getBooks() => _myBooks;

  /// Uygulama ilk açıldığında `assets/` klasöründeki sizin özel 3 kitabınızı yükler
  Future<void> loadDefaultAssets() async {
    if (_assetsLoaded) return;
    
    // Güvenli dosya yolları ve kullanıcının göreceği orijinal Türkçe isimler
    final assetBooks = [
      {'path': 'assets/kitap1.epub', 'title': 'Üç Cisim Problemi - Tek Cilt İthaki Yayınları'},
      {'path': 'assets/kitap2.epub', 'title': 'Nutuk - Gençler İçin Fotoğraflarla (Mustafa Kemal Atatürk)'},
      {'path': 'assets/kitap3.epub', 'title': 'Nutuk - Yapı Kredi Yayınları'},
    ];

    for (var asset in assetBooks) {
      try {
        final byteData = await rootBundle.load(asset['path']!);
        final bytes = byteData.buffer.asUint8List();
        final content = parseEpubBytes(bytes);
        
        _addSingleBook(asset['title']!, 'EPUB', content);
      } catch (e) {
        // Dosya bulunamazsa veya henüz assets klasörüne yüklenmediyse sistemi çökertmeden sessizce atlar
        debugPrint("Asset yüklenemedi: ${asset['path']} - Hata: $e");
      }
    }
    _assetsLoaded = true;
  }

  /// Çoklu dosya seçiciden gelen RAW BYTES verilerini işler
  void addMultipleBooksFromBytes(List<Map<String, dynamic>> pickedFiles) {
    for (var file in pickedFiles) {
      final title = file['title'] as String;
      final format = file['format'] as String;
      final bytes = file['bytes'] as Uint8List;

      // Kitap zaten eklendiyse tekrar ekleme
      if (_myBooks.any((b) => b.title == title)) continue;

      String content = '';
      if (format == 'EPUB') {
        content = parseEpubBytes(bytes);
      } else if (format == 'TXT') {
        // Saf TXT UTF-8 çevirimi
        content = utf8.decode(bytes, allowMalformed: true);
      } else {
        content = "Bu format (PDF/DOCX) henüz tam desteklenmemektedir. Lütfen EPUB veya TXT kullanın.";
      }

      _addSingleBook(title, format, content);
    }
  }

  void _addSingleBook(String title, String format, String content) {
    if (content.trim().isEmpty) return;

    final id = (_myBooks.length + 1).toString();
    // Her 150 karakteri ortalama bir RSVP sayfası olarak baz alıyoruz
    int pages = (content.length / 150).ceil();
    if (pages < 1) pages = 1;

    _myBooks.add(BookModel(
      id: id,
      title: title,
      format: format,
      content: content,
      totalPages: pages,
    ));
  }

  /// Sıkıştırılmış EPUB arşivini kırar ve içindeki HTML/XHTML metinleri %100 Türkçe desteğiyle ayıklar
  String parseEpubBytes(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      StringBuffer sb = StringBuffer();

      for (final file in archive) {
        if (file.isFile && (file.name.endsWith('.html') || file.name.endsWith('.xhtml') || file.name.endsWith('.htm'))) {
          // UTF-8 olarak veriyi al
          final htmlContent = utf8.decode(file.content as List<int>, allowMalformed: true);
          
          // CSS ve JavaScript kodlarını blok olarak sil
          String text = htmlContent.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false), ' ');
          text = text.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false), ' ');
          
          // Geriye kalan tüm HTML Tag'lerini sil
          text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
          
          // TÜRKÇE KARAKTER DÜZELTME MOTORU (HTML Entities to UTF-8)
          text = text.replaceAll('&ccedil;', 'ç').replaceAll('&Ccedil;', 'Ç')
                     .replaceAll('&ouml;', 'ö').replaceAll('&Ouml;', 'Ö')
                     .replaceAll('&uuml;', 'ü').replaceAll('&Uuml;', 'Ü')
                     .replaceAll('&scedil;', 'ş').replaceAll('&Scedil;', 'Ş')
                     .replaceAll('&gbreve;', 'ğ').replaceAll('&Gbreve;', 'Ğ')
                     .replaceAll('&imath;', 'ı').replaceAll('&Idot;', 'İ')
                     .replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&')
                     .replaceAll('&quot;', '"').replaceAll('&#39;', "'")
                     .replaceAll('&lt;', '<').replaceAll('&gt;', '>');
                     
          // Kalan bilinmeyen, bozuk veya gereksiz HTML simgelerini (& ile başlayıp ; ile biten) boşlukla temizle
          text = text.replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), '');
          
          // Çoklu boşlukları ve satır atlamalarını tek boşluğa düşür
          text = text.replaceAll(RegExp(r'\s+'), ' ');

          sb.write("${text.trim()} ");
        }
      }
      return sb.toString().trim();
    } catch (e) {
      return "E-Kitap Ayrıştırma Hatası: Dosya bozuk, DRM şifreli veya desteklenmeyen bir yapıda olabilir.";
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
