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
  int _readingMode = 1; 
  
  Timer? _timer;
  bool _isPlaying = false;
  
  // Sabit Sayfa ve Satır Matrisi (Kaymayı engeller)
  final int _wordsPerLine = 8; 
  final int _linesPerPage = 6;
  int get _wordsPerPage => _wordsPerLine * _linesPerPage; // Toplam 48 Kelime / Sayfa
  int _totalChunks = 1;

  @override
  void initState() {
    super.initState();
    
    _words = widget.rawText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (_words.isEmpty) _words = ["Metin", "içeriği", "boş", "veya", "okunamadı."];
    
    _totalChunks = (_words.length / _wordsPerPage).ceil();
    if (_totalChunks < 1) _totalChunks = 1;

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

  int _calculateDurationMs() {
    return (60000 / _wpm).round();
  }

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
    
    int duration = _calculateDurationMs();
    if (_readingMode == 4) {
      // Mod 4: Seçili Hıza Göre Sayfanın Toplam Ekranda Kalma Süresi Otonom Hesaplanır
      duration = duration * _wordsPerPage; 
    }

    _timer = Timer.periodic(Duration(milliseconds: duration), (timer) {
      if (!mounted) return;

      setState(() {
        if (_readingMode == 4) {
          // Mod 4: Süre dolduğunda doğrudan sonraki sayfanın ilk kelimesine zıplar
          int nextIndex = _currentWordIndex + _wordsPerPage;
          if (nextIndex < _words.length) {
            _currentWordIndex = (nextIndex ~/ _wordsPerPage) * _wordsPerPage;
          } else {
            _timer?.cancel();
            _isPlaying = false;
          }
        } else {
          // Mod 1, 2, 3: Kelime Kelime ilerler, sayfa sonu gelince kesintisiz diğer sayfaya geçer
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

  void _jumpPages(int pageOffset) {
    setState(() {
      int newWordIndex = _currentWordIndex + (pageOffset * _wordsPerPage);
      if (newWordIndex < 0) newWordIndex = 0;
      if (newWordIndex >= _words.length) newWordIndex = _words.length - 1;
      // Sayfa atlandığında her zaman sayfanın ilk kelimesinden başla
      _currentWordIndex = (newWordIndex ~/ _wordsPerPage) * _wordsPerPage;
      
      if (_isPlaying) _runTimer();
    });
    _saveCurrentProgress();
  }

  /// Gelişmiş Spritz ORP (Hassas Odak Harfi) Motoru
  TextSpan _buildORPSpan(String word, double baseSize, Color regColor, Color orpColor, String fontFam, {bool isLarge = false}) {
    if (word.isEmpty) return const TextSpan();
    
    int len = word.length;
    int focusIndex = 0;
    if (len <= 1) focusIndex = 0;
    else if (len <= 5) focusIndex = 1;
    else if (len <= 9) focusIndex = 2;
    else if (len <= 13) focusIndex = 3;
    else focusIndex = 4;

    if (focusIndex >= len) focusIndex = len > 0 ? len - 1 : 0;

    String p1 = word.substring(0, focusIndex);
    String p2 = word.substring(focusIndex, focusIndex + 1);
    String p3 = word.substring(focusIndex + 1);

    // Kırmızı ORP harfi diğerlerinden %30 daha büyük ve daha kalın çizilir
    double orpSize = isLarge ? baseSize * 1.3 : baseSize * 1.1;
    FontWeight orpWeight = isLarge ? FontWeight.w900 : FontWeight.bold;
    FontWeight regWeight = isLarge ? FontWeight.w600 : FontWeight.w500;

    return TextSpan(
      children: [
        TextSpan(text: p1, style: TextStyle(color: regColor, fontSize: baseSize, fontFamily: fontFam, fontWeight: regWeight)),
        TextSpan(text: p2, style: TextStyle(color: orpColor, fontSize: orpSize, fontWeight: orpWeight, fontFamily: fontFam, letterSpacing: 1.0)),
        TextSpan(text: p3, style: TextStyle(color: regColor, fontSize: baseSize, fontFamily: fontFam, fontWeight: regWeight)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ThemeManager dinleyicisini aktifleştiren yapı:
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, child) {
        final bg = ThemeManager.instance.getReaderBackgroundColor();
        final textCol = ThemeManager.instance.getReaderTextColor();
        final focusCol = ThemeManager.instance.getVibrantOrpColor(); // Daha canlı ORP rengi
        final fSize = ThemeManager.instance.readerFontSize;
        final fFamily = ThemeManager.instance.readerFontFamily;

        int pageStart = _currentPage * _wordsPerPage;
        int pageEnd = pageStart + _wordsPerPage;
        if (pageEnd > _words.length) pageEnd = _words.length;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: Text(widget.activeBook?.title ?? 'Okuma Modu', style: const TextStyle(fontSize: 14)),
            elevation: 0,
            backgroundColor: bg,
            foregroundColor: textCol,
            actions: [
              DropdownButton<int>(
                value: _readingMode,
                dropdownColor: bg,
                icon: Icon(Icons.tune, color: textCol),
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: 1, child: Text('Mod 1: RSVP Odak', style: TextStyle(color: textCol))),
                  DropdownMenuItem(value: 2, child: Text('Mod 2: Sayfa Highlight', style: TextStyle(color: textCol))),
                  DropdownMenuItem(value: 3, child: Text('Mod 3: Satır Odak', style: TextStyle(color: textCol))),
                  DropdownMenuItem(value: 4, child: Text('Mod 4: Sayfa Akışı', style: TextStyle(color: textCol))),
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
              // BİLGİ PANELİ
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
              
              // ANA OKUMA MOTORU
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: textCol.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Builder(
                    builder: (context) {
                      // MOD 1: Yalnızca Tek Kelime (RSVP)
                      if (_readingMode == 1) {
                        return Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: _buildORPSpan(_words[_currentWordIndex], fSize * 2.0, textCol, focusCol, fFamily, isLarge: true),
                          ),
                        );
                      }
                      
                      // MOD 2, 3, 4: Gelişmiş Tam Sayfa / Satır Mimarisi
                      List<Widget> lineWidgets = [];
                      int middleGlobalIndex = pageStart + (_wordsPerPage ~/ 2); // Mod 4 için sayfanın tam ortası

                      for (int line = 0; line < _linesPerPage; line++) {
                        int lineStart = pageStart + (line * _wordsPerLine);
                        int lineEnd = lineStart + _wordsPerLine;
                        if (lineStart >= _words.length) break;
                        if (lineEnd > _words.length) lineEnd = _words.length;

                        List<String> lineWords = _words.sublist(lineStart, lineEnd);
                        List<InlineSpan> spans = [];

                        int currentLineIndex = ((_currentWordIndex - pageStart) ~/ _wordsPerLine);
                        bool isCurrentLine = (line == currentLineIndex);

                        for (int i = 0; i < lineWords.length; i++) {
                          int globalIdx = lineStart + i;
                          bool isCurrentWord = (globalIdx == _currentWordIndex);

                          Color wordColor = textCol;
                          Color bgColor = Colors.transparent;
                          bool showOrp = false;
                          bool largeOrp = false;

                          if (_readingMode == 2) {
                            if (isCurrentWord) {
                              bgColor = focusCol.withOpacity(0.15);
                              showOrp = true;
                              largeOrp = true;
                            }
                          } else if (_readingMode == 3) {
                            if (isCurrentLine) {
                              // Satırın tamamına hafif background
                              bgColor = textCol.withOpacity(0.08); 
                              if (isCurrentWord) {
                                showOrp = true;
                                largeOrp = true;
                                wordColor = textCol;
                              }
                            } else {
                              // Odakta olmayan satırları %40 soluklaştır
                              wordColor = textCol.withOpacity(0.4); 
                            }
                          } else if (_readingMode == 4) {
                            // Sadece sayfanın tam ortasındaki kelimeyi vurgula
                            if (globalIdx == middleGlobalIndex) {
                              showOrp = true;
                              largeOrp = true;
                            }
                          }

                          if (showOrp) {
                            spans.add(TextSpan(
                              style: TextStyle(backgroundColor: bgColor),
                              children: [
                                _buildORPSpan(lineWords[i], fSize, wordColor, focusCol, fFamily, isLarge: largeOrp),
                                TextSpan(text: ' ', style: TextStyle(fontSize: fSize)),
                              ]
                            ));
                          } else {
                            spans.add(TextSpan(
                              text: '${lineWords[i]} ',
                              style: TextStyle(color: wordColor, backgroundColor: bgColor, fontSize: fSize, fontFamily: fFamily)
                            ));
                          }
                        }

                        // HER BİR SATIR İÇİN KUSURSUZ SIĞDIRMA (FITTEDBOX) Zıplamayı Engeller
                        lineWidgets.add(
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown, // Satır taşarsa küçültür, küçükse normal fontta bırakır
                                alignment: Alignment.center,
                                child: RichText(
                                  text: TextSpan(children: spans),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: lineWidgets,
                      );
                    },
                  ),
                ),
              ),
              
              // ALT BÖLÜM: Kontrol Paneli (İleri - Geri Atlama)
              Container(
                padding: const EdgeInsets.all(16),
                color: textCol.withOpacity(0.03),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed, color: textCol, size: 18),
                        Expanded(
                          child: Slider(
                            value: _wpm.toDouble(),
                            min: 100, max: 1000, divisions: 18,
                            label: '$_wpm WPM',
                            activeColor: focusCol,
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
                          backgroundColor: focusCol, // Play butonu ORP rengiyle senkron
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
        );
      },
    );
  }
}
