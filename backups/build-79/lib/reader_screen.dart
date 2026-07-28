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
  
  // Metni ekran düzeninde kaymadan tutan matris yapısı
  final int _wordsPerLine = 8; 
  final int _linesPerPage = 6;
  int get _wordsPerPage => _wordsPerLine * _linesPerPage;
  int _totalChunks = 1;

  @override
  void initState() {
    super.initState();
    
    _words = widget.rawText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (_words.isEmpty) _words = ["Metin", "içeriği", "boş."];
    
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
      BookDatabase.instance.saveProgress(widget.activeBook!.id, _currentPage, _wpm, _readingMode);
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
    
    // Mod 3: Hıza bağlı olarak SATIR atlama süresi
    if (_readingMode == 3) {
      duration = duration * _wordsPerLine; 
    } 
    // Mod 4: Hıza bağlı olarak SAYFA atlama süresi
    else if (_readingMode == 4) {
      duration = duration * _wordsPerPage; 
    }

    _timer = Timer.periodic(Duration(milliseconds: duration), (timer) {
      if (!mounted) return;

      setState(() {
        if (_readingMode == 3) {
          int nextIndex = _currentWordIndex + _wordsPerLine;
          if (nextIndex < _words.length) {
            _currentWordIndex = (nextIndex ~/ _wordsPerLine) * _wordsPerLine;
          } else {
            _timer?.cancel();
            _isPlaying = false;
          }
        } else if (_readingMode == 4) {
          int nextIndex = _currentWordIndex + _wordsPerPage;
          if (nextIndex < _words.length) {
            _currentWordIndex = (nextIndex ~/ _wordsPerPage) * _wordsPerPage;
          } else {
            _timer?.cancel();
            _isPlaying = false;
          }
        } else {
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
      _currentWordIndex = (newWordIndex ~/ _wordsPerPage) * _wordsPerPage;
      
      if (_isPlaying) _runTimer();
    });
    _saveCurrentProgress();
  }

  TextSpan _buildORPSpan(String word, double baseSize, Color regColor, Color orpColor, String fontFam, {bool isLarge = false}) {
    if (word.isEmpty) return const TextSpan();
    
    int len = word.length;
    int focusIndex = len <= 1 ? 0 : (len <= 5 ? 1 : (len <= 9 ? 2 : (len <= 13 ? 3 : 4)));
    if (focusIndex >= len) focusIndex = len > 0 ? len - 1 : 0;

    String p1 = word.substring(0, focusIndex);
    String p2 = word.substring(focusIndex, focusIndex + 1);
    String p3 = word.substring(focusIndex + 1);

    double orpSize = isLarge ? baseSize * 1.5 : baseSize * 1.1;
    FontWeight orpWeight = isLarge ? FontWeight.w900 : FontWeight.bold;
    FontWeight regWeight = isLarge ? FontWeight.w600 : FontWeight.w500;

    return TextSpan(
      children: [
        TextSpan(text: p1, style: TextStyle(color: regColor, fontSize: baseSize, fontFamily: fontFam, fontWeight: regWeight)),
        TextSpan(text: p2, style: TextStyle(color: orpColor, fontSize: orpSize, fontWeight: orpWeight, fontFamily: fontFam)),
        TextSpan(text: p3, style: TextStyle(color: regColor, fontSize: baseSize, fontFamily: fontFam, fontWeight: regWeight)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, child) {
        final bg = ThemeManager.instance.getReaderBackgroundColor();
        final textCol = ThemeManager.instance.getReaderTextColor();
        final focusCol = ThemeManager.instance.getVibrantOrpColor(); 
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
              
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: textCol.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Builder(
                    builder: (context) {
                      if (_readingMode == 1) {
                        return Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: _buildORPSpan(_words[_currentWordIndex], fSize * 2.0, textCol, focusCol, fFamily, isLarge: true),
                          ),
                        );
                      }
                      
                      List<Widget> lineWidgets = [];
                      
                      // Mod 3 ve 4 Algoritması
                      int targetLineForMode4 = _linesPerPage ~/ 2; 
                      int targetWordForMode4 = _wordsPerLine ~/ 2;

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
                          bool showOrp = false;
                          bool largeOrp = false;

                          if (_readingMode == 2 && isCurrentWord) {
                            showOrp = true; largeOrp = true;
                          } else if (_readingMode == 3) {
                            if (isCurrentLine) {
                              wordColor = textCol;
                              // Satırın tam ortasındaki kelimeyi odakla
                              if (i == _wordsPerLine ~/ 2) {
                                showOrp = true; largeOrp = true;
                              }
                            } else {
                              wordColor = textCol.withOpacity(0.3); 
                            }
                          } else if (_readingMode == 4) {
                            // Sayfanın ortasındaki satırın ortasındaki kelimeyi odakla
                            if (line == targetLineForMode4 && i == targetWordForMode4) {
                              showOrp = true; largeOrp = true;
                            }
                          }

                          if (showOrp) {
                            spans.add(_buildORPSpan(lineWords[i], fSize, wordColor, focusCol, fFamily, isLarge: largeOrp));
                            spans.add(TextSpan(text: ' ', style: TextStyle(fontSize: fSize)));
                          } else {
                            spans.add(TextSpan(text: '${lineWords[i]} ', style: TextStyle(color: wordColor, fontSize: fSize, fontFamily: fFamily)));
                          }
                        }

                        // Metnin taşmasını ve kaymasını kesinlikle önleyen FittedBox/RichText Kombinasyonu
                        lineWidgets.add(
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              color: (_readingMode == 3 && isCurrentLine) ? textCol.withOpacity(0.08) : Colors.transparent,
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: RichText(text: TextSpan(children: spans)),
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
                        IconButton(icon: const Icon(Icons.fast_rewind), color: textCol, onPressed: () => _jumpPages(-5)),
                        IconButton(icon: const Icon(Icons.chevron_left), color: textCol, onPressed: () => _jumpPages(-1)),
                        FloatingActionButton(
                          onPressed: _togglePlay,
                          backgroundColor: focusCol,
                          foregroundColor: Colors.white,
                          child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        ),
                        IconButton(icon: const Icon(Icons.chevron_right), color: textCol, onPressed: () => _jumpPages(1)),
                        IconButton(icon: const Icon(Icons.fast_forward), color: textCol, onPressed: () => _jumpPages(5)),
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
