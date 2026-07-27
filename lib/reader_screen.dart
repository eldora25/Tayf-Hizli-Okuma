import 'dart:async';
import 'package:flutter/material.dart';
import 'book_database.dart';
import 'theme_manager.dart';

class ReaderScreen extends StatefulWidget {
  final String rawText;
  final BookModel? activeBook;

  const ReaderScreen({Key? key, required this.rawText, this.activeBook}) : super(key: key);

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  List<String> _words = [];
  int _currentWordIndex = 0;
  int _wpm = 300;
  int _readingMode = 1; // 1: RSVP, 2: Tam Sayfa Highlight, 3: Satır Odaklama, 4: Sayfa Akışı
  
  Timer? _timer;
  bool _isPlaying = false;
  
  // Sayfa hesaplamaları için
  final int _wordsPerPage = 60; 
  int _totalChunks = 1;

  @override
  void initState() {
    super.initState();
    
    // Metni kelimelere bölme
    _words = widget.rawText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (_words.isEmpty) _words = ["Metin", "içeriği", "boş", "veya", "okunamadı."];
    
    _totalChunks = (_words.length / _wordsPerPage).ceil();
    if (_totalChunks < 1) _totalChunks = 1;

    // Eğer bir kitap açıldıysa, kalınan yerleri ve ayarları geri yükle
    if (widget.activeBook != null) {
      _wpm = widget.activeBook!.savedWpm;
      _readingMode = widget.activeBook!.savedMode;
      int savedIndex = widget.activeBook!.lastPage * _wordsPerPage;
      if (savedIndex < _words.length) {
        _currentWordIndex = savedIndex;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _currentPage => (_currentWordIndex / _wordsPerPage).floor();

  /// İlerlemeyi yerel modele kaydeder
  void _saveCurrentProgress() {
    if (widget.activeBook != null) {
      BookDatabase.instance.saveProgress(
        widget.activeBook!.id,
        _currentPage,
        _wpm,
        _readingMode,
      );
    }
  }

  /// Hızı milisaniyeye çevirir
  int _calculateDurationMs() {
    return (60000 / _wpm).round();
  }

  /// Egzersiz Zamanlayıcı Başlatıcı/Durdurucu
  void _togglePlay() {
    if (_isPlaying) {
      _timer?.cancel();
      setState(() => _isPlaying = false);
      _saveCurrentProgress();
    } else {
      setState(() => _isPlaying = true);
      _runTimer();
    }
  }

  void _runTimer() {
    _timer?.cancel();
    
    // Mod 4 (Sayfa Akışı) ise sayfa başına bekleme süresi hesaplanır
    int duration = _calculateDurationMs();
    if (_readingMode == 4) {
      duration = duration * _wordsPerPage; // Sayfa değiştirme periyodu
    }

    _timer = Timer.periodic(Duration(milliseconds: duration), (timer) {
      if (!mounted) return;

      setState(() {
        if (_readingMode == 4) {
          // Sayfa Akış Modu: Doğrudan sonraki sayfaya atla
          int nextIndex = _currentWordIndex + _wordsPerPage;
          if (nextIndex < _words.length) {
            _currentWordIndex = nextIndex;
          } else {
            _timer?.cancel();
            _isPlaying = false;
          }
        } else {
          // Kelime bazlı modlar (1, 2, 3): Kelime kelime ilerle
          if (_currentWordIndex < _words.length - 1) {
            _currentWordIndex++;
          } else {
            _timer?.cancel();
            _isPlaying = false;
          }
        }
      });
      _saveCurrentProgress();
    });
  }

  /// Sayfa Atlama Fonksiyonu (Dinamik ve Kesintisiz)
  void _jumpPages(int pageOffset) {
    setState(() {
      int newWordIndex = _currentWordIndex + (pageOffset * _wordsPerPage);
      if (newWordIndex < 0) newWordIndex = 0;
      if (newWordIndex >= _words.length) newWordIndex = _words.length - 1;
      _currentWordIndex = newWordIndex;
      
      // Eğer oynatılıyorsa zamanlayıcıyı yeni endekse göre tazele
      if (_isPlaying) _runTimer();
    });
    _saveCurrentProgress();
  }

  /// Spritz Tarzı Optimal Odak Noktası (ORP) Hesaplama Motoru
  Widget _buildSpritzWord(String word, double fontSize, Color focusColor, Color regularColor, String fontFamily) {
    if (word.isEmpty) return const SizedBox();
    
    int len = word.length;
    int focusIndex = 0;
    if (len <= 1) focusIndex = 0;
    else if (len <= 5) focusIndex = 1;
    else if (len <= 9) focusIndex = 2;
    else if (len <= 13) focusIndex = 3;
    else focusIndex = 4;

    String part1 = word.substring(0, focusIndex);
    String part2 = word.substring(focusIndex, focusIndex + 1);
    String part3 = word.substring(focusIndex + 1);

    final style = TextStyle(fontSize: fontSize, fontFamily: fontFamily, fontWeight: FontWeight.bold);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(part1, style: style.copyWith(color: regularColor)),
        Text(part2, style: style.copyWith(color: focusColor)),
        Text(part3, style: style.copyWith(color: regularColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ThemeManager.instance.themeMode;
    final bg = ThemeManager.instance.getReaderBackgroundColor();
    final textCol = ThemeManager.instance.getReaderTextColor();
    final focusCol = ThemeManager.instance.readerTextColor;
    final fSize = ThemeManager.instance.readerFontSize;
    final fFamily = ThemeManager.instance.readerFontFamily;

    // Mevcut sayfadaki kelimelerin aralığını hesapla
    int pageStart = _currentPage * _wordsPerPage;
    int pageEnd = pageStart + _wordsPerPage;
    if (pageEnd > _words.length) pageEnd = _words.length;
    List<String> pageWords = _words.sublist(pageStart, pageEnd);

    return Theme(
      data: ThemeManager.instance.getThemeData(themeMode == ThemeMode.dark),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text(widget.activeBook?.title ?? 'Hızlı Okuma', style: const TextStyle(fontSize: 14)),
          elevation: 0,
          backgroundColor: bg,
          foregroundColor: textCol,
          actions: [
            DropdownButton<int>(
              value: _readingMode,
              dropdownColor: bg,
              icon: Icon(Icons.tune, color: textCol),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Mod 1: RSVP Odak')),
                DropdownMenuItem(value: 2, child: Text('Mod 2: Sayfa Highlight')),
                DropdownMenuItem(value: 3, child: Text('Mod 3: Satır Odak')),
                DropdownMenuItem(value: 4, child: Text('Mod 4: Sayfa Akışı')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _readingMode = val;
                    if (_isPlaying) _runTimer();
                  });
                  _saveCurrentProgress();
                }
              },
            )
          ],
        ),
        body: Column(
          children: [
            // ÜST BÖLÜM: İlerleme Bilgisi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sayfa: ${_currentPage + 1} / $_totalChunks', style: TextStyle(color: textCol, fontSize: 12)),
                  Text('Kelime: ${_currentWordIndex + 1} / ${_words.length}', style: TextStyle(color: textCol, fontSize: 12)),
                ],
              ),
            ),
            
            // ORTA BÖLÜM: Modlara Göre Çeşitlenen Okuma Alanı
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: textCol.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Builder(
                  builder: (context) {
                    if (_readingMode == 1) {
                      // MOD 1: Klasik RSVP Odaklama Modu
                      return _buildSpritzWord(_words[_currentWordIndex], fSize * 1.5, focusCol, textCol, fFamily);
                    }
                    
                    // MOD 2, 3 ve 4: Tam Sayfa Gösterimli Metin Akış Yapıları
                    return Wrap(
                      spacing: 6,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: List.generate(pageWords.length, (index) {
                        int globalIdx = pageStart + index;
                        bool isCurrentWord = globalIdx == _currentWordIndex;

                        if (_readingMode == 2 && isCurrentWord) {
                          // MOD 2: Kelime Kelime Highlight ve ORP Odaklama
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: focusCol.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: _buildSpritzWord(_words[globalIdx], fSize, focusCol, textCol, fFamily),
                          );
                        } else if (_readingMode == 3 && (index % 6 == 3) && (_currentWordIndex >= globalIdx - 3 && _currentWordIndex <= globalIdx + 2)) {
                          // MOD 3: Satır Merkez Odaklama ve Satır Highlight Yapısı
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                            child: isCurrentWord 
                              ? _buildSpritzWord(_words[globalIdx], fSize, focusCol, textCol, fFamily)
                              : Text(_words[globalIdx], style: TextStyle(fontSize: fSize, fontFamily: fFamily, color: textCol, fontWeight: FontWeight.bold)),
                          );
                        } else if (_readingMode == 4) {
                          // MOD 4: Kesintisiz Sayfa Akış Modu
                          return Text(
                            _words[globalIdx],
                            style: TextStyle(
                              fontSize: fSize,
                              fontFamily: fFamily,
                              color: textCol,
                            ),
                          );
                        }

                        // Standart Durumda Olan Kelimeler
                        return Text(
                          _words[globalIdx],
                          style: TextStyle(
                            fontSize: fSize,
                            fontFamily: fFamily,
                            color: isCurrentWord ? focusCol : textCol.withOpacity(0.5),
                            fontWeight: isCurrentWord ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
            
            // ALT BÖLÜM: Kontrol ve Sayfa Atlama İstasyonu
            Container(
              padding: const EdgeInsets.all(16),
              color: textCol.withOpacity(0.03),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hız Ayar Çubuğu (WPM)
                  Row(
                    children: [
                      Icon(Icons.speed, color: textCol, size: 18),
                      Expanded(
                        child: Slider(
                          value: _wpm.toDouble(),
                          min: 100, max: 1000, divisions: 18,
                          label: '$_wpm WPM',
                          onChanged: (val) {
                            setState(() {
                              _wpm = val.round();
                              if (_isPlaying) _runTimer();
                            });
                            _saveCurrentProgress();
                          },
                        ),
                      ),
                      Text('$_wpm WPM', style: TextStyle(color: textCol, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Sayfa Atlatıcılar ve Oynat/Durdur Buton Kombinasyonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.fast_rewind),
                        tooltip: '5 Sayfa Geri',
                        color: textCol,
                        onPressed: () => _jumpPages(-5),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        tooltip: '1 Sayfa Geri',
                        color: textCol,
                        onPressed: () => _jumpPages(-1),
                      ),
                      FloatingActionButton(
                        onPressed: _togglePlay,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        tooltip: '1 Sayfa İleri',
                        color: textCol,
                        onPressed: () => _jumpPages(1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fast_forward),
                        tooltip: '5 Sayfa İleri',
                        color: textCol,
                        onPressed: () => _jumpPages(5),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
