import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'format': format, 'content': content,
    'totalPages': totalPages, 'lastPage': lastPage, 'savedWpm': savedWpm, 'savedMode': savedMode,
  };

  factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(
    id: json['id'], title: json['title'], format: json['format'], content: json['content'],
    totalPages: json['totalPages'], lastPage: json['lastPage'], savedWpm: json['savedWpm'], savedMode: json['savedMode'],
  );
}

class BookDatabase {
  static final BookDatabase instance = BookDatabase._internal();
  BookDatabase._internal();

  List<BookModel> _myBooks = [];
  bool _assetsLoaded = false;

  List<BookModel> getBooks() => _myBooks;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? booksJson = prefs.getString('saved_books');
    if (booksJson != null) {
      final List<dynamic> decoded = jsonDecode(booksJson);
      _myBooks = decoded.map((e) => BookModel.fromJson(e)).toList();
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_myBooks.map((e) => e.toJson()).toList());
    await prefs.setString('saved_books', encoded);
  }

  Future<void> loadDefaultAssets() async {
    if (_assetsLoaded) return;
    final assetBooks = [
      {'path': 'assets/kitap1.epub', 'title': 'Üç Cisim Problemi - Tek Cilt İthaki Yayınları'},
      {'path': 'assets/kitap2.epub', 'title': 'Nutuk - Gençler İçin Fotoğraflarla (Mustafa Kemal Atatürk)'},
      {'path': 'assets/kitap3.epub', 'title': 'Nutuk - Yapı Kredi Yayınları'},
    ];

    for (var asset in assetBooks) {
      if (!_myBooks.any((b) => b.title == asset['title'])) {
        try {
          final byteData = await rootBundle.load(asset['path']!);
          final bytes = byteData.buffer.asUint8List();
          final content = parseEpubBytes(bytes);
          _addSingleBook(asset['title']!, 'EPUB', content);
        } catch (e) {
          debugPrint("Asset yüklenemedi: $e");
        }
      }
    }
    _assetsLoaded = true;
    await _saveToPrefs();
  }

  Future<void> addMultipleBooks(List<dynamic> pickedFiles) async {
    for (var item in pickedFiles) {
      if (item is! Map) continue;
      final file = item.cast<String, dynamic>();
      final title = file['title'] as String;
      
      if (_myBooks.any((b) => b.title == title)) continue;

      String content = '';
      if (file['format'] == 'EPUB') {
        content = parseEpubBytes(file['bytes'] as Uint8List);
      } else if (file['format'] == 'TXT') {
        content = utf8.decode(file['bytes'] as Uint8List, allowMalformed: true);
      } else if (file['format'] == 'DOCX') {
        content = parseDocxBytes(file['bytes'] as Uint8List);
      }
      _addSingleBook(title, file['format'] as String, content);
    }
    await _saveToPrefs();
  }

  void _addSingleBook(String title, String format, String content) {
    if (content.trim().isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    int pages = (content.length / 150).ceil();
    _myBooks.add(BookModel(id: id, title: title, format: format, content: content, totalPages: pages < 1 ? 1 : pages));
  }

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
          text = text.replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), '').replaceAll(RegExp(r'\s+'), ' ');
          sb.write("${text.trim()} ");
        }
      }
      return sb.toString().trim();
    } catch (e) {
      return "E-Kitap Ayrıştırma Hatası.";
    }
  }

  /// DOCX (Zip Arşivi) içerisindeki word/document.xml verisini ayıklar ve düz metne çevirir
  String parseDocxBytes(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final file = archive.findFile('word/document.xml');
      
      if (file != null) {
        final xmlContent = utf8.decode(file.content as List<int>, allowMalformed: true);
        
        // Paragraflar arasına boşluk koyarak kelimelerin yapışmasını engeller
        String text = xmlContent.replaceAll(RegExp(r'<w:p[^>]*>'), ' <w:p> ');
        
        // Kalan tüm XML etiketlerini siler
        text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
        text = text.replaceAll(RegExp(r'\s+'), ' ');
        return text.trim();
      }
      return "DOCX metin içeriği bulunamadı.";
    } catch (e) {
      return "DOCX Ayrıştırma Hatası: Belge formatı desteklenmiyor olabilir.";
    }
  }

  Future<void> saveProgress(String id, int page, int wpm, int mode) async {
    final index = _myBooks.indexWhere((b) => b.id == id);
    if (index != -1) {
      _myBooks[index].lastPage = page;
      _myBooks[index].savedWpm = wpm;
      _myBooks[index].savedMode = mode;
      await _saveToPrefs();
    }
  }
}
