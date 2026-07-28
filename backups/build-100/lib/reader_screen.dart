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
  
  int _wpl = 6; 
  int _lpp = 8; 
  int get _wpp => _wpl * _lpp; 
  int _totalChunks = 1;

  @override
  void initState() {
    super.initState();
    _words = widget.rawText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (_words.isEmpty) _words = ["Metin", "içeriği", "boş."];
    
    if (widget.activeBook != null) {
      _wpm = widget.activeBook!.savedWpm;
      _readingMode = widget.activeBook!.savedMode;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _currentPage => (_wpp > 0) ? (_currentWordIndex ~/ _wpp) : 0;

  void _saveCurrentProgress() {
    if (widget.activeBook != null && _wpp > 0) {
      BookDatabase.instance.saveProgress(widget.activeBook!.id, _currentPage, _wpm, _readingMode);
    }
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
    
    int durationMs = (60000 / _wpm).round();
    
    if (_readingMode == 3) {
      durationMs *= _wpl; 
    } 
    else if (_readingMode == 4) {
      durationMs *= _wpp; 
    }

    _timer = Timer.periodic(Duration(milliseconds: durationMs), (timer) {
      if (!mounted || !_isPlaying) {
        timer.cancel(); // Arkaplan timer sızıntısını engelleyen kesin çözüm
        return;
      }

      setState(() {
        if (_readingMode == 3) {
          _currentWordIndex += _wpl;
          _currentWordIndex = (_currentWordIndex ~/ _wpl) * _wpl; 
        } else if (_readingMode == 4) {
          _currentWordIndex += _wpp;
          _currentWordIndex = (_currentWordIndex ~/ _wpp) * _wpp; 
        } else {
          _currentWordIndex++; 
        }

        if (_currentWordIndex >= _words.length) {
          _currentWordIndex = _words.length - 1;
          timer.cancel();
          _isPlaying = false;
        }
      });
      _saveCurrentProgress();
    });
  }

  void _jumpPages(int pageOffset) {
    setState(() {
      int newWordIndex = _currentWordIndex + (pageOffset * _wpp);
      if (newWordIndex < 0) newWordIndex = 0;
      if (newWordIndex >= _words.length) newWordIndex = _words.length - 1;
      _currentWordIndex = (newWordIndex ~/ _wpp) * _wpp;
      
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

    double orpSize = isLarge ? baseSize * 1.3 : baseSize * 1.1;
    FontWeight orpWeight = isLarge ? FontWeight.w900 : FontWeight.bold;
    FontWeight regWeight = isLarge ? FontWeight.w600 : FontWeight.w500;

    return TextSpan(
      children: [
        TextSpan(text: p1, style: TextStyle(color: regColor, fontSize: baseSize, fontFamily: fontFam, fontWeight: regWeight)),
        TextSpan(text: p2, style: TextStyle(color: orpColor, fontSize: orpSize, fontWeight: orpWeight, fontFamily: fontFam, letterSpacing: 0.5)),
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

        final screenWidth = MediaQuery.of(context).size.width - 32;
        final screenHeight = MediaQuery.of(context).size.height - 250;
        
        _wpl = (screenWidth / (fSize * 3.5)).floor().clamp(3, 15);
        _lpp = (screenHeight / (fSize * 1.8)).floor().clamp(3, 20);
        
        _totalChunks = (_words.length / _wpp).ceil();

        if (widget.activeBook != null && _currentWordIndex == 0 && widget.activeBook!.lastPage > 0) {
          _currentWordIndex = widget.activeBook!.lastPage * _wpp;
          if (_currentWordIndex >= _words.length) _currentWordIndex = 0;
        }

        int pageStart = (_currentWordIndex ~/ _wpp) * _wpp;
        int currentLineIndex = ((_currentWordIndex - pageStart) ~/ _wpl);

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
                      _currentWordIndex = pageStart; 
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
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      int middleLineForMode4 = _lpp ~/ 2; 
                      int middleWordForMode4 = _wpl ~/ 2;

                      for (int line = 0; line < _lpp; line++) {
                        int lineStart = pageStart + (line * _wpl);
                        if (lineStart >= _words.length) break;
                        
                        int lineEnd = lineStart + _wpl;
                        if (lineEnd > _words.length) lineEnd = _words.length;

                        List<String> lineWords = _words.sublist(lineStart, lineEnd);
                        List<InlineSpan> spans = [];

                        bool isCurrentLine = (line == currentLineIndex);
                        Color lineBgColor = Colors.transparent;

                        if (_readingMode == 3 && isCurrentLine) {
                          lineBgColor = textCol.withOpacity(0.08); 
                        }

                        for (int i = 0; i < lineWords.length; i++) {
                          int globalIdx = lineStart + i;
                          bool isCurrentWord = (globalIdx == _currentWordIndex);
                          
                          Color wordColor = textCol;
                          Color wordBgColor = Colors.transparent;
                          bool showOrp = false;

                          if (_readingMode == 2 && isCurrentWord) {
                            wordBgColor = focusCol.withOpacity(0.15);
                            showOrp = true;
                          } else if (_readingMode == 3) {
                            if (isCurrentLine) {
                              wordColor = textCol;
                              if (i == _wpl ~/ 2) showOrp = true; 
                            } else {
                              wordColor = textCol.withOpacity(0.3); 
                            }
                          } else if (_readingMode == 4) {
                            if (line == middleLineForMode4 && i == middleWordForMode4) {
                              showOrp = true;
                            }
                          }

                          if (showOrp) {
                            spans.add(TextSpan(style: TextStyle(backgroundColor: wordBgColor), children: [
                              _buildORPSpan(lineWords[i], fSize, wordColor, focusCol, fFamily, isLarge: true),
                              TextSpan(text: ' ', style: TextStyle(fontSize: fSize)),
                            ]));
                          } else {
                            spans.add(TextSpan(text: '${lineWords[i]} ', style: TextStyle(color: wordColor, backgroundColor: wordBgColor, fontSize: fSize, fontFamily: fFamily)));
                          }
                        }

                        lineWidgets.add(
                          Container(
                            width: double.infinity,
                            color: lineBgColor,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: RichText(
                              textAlign: TextAlign.center, 
                              text: TextSpan(children: spans),
                            ),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: lineWidgets,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Android sanal buton koruması
              SafeArea(
                bottom: true,
                child: Container(
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
              ),
            ],
          ),
        );
      },
    );
  }
}
