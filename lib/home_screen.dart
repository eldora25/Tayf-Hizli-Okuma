import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'reader_screen.dart';
import 'theme_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();
  bool _isLoading = false;

  final Map<String, String> _presetTexts = {
    "Hızlı Okuma Nedir?":
        "Hızlı okuma, göz kaslarını geliştirerek ve kelimeleri tek tek değil gruplar halinde görerek okuma hızını artırma tekniğidir. İnsan beyni kelimeleri resim gibi algılar. Bu sayede odaklanma artar ve zamandan tasarruf edilir.",
    "Odaklanma Egzersizi":
        "Gözlerimiz okuma yaparken sürekli geriye sıçrama eğilimindedir. RSVP tekniği kelimeleri tek bir noktada göstererek bu sıçramaları engeller. Böylece dikkat dağınıklığı minimuma iner ve algılama hızı maksimuma çıkar.",
  };

  Future<void> _fetchTextFromUrl(String url) async {
    if (url.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        String cleanText = response.body
            .replaceAll(RegExp(r'<[^>]*>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ');
        setState(() {
          _textController.text = cleanText;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bağlantı başarıyla yüklendi!')),
          );
        }
      } else {
        throw Exception('Veri çekilemedi.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: Bağlantı okunamadı ($e)')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _simulateFileUpload() {
    setState(() {
      _fileNameController.text = "kitap_verisi.txt (Yüklendi)";
      _textController.text = "Dosyadan başarıyla okunan hızlı okuma metni metodu: Görsel algılama yeteneğinizi geliştirmek için kelimeleri bloklar halinde okumayı alışkanlık haline getirmelisiniz. Bu yüklenen dosya içeriğidir.";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dosya simülasyonu başarıyla yüklendi!')),
    );
  }

  void _showThemeSettingsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final themeMgr = ThemeManager.instance;
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Görünüm Modu', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                        label: Text('Açık'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                        label: Text('Karanlık'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.settings_suggest),
                        label: Text('Sistem'),
                      ),
                    ],
                    selected: {themeMgr.themeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      setModalState(() {
                        themeMgr.setThemeMode(newSelection.first);
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Renk Paleti', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppThemePalette.values.map((palette) {
                      final isSelected = themeMgr.currentPalette == palette;
                      Color color;
                      switch (palette) {
                        case AppThemePalette.deepPurple:
                          color = Colors.deepPurple;
                          break;
                        case AppThemePalette.oceanBlue:
                          color = const Color(0xFF0277BD);
                          break;
                        case AppThemePalette.emeraldGreen:
                          color = const Color(0xFF2E7D32);
                          break;
                        case AppThemePalette.sunsetOrange:
                          color = const Color(0xFFE65100);
                          break;
                        case AppThemePalette.warmSepia:
                          color = const Color(0xFF6D4C41);
                          break;
                      }

                      return FilterChip(
                        avatar: CircleAvatar(backgroundColor: color, radius: 10),
                        label: Text(themeMgr.getPaletteName(palette)),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          if (selected) {
                            setModalState(() {
                              themeMgr.setPalette(palette);
                            });
                            setState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tayf Hızlı Okuma'),
        centerTitle: true,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Tema ve Renk Paleti',
            onPressed: _showThemeSettingsDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HAZIR EĞİTİM METİNLERİ
            Text('1. Hazır Eğitim Metinleri', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
            const SizedBox(height: 8),
            Card(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _presetTexts.length,
                itemBuilder: (context, index) {
                  String title = _presetTexts.keys.elementAt(index);
                  return ListTile(
                    title: Text(title, style: TextStyle(fontWeight: FontWeight.w6amp;500)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.secondary),
                    onTap: () {
                      _textController.text = _presetTexts[title]!;
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 2. BAĞLANTI (URL) METNİ
            Text('2. İnternet Bağlantısından Metin Çek', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'https://example.com/makale',
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: colorScheme.secondaryContainer, foregroundColor: colorScheme.onSecondaryContainer),
                        onPressed: () => _fetchTextFromUrl(_urlController.text),
                        child: const Text('Getir'),
                      ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. DOSYA SEÇME ALANI
            Text('3. Cihazdan Dosya (.txt) Seç / Yükle', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fileNameController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: 'Dosya seçilmedi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: colorScheme.tertiaryContainer, foregroundColor: colorScheme.onTertiaryContainer),
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Dosya Seç'),
                  onPressed: _simulateFileUpload,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. MANUEL KOPYALAMA VE METİN ALANI
            Text('4. Manuel Metin Girişi veya Kopyalama Alanı', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: 'Kopyaladığınız metni buraya yapıştırın veya yukarıdaki kaynakları kullanın...',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.primary, width: 2)),
              ),
            ),
            const SizedBox(height: 24),

            // ÇALIŞMAYI BAŞLATMA BUTONU
            SWidth(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Okuma Egzersizini Başlat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 4,
                ),
                onPressed: () {
                  if (_textController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen önce bir metin ekleyin veya dosya yükleyin!')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReaderScreen(rawText: _textController.text),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Yardımcı widget (SizedBox kısaltması kütüphane çakışması önleme amaçlı)
class SWidth extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;
  const SWidth({super.key, required this.width, required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height, child: child);
  }
}
