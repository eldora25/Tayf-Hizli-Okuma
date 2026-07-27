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
  int _wpm = 300; // Başlangıç WPM değeri
  bool _isPlaying = false;
  Timer? _timer;

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
    // WPM değerini milisaniyeye çeviren matematiksel formül
    int intervalMs = ((60 / _wpm) * 1000).round();

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (_currentWordIndex < _engine.words.length - 1) {
        setState(() {
          _currentWordIndex++;
        });
      } else {
        _pauseTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tebrikler! Okuma çalışması tamamlandı.')),
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

  /// Kelimeyi odak noktasına göre renkli parçalara ayırıp RichText olarak döner
  Widget _buildSpritzWord(String word) {
    if (word.isEmpty) return const SizedBox.shrink();

    int focusIndex = SpeedReaderEngine.getOptimalFocusIndex(word);
    
    String leftPart = word.substring(0, focusIndex);
    String focusChar = word.substring(focusIndex, focusIndex + 1);
    String rightPart = word.substring(focusIndex + 1);

    const textStyle = TextStyle(fontSize: 36, fontWeight: FontWeight.w400, fontFamily: 'monospace');

    return RichText(
      text: TextSpan(
        style: textStyle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
        children: [
          // Sol Kısım (Sağa hizalı hissi yaratmak için boşluk yönetimi eklenebilir)
          TextSpan(text: leftPart),
          // Odak Noktası (Kırmızı / Vurgulu Renk)
          TextSpan(
            text: focusChar,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          // Sağ Kısım
          TextSpan(text: rightPart),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentWord = _engine.words[_currentWordIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tayf RSVP Egzersizi'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ÜST BİLGİ: İlerleme Çubuğu ve Kelime Sayacı
          Padding(
            padding: const EdgeInsets.all(16.0),
            key: const ValueKey('progress_section'),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _engine.words.isEmpty ? 0 : (_currentWordIndex + 1) / _engine.words.length,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelime: ${_currentWordIndex + 1} / ${_engine.words.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // ORTA KISIM: Spritz Odaklama Arayüzü
          Column(
            children: [
              // Üst Kılavuz Odak Çizgisi
              Container(
                width: 300,
                height: 2,
                color: Theme.of(context).dividerColor,
              ),
              const SizedBox(height: 4),
              // Dikey Merkezleme Kılavuz Çentiği (Üst)
              const Icon(Icons.arrow_drop_down, color: Colors.red),
              
              // KELİME GÖSTERİM ALANI
              Container(
                alignment: Alignment.center,
                height: 100,
                width: double.infinity,
                child: _buildSpritzWord(currentWord),
              ),

              // Dikey Merkezleme Kılavuz Çentiği (Alt)
              const Icon(Icons.arrow_drop_up, color: Colors.red),
              const SizedBox(height: 4),
              // Alt Kılavuz Odak Çizgisi
              Container(
                width: 300,
                height: 2,
                color: Theme.of(context).dividerColor,
              ),
            ],
          ),

          // ALT KISIM: Hız Kontrolü (WPM) ve Oynatma Butonları
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0, left: 16, right: 16),
            child: Column(
              children: [
                // Hız Ayarı (WPM) Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.speed),
                    const SizedBox(width: 8),
                    Text('Hız (WPM): $_wpm', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _wpm.toDouble(),
                  min: 100,
                  max: 1000,
                  divisions: 18,
                  label: _wpm.toString(),
                  onChanged: (value) {
                    setState(() {
                      _wpm = value.toInt();
                    });
                    if (_isPlaying) {
                      _startTimer(); // Çalışırken hız değiştirilirse motoru güncelle
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Oynat, Duraklat, Sıfırla Butonları
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.refresh),
                      onPressed: _resetTimer,
                    ),
                    const SizedBox(width: 20),
                    FloatingActionButton(
                      onPressed: _isPlaying ? _pauseTimer : _startTimer,
                      child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    ),
                    const SizedBox(width: 56), // Simetri dengelemesi için boşluk
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
