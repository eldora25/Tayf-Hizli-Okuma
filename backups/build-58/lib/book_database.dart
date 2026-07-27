import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
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

  /// Uygulama ilk açıldığında assets klasöründeki özel kitapları yükler
  Future<void> loadDefaultAssets() async {
    if (_assetsLoaded) return;
    
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
        debugPrint("Asset yüklenemedi: ${asset['path']} - Hata: $e");
      }
    }
    _assetsLoaded = true;
  }

  /// UI katmanının asenkron süreci bekleyebilmesi için metot Future<void> yapısına geçirildi
  Future<void> addMultipleBooks(List<dynamic> pickedFiles) async {
    for (var item in pickedFiles) {
      if (item is! Map) continue;
      
      final file = item.cast<String, dynamic>();
      final title = file['title'] as String;
      final format = file['format'] as String;
      final bytes = file['bytes'] as Uint8List;

      // Kitap zaten eklendiyse tekrar ekleme adımlarına geçme
      if (_myBooks.any((b) => b.title == title)) continue;

      String content = '';
      if (format == 'EPUB') {
        content = parseEpubBytes(bytes);
      } else if (format == 'TXT') {
        content = utf8.decode(bytes, allowMalformed: true);
      } else {
        content = "Bu format henüz desteklenmemektedir. Lütfen EPUB veya TXT kullanın.";
      }

      _addSingleBook(title, format, content);
    }
  }

  void _addSingleBook(String title, String format, String content) {
    if (content.trim().isEmpty) return;

    final id = (_myBooks.length + 1).toString();
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

  /// S Sıkıştırılmış EPUB arşivini kırar ve içindeki HTML/XHTML metinleri Türkçe desteğiyle ayıklar
  String parseEpubBytes(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      StringBuffer sb = StringBuffer();

      for (final file in archive) {
        if (file.isFile && (file.name.endsWith('.html') || file.name.endsWith('.xhtml') || file.name.endsWith('.htm'))) {
          final htmlContent = utf8.decode(file.content as List<int>, allowMalformed: true);
          
          String text = htmlContent.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false), ' ');
          text = text.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false), ' ');
          
          text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
          
          text = text.replaceAll('&ccedil;', 'ç').replaceAll('&Ccedil;', 'Ç')
                     .replaceAll('&ouml;', 'ö').replaceAll('&Ouml;', 'Ö')
                     .replaceAll('&uuml;', 'ü').replaceAll('&Uuml;', 'Ü')
                     .replaceAll('&scedil;', 'ş').replaceAll('&Scedil;', 'Ş')
                     .replaceAll('&gbreve;', 'ğ').replaceAll('&Gbreve;', 'Ğ')
                     .replaceAll('&imath;', 'ı').replaceAll('&Idot;', 'İ')
                     .replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&')
                     .replaceAll('&quot;', '"').replaceAll('&#39;', "'")
                     .replaceAll('&lt;', '<').replaceAll('&gt;', '>');
                     
          text = text.replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), '');
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
