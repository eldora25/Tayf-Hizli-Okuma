import 'dart:async';
import 'package:flutter/material.dart';
import 'speed_reader_engine.dart';

class ReaderScreen extends StatefulWidget {
  final String rawText;
  const ReaderScreen({super.key, required this.rawText});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late SpeedReaderEngine _engine;
  int _currentWordIndex = 0;
  int _wpm = 300;
  bool _isPlaying = false;
  Timer? _timer;

  final String _buildNumber = "BUILD_NUMBER_PLACEHOLDER";

  @override
  void initState() {
    super.initState();
    _engine = SpeedReaderEngine(text: widget.rawText);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    int intervalMs = ((60 / _wpm) * 1000).round();

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (_currentWordIndex < _engine.words.length - 1) {
        setState(() {
          _currentWordIndex++;
        });
      } else {
        _pauseTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Egzersiz başarıyla tamamlandı!')),
        );
      }
    });
    setState(() => _isPlaying = true);
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() {
      _currentWordIndex = 0;
    });
  }

  Widget _buildSpritzFocusWord(String word) {
    if (word.isEmpty) return const SizedBox.shrink();

    int focusIndex = SpeedReaderEngine.getOptimalFocusIndex(word);
    
    if (focusIndex >= word.length) {
      focusIndex = 0;
    }

    String leftPart = word.substring(0, focusIndex);
    String focusChar = word.substring(focusIndex, focusIndex + 1);
    String rightPart = word.substring(focusIndex + 1);

    const textStyle = TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.bold,
      fontFamily: 'monospace',
    );

    final defaultColor = Theme.of(context).textTheme.bodyLarge?.color;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: textStyle.copyWith(color: defaultColor),
        children: [
          TextSpan(text: leftPart),
          TextSpan(
            text: focusChar,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
          ),
          TextSpan(text: rightPart),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentWord = _engine.words[_currentWordIndex];
    final colorScheme = Theme.of(context).colorScheme;
    final displayBuild = _buildNumber.contains("PLACEHOLDER") ? "Local" : _buildNumber;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('RSVP Okuma Motoru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'V1.$displayBuild | By: Tayfun YAMAK ©',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      // Sanal tuşların butonları ezmesini ve taşmasını yüzde yüz engellemek için kaydırılabilir gövde mimarisi
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // İLERLEME ÇUBUĞU
                LinearProgressIndicator(
                  value: _engine.words.isEmpty ? 0 : (_currentWordIndex + 1) / _engine.words.length,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelime: ${_currentWordIndex + 1} / ${_engine.words.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 60),

                // ORTA KISIM: Odak Çerçevesi
                Container(
                  width: 320,
                  height: 2,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 4),
                Icon(Icons.arrow_drop_down, color: colorScheme.primary, size: 30),
                Container(
                  alignment: Alignment.center,
                  height: 120,
                  width: double.infinity,
                  child: _buildSpritzFocusWord(currentWord),
                ),
                Icon(Icons.arrow_drop_up, color: colorScheme.primary, size: 30),
                const SizedBox(height: 4),
                Container(
                  width: 320,
                  height: 2,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 60),

                // KONTROL PANELİ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.speed, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Hız (WPM): $_wpm',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: _wpm.toDouble(),
                  min: 100,
                  max: 1000,
                  divisions: 18,
                  activeColor: colorScheme.primary,
                  inactiveColor: colorScheme.surfaceContainerHighest,
                  label: _wpm.toString(),
                  onChanged: (value) {
                    setState(() {
                      _wpm = value.toInt();
                    });
                    if (_isPlaying) {
                      _startTimer();
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 38,
                      icon: const Icon(Icons.refresh),
                      color: colorScheme.secondary,
                      onPressed: _resetTimer,
                    ),
                    const SizedBox(width: 20),
                    FloatingActionButton(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      onPressed: _isPlaying ? _pauseTimer : _startTimer,
                      child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 30),
                    ),
                    const SizedBox(width: 58),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
