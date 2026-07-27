import 'dart:async';
import 'package:flutter/material.dart';
import 'speed_reader_engine.dart';
import 'book_database.dart';
import 'theme_manager.dart';

class ReaderScreen extends StatefulWidget {
  final String rawText;
  final BookModel? activeBook;
  const ReaderScreen({super.key, required this.rawText, this.activeBook});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late SpeedReaderEngine _engine;
  int _currentWordIndex = 0;
  int _wpm = 300;
  bool _isPlaying = false;
  Timer? _timer;
  
  // 1: RSVP, 2: Tüm Sayfa Kelime Akışı, 3: Satır Merkez Odak, 4: Sayfa Yoğunluk Akışı
  int _readingMode = 1; 
  int _currentPage = 0;
  List<String> _pageSegments = [];

  final String _buildNumber = "BUILD_NUMBER_PLACEHOLDER";

  @override
  void initState() {
    super.initState();
    _wpm = widget.activeBook?.savedWpm ?? 300;
    _currentPage = widget.activeBook?.lastPage ?? 0;
    _setupContent();
  }

  void _setupContent() {
    if (widget.activeBook != null) {
      _pageSegments = widget.rawText.split('.');
      if (_currentPage >= _pageSegments.length) _currentPage = 0;
      _engine = SpeedReaderEngine(text: _pageSegments[_currentPage]);
    } else {
      _engine = SpeedReaderEngine(text: widget.rawText);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    int intervalMs = ((60 / _wpm) * 1000).round();

    if (_readingMode == 4) {
      int wordCount = _engine.words.length;
      int pageDurationMs = ((wordCount / _wpm) * 60 * 1000).round();
      _timer = Timer(Duration(milliseconds: pageDurationMs), () {
        _changePage(1);
        if (_isPlaying) _startTimer();
      });
    } else {
      _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
        if (_currentWordIndex < _engine.words.length - 1) {
          setState(() => _currentWordIndex++);
        } else {
          if (widget.activeBook != null && _currentPage < _pageSegments.length - 1) {
            _changePage(1);
          } else {
            _pauseTimer();
          }
        }
      });
    }
    setState(() => _isPlaying = true);
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isPlaying = false);
    _saveCurrentProgress();
  }

  void _saveCurrentProgress() {
    if (widget.activeBook != null) {
      BookDatabase.instance.saveProgress(widget.activeBook!.id, _currentPage, _wpm);
    }
  }

  void _changePage(int direction) {
    if (widget.activeBook == null) return;
    _pauseTimer();
    setState(() {
      _currentPage = (_currentPage + direction).clamp(0, _pageSegments.length - 1);
      _currentWordIndex = 0;
      _setupContent();
    });
    _saveCurrentProgress();
  }

  Widget _buildSpritzWord(String word, {bool highlightAll = false, Color? customColor}) {
    if (word.isEmpty) return const SizedBox.shrink();
    int focusIndex = SpeedReaderEngine.getOptimalFocusIndex(word);
    if (focusIndex >= word.length) focusIndex = 0;

    String left = word.substring(0, focusIndex);
    String center = word.substring(focusIndex, focusIndex + 1);
    String right = word.substring(focusIndex + 1);

    final style = TextStyle(
      fontSize: ThemeManager.instance.readerFontSize,
      fontFamily: ThemeManager.instance.readerFontFamily,
      fontWeight: FontWeight.bold,
      backgroundColor: highlightAll ? Colors.yellow.withOpacity(0.4) : null,
    );

    return RichText(
      text: TextSpan(
        style: style.copyWith(color: customColor ?? Theme.of(context).textTheme.bodyLarge?.color),
        children: [
          TextSpan(text: left),
          TextSpan(text: center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
          TextSpan(text: right),
        ],
      ),
    );
  }

  Widget _buildReaderBody() {
    if (_readingMode == 1) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.arrow_drop_down, color: Colors.red, size: 30),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: _buildSpritzWord(_engine.words[_currentWordIndex]),
            ),
            const Icon(Icons.arrow_drop_up, color: Colors.red, size: 30),
          ],
        ),
      );
    } else if (_readingMode == 2) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(_engine.words.length, (index) {
          bool isCurrent = index == _currentWordIndex;
          return _buildSpritzWord(_engine.words[index], highlightAll: isCurrent);
        }),
      );
    } else if (_readingMode == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Gözünüzü satır merkezine odaklayın:", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.withOpacity(0.1),
            child: Center(child: _buildSpritzWord(_engine.words[_currentWordIndex], highlightAll: true)),
          )
        ],
      );
    } else {
      return Text(
        _pageSegments.isEmpty ? widget.rawText : _pageSegments[_currentPage],
        style: TextStyle(
          fontSize: ThemeManager.instance.readerFontSize,
          fontFamily: ThemeManager.instance.readerFontFamily,
          color: ThemeManager.instance.readerCustomTextColor,
        ),
      );
    }
  }

  void _showStyleSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setMState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Okuma Paneli Metin Ayarları', style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: ThemeManager.instance.readerFontSize,
                min: 14, max: 30, divisions: 8,
                label: "Boyut: ${ThemeManager.instance.readerFontSize.round()}",
                onChanged: (v) {
                  setMState(() => ThemeManager.instance.updateReaderSettings(v, ThemeManager.instance.readerFontFamily, ThemeManager.instance.readerCustomTextColor));
                  setState(() {});
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['monospace', 'serif', 'sans-serif'].map((font) {
                  return ChoiceChip(
                    label: Text(font),
                    selected: ThemeManager.instance.readerFontFamily == font,
                    onSelected: (selected) {
                      if (selected) {
                        setMState(() => ThemeManager.instance.updateReaderSettings(ThemeManager.instance.readerFontSize, font, ThemeManager.instance.readerCustomTextColor));
                        setState(() {});
                      }
                    },
                  );
                }).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayBuild = _buildNumber.contains("PLACEHOLDER") ? "Local" : _buildNumber;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.activeBook != null ? widget.activeBook!.title : 'Tayf RSVP Motoru', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Sayfa: ${_currentPage + 1}/${_pageSegments.isNotEmpty ? _pageSegments.length : 1} | V1.$displayBuild', style: const TextStyle(fontSize: 10)),
          ],
        ),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          IconButton(icon: const Icon(Icons.font_download), onPressed: _showStyleSettings),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [1, 2, 3, 4].map((modeIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text('Mod $modeIndex'),
                        selected: _readingMode == modeIndex,
                        onSelected: (val) {
                          if (val) {
                            _pauseTimer();
                            setState(() => _readingMode = modeIndex);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              
              // HATA DÜZELTİLDİ: Container içinde minHeight yerine constraints: BoxConstraints() kullanıldı
              Container(
                constraints: const BoxConstraints(minHeight: 180),
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(12),
                child: _buildReaderBody(),
              ),
              const SizedBox(height: 30),

              Text('Hız Ayarı (WPM): $_wpm', style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _wpm.toDouble(),
                min: 100, max: 1000,
                divisions: 90,
                label: _wpm.toString(),
                onChanged: (val) {
                  setState(() => _wpm = val.toInt());
                  if (_isPlaying) _startTimer();
                },
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.skip_previous), onPressed: widget.activeBook != null ? () => _changePage(-1) : null),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.replay_10), onPressed: () => setState(() => _currentWordIndex = (_currentWordIndex - 10).clamp(0, _engine.words.length - 1))),
                      FloatingActionButton(
                        onPressed: _isPlaying ? _pauseTimer : _startTimer,
                        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.skip_next), onPressed: widget.activeBook != null ? () => _changePage(1) : null),
                ],
              ),
              const SizedBox(height: 20),
              Text('By: Tayfun YAMAK ©', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }
}
