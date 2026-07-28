import 'dart:async';
import 'package:flutter/material.dart';
import 'book_database.dart';
import 'theme_manager.dart';

class AdvancedExerciseScreen extends StatefulWidget {
  final String rawText;
  final int exerciseType; // 1: Blok, 2: Gölgeleme, 3: Gruplama, 4: Takistoskop
  final BookModel? activeBook;

  const AdvancedExerciseScreen({
    Key? key,
    required this.rawText,
    required this.exerciseType,
    this.activeBook,
  }) : super(key: key);

  @override
  State<AdvancedExerciseScreen> createState() => _AdvancedExerciseScreenState();
}

class _AdvancedExerciseScreenState extends State<AdvancedExerciseScreen> {
  List<String> _words = [];
  List<List<String>> _chunks = [];
  
  int _currentChunkIndex = 0;
  int _chunkSize = 2; // Aynı anda gösterilecek kelime grubu sayısı
  int _speedMs = 300; 
  
  bool _isPlaying = false;
  Timer? _timer;

  // Takistoskop (Mod 4) için Özel Durumlar
  bool _isFlashing = false;
  bool _isWaitingForInput = false;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  String _takistoskopFeedback = "Başlamak için Başlat'a basın";
  Color _feedbackColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _words = widget.rawText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (_words.isEmpty) _words = ["Eğitim", "metni", "bulunamadı."];
    
    _generateChunks();

    // Kitaptan geliyorsa kalınan yerden (kelime endeksinden) başlat
    if (widget.activeBook != null) {
      int savedWordIndex = widget.activeBook!.lastPage * 60; // Ortalama sayfa başı 60 kelime sayıyoruz
      if (savedWordIndex < _words.length) {
        _currentChunkIndex = savedWordIndex ~/ _chunkSize;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _generateChunks() {
    _chunks = [];
    for (int i = 0; i < _words.length; i += _chunkSize) {
      int end = (i + _chunkSize < _words.length) ? i + _chunkSize : _words.length;
      _chunks.add(_words.sublist(i, end));
    }
    if (_currentChunkIndex >= _chunks.length) _currentChunkIndex = 0;
  }

  void _saveProgress() {
    if (widget.activeBook != null) {
      // Bulunduğu chunk'ı tahmini sayfa indeksine geri çevirerek kaydet
      int currentPage = (_currentChunkIndex * _chunkSize) ~/ 60;
      BookDatabase.instance.saveProgress(widget.activeBook!.id, currentPage, 300, widget.activeBook!.savedMode);
    }
  }

  void _togglePlay() {
    if (_isPlaying) {
      _timer?.cancel();
      setState(() {
        _isPlaying = false;
        if (widget.exerciseType == 4) {
          _isFlashing = false;
          _isWaitingForInput = false;
          _takistoskopFeedback = "Duraklatıldı";
        }
      });
      _saveProgress();
    } else {
      setState(() => _isPlaying = true);
      if (widget.exerciseType == 4) {
        _runTakistoskopCycle();
      } else {
        _runStandardTimer();
      }
    }
  }

  // Mod 1, 2 ve 3 için Standart Akış
  void _runStandardTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _speedMs), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentChunkIndex < _chunks.length - 1) {
          _currentChunkIndex++;
        } else {
          _timer?.cancel();
          _isPlaying = false;
        }
      });
      _saveProgress();
    });
  }

  // Mod 4: Takistoskop Özel Döngüsü (Göster -> Gizle -> Cevap Bekle)
  void _runTakistoskopCycle() {
    if (!mounted || !_isPlaying) return;
    
    setState(() {
      _isFlashing = true;
      _isWaitingForInput = false;
      _takistoskopFeedback = "Dikkat!";
      _feedbackColor = ThemeManager.instance.getReaderTextColor();
    });

    // Kelimeyi belirlenen milisaniye kadar ekranda tut ve gizle
    _timer = Timer(Duration(milliseconds: _speedMs), () {
      if (!mounted) return;
      setState(() {
        _isFlashing = false;
        _isWaitingForInput = true;
        _takistoskopFeedback = "Gördüğünüz kelime grubunu yazın ve Enter'a basın";
      });
      _inputFocus.requestFocus();
    });
  }

  void _checkTakistoskopInput(String value) {
    if (!_isWaitingForInput) return;

    String correctAnswer = _chunks[_currentChunkIndex].join(" ").toLowerCase();
    String userAnswer = value.trim().toLowerCase();

    setState(() {
      _isWaitingForInput = false;
      _inputController.clear();
      if (correctAnswer == userAnswer) {
        _takistoskopFeedback = "Tebrikler! Doğru.";
        _feedbackColor = Colors.green;
      } else {
        _takistoskopFeedback = "Hata! Doğrusu: '$correctAnswer'";
        _feedbackColor = Colors.red;
      }
    });

    // Sonucu gösterdikten 1 saniye sonra sıradaki kelimeye geç
    _timer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted || !_isPlaying) return;
      if (_currentChunkIndex < _chunks.length - 1) {
        _currentChunkIndex++;
        _runTakistoskopCycle();
      } else {
        setState(() {
          _isPlaying = false;
          _takistoskopFeedback = "Egzersiz Tamamlandı!";
        });
      }
    });
  }

  String get _exerciseName {
    switch (widget.exerciseType) {
      case 1: return "Blok Okuma";
      case 2: return "Gölgeleme Çalışması";
      case 3: return "Gruplama Çalışması";
      case 4: return "Takistoskop";
      default: return "Egzersiz";
    }
  }

  Widget _buildExerciseArea(Color textCol, Color focusCol, double fSize, String fFamily) {
    // MOD 1: BLOK OKUMA (Sadece aktif kelime grubu ekranın ortasında)
    if (widget.exerciseType == 1) {
      return Center(
        child: Text(
          _chunks[_currentChunkIndex].join(" "),
          style: TextStyle(fontSize: fSize * 1.5, fontWeight: FontWeight.bold, color: focusCol, fontFamily: fFamily),
          textAlign: TextAlign.center,
        ),
      );
    }

    // MOD 4: TAKİSTOSKOP (Klavye girişli flaşlama)
    if (widget.exerciseType == 4) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_takistoskopFeedback, style: TextStyle(color: _feedbackColor, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (_isFlashing)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                decoration: BoxDecoration(color: focusCol.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: focusCol)),
                child: Text(
                  _chunks[_currentChunkIndex].join(" "),
                  style: TextStyle(fontSize: fSize * 1.5, fontWeight: FontWeight.bold, color: focusCol, fontFamily: fFamily),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_isWaitingForInput)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocus,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: fSize, color: textCol, fontFamily: fFamily),
                  decoration: InputDecoration(
                    hintText: "Buraya yazın...",
                    filled: true,
                    fillColor: textCol.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: _checkTakistoskopInput,
                ),
              )
            else
              Container(height: fSize * 2), // Yer tutucu boşluk
          ],
        ),
      );
    }

    // MOD 2 (Gölgeleme) ve MOD 3 (Gruplama) için Metin Matrisi
    List<Widget> wordWidgets = [];
    for (int i = 0; i < _chunks.length; i++) {
      bool isCurrent = (i == _currentChunkIndex);
      String chunkText = _chunks[i].join(" ") + " ";

      Color wordColor = textCol;
      Color bgColor = Colors.transparent;

      if (widget.exerciseType == 2) {
        // GÖLGELEME: Odaktaki kelime normal, diğerleri arka plan rengiyle aynı yapılarak blok (gölge) gibi gösterilir
        if (isCurrent) {
          wordColor = focusCol;
          bgColor = focusCol.withOpacity(0.1);
        } else {
          wordColor = Colors.transparent; 
          bgColor = textCol.withOpacity(0.3); // Okunmayan kısımlar gri gölge bloğu olur
        }
      } else if (widget.exerciseType == 3) {
        // GRUPLAMA: Odaktaki kelime arka plan rengi yapılarak gizlenir, diğerleri normal okunur
        if (isCurrent) {
          wordColor = Colors.transparent;
          bgColor = textCol.withOpacity(0.4); // Üzerinde okunduğunu belirten bir gölge kutusu
        } else {
          wordColor = textCol;
        }
      }

      wordWidgets.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
          child: Text(
            chunkText,
            style: TextStyle(color: wordColor, fontSize: fSize, fontFamily: fFamily, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Wrap(
        alignment: WrapAlignment.start,
        children: wordWidgets,
      ),
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

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: Text(_exerciseName, style: const TextStyle(fontSize: 14)),
            elevation: 0,
            backgroundColor: bg,
            foregroundColor: textCol,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Grup: ${_currentChunkIndex + 1} / ${_chunks.length}', style: TextStyle(color: textCol, fontSize: 12)),
                    Text('İlerleme: %${((_currentChunkIndex / _chunks.length) * 100).toStringAsFixed(1)}', style: TextStyle(color: textCol, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: textCol.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
                  child: _buildExerciseArea(textCol, focusCol, fSize, fFamily),
                ),
              ),
              
              // KONTROL PANELİ
              Container(
                padding: const EdgeInsets.all(16),
                color: textCol.withOpacity(0.03),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed, color: textCol, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: _speedMs.toDouble(),
                            min: 50, max: 1500, divisions: 29,
                            activeColor: focusCol,
                            onChanged: (val) {
                              setState(() {
                                _speedMs = val.round();
                                if (_isPlaying && widget.exerciseType != 4) _runStandardTimer();
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 50, child: Text('$_speedMs ms', style: TextStyle(color: textCol, fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.format_size, color: textCol, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: _chunkSize.toDouble(),
                            min: 1, max: 5, divisions: 4,
                            activeColor: focusCol,
                            onChanged: (val) {
                              setState(() {
                                _chunkSize = val.round();
                                _generateChunks();
                                if (_isPlaying && widget.exerciseType != 4) _runStandardTimer();
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 50, child: Text('$_chunkSize Kel.', style: TextStyle(color: textCol, fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _togglePlay,
                        style: ElevatedButton.styleFrom(backgroundColor: focusCol, foregroundColor: Colors.white),
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        label: Text(_isPlaying ? 'DURDUR' : 'BAŞLAT', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
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
