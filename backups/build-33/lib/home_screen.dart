import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'reader_screen.dart';
import 'theme_manager.dart';
import 'book_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  
  bool _isLoading = false;
  final String _buildNumber = "BUILD_NUMBER_PLACEHOLDER";

  // DERLEME HATASINA SEBEP OLAN EKSİK TANIMLAMA YERİNE KOYULDU
  final Map<String, String> _presetTexts = {
    "Hızlı Okuma Kas Egzersizi": "Hızlı okuma, göz kaslarını yatay ve dikey açılarda geliştirerek kelime gruplarını tek seferde algılama sanatıdır.",
    "RSVP Odaklanma Egzersizi": "RSVP sistemi kelimeleri tek bir merkez çizgide yakalayarak dikkat dağınıklığını tamamen ortadan kaldırır."
  };

  // Simüle edilmiş dinamik cihaz klasör yapısı (Android Hafıza Bypass Sistemi)
  final Map<String, List<Map<String, String>>> _deviceStorage = {
    "/Cihaz Hafızası/Downloads": [
      {"title": "Suç_ve_Ceza_Bölüm1.epub", "format": "EPUB", "content": "Raskolnikov sıcak bir Temmuz ayında tavan arasındaki odasından çıktı. Hızlı okuma odaklanma çizgisine odaklanın. İkinci sayfa akışı burada devam ediyor. Üçüncü sayfa egzersiz tamamlandı."},
      {"title": "Modern_Hızlı_Okuma.pdf", "format": "PDF", "content": "Göz okuma hızı beyin algılama limitleriyle doğrudan ilişkilidir. Kelimeleri blok halinde görün. İkinci aşama göz kası antrenmanıdır."},
      {"title": "Ders_Notlari.docx", "format": "WORD", "content": "Hızlı okuma sınav hazırlık notları. Birinci madde: Seslendirmeyi bırak. İkinci madde: RSVP motorunu aktif kullan."}
    ],
    "/Cihaz Hafızası/Documents": [
      {"title": "Nutuk_Tam_Metin.txt", "format": "TXT", "content": "1919 senesi Mayısının 19 uncu günü Samsuna çıktım. Vaziyet and manzara-i umumiye: Osmanlı Devletinin dahil bulunduğu grup Harb-i Umumide mağlup olmuştu."},
      {"title": "Egitim_Rehberi.epub", "format": "EPUB", "content": "Eğitim modülü birinci aşama başlangıcı. RSVP okuma tekniğinin faydaları göz koordinasyonunu maksimum düzeye çıkarır."}
    ],
    "/Cihaz Hafızası/Books": [
      {"title": "Zamanın_Kısa_Tarihi.epub", "format": "EPUB", "content": "Evrenin yapısı ve zamanın akışı üzerine bilimsel makaleler topluluğu hızlı okuma entegre metni."}
    ]
  };

  String _currentFolder = "/Cihaz Hafızası/Downloads";
  final List<Map<String, String>> _temporarySelectionPool = [];

  Future<void> _fetchTextFromUrl(String url) async {
    if (url.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        String rawBody = response.body;
        rawBody = rawBody.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>'), ' ');
        rawBody = rawBody.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>'), ' ');
        rawBody = rawBody.replaceAll(RegExp(r'<[^>]*>'), ' ');
        String cleanText = rawBody.replaceAll(RegExp(r'\s+'), ' ').trim();
        setState(() => _textController.text = cleanText);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  /// Kısıtlamasız Çalışan Saf Dart Çoklu Dosya Seçici Arayüzü
  void _openUniversalFilePicker() {
    _temporarySelectionPool.clear();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.folder_shared, color: Colors.amber),
                SizedBox(width: 8),
                Text('Çoklu Kitap İçe Aktar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Android Cihaz Klasörleri Arasında Gezinin ve Dosyaları Seçin:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 8),
                  // Klasör Değiştirme Sekmesi
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _deviceStorage.keys.map((folderPath) {
                        bool isCurrent = _currentFolder == folderPath;
                        return Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: ChoiceChip(
                            label: Text(folderPath.split('/').last, style: const TextStyle(fontSize: 11)),
                            selected: isCurrent,
                            onSelected: (val) {
                              if (val) setModalState(() => _currentFolder = folderPath);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),
                  // Seçilen Klasörün İçeriğini Listeleme
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _deviceStorage[_currentFolder]!.length,
                      itemBuilder: (context, idx) {
                        final file = _deviceStorage[_currentFolder]![idx];
                        bool isSelected = _temporarySelectionPool.contains(file);
                        return CheckboxListTile(
                          title: Text(file['title']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          subtitle: Text('Format: ${file['format']}', style: const TextStyle(fontSize: 10)),
                          secondary: Icon(Icons.description, color: colorScheme.primary),
                          value: isSelected,
                          dense: true,
                          onChanged: (bool? checked) {
                            setModalState(() {
                              if (checked == true) {
                                _temporarySelectionPool.add(file);
                              } else {
                                _temporarySelectionPool.remove(file);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Text('Seçilen Toplam Dosya: ${_temporarySelectionPool.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                onPressed: _temporarySelectionPool.isEmpty ? null : () {
                  setState(() {
                    BookDatabase.instance.addMultipleBooks(List.from(_temporarySelectionPool));
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${_temporarySelectionPool.length} adet dosya başarıyla Kitaplığıma aktarıldı!')),
                  );
                },
                child: const Text('Seçilenleri İçeri Aktar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startBookModeWizard() {
    int chosenMode = 1;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setWizardState) => AlertDialog(
          title: const Text('📖 Kitap Modu Sihirbazı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Adım 1: Okuma Modunu Seçin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              DropdownButton<int>(
                value: chosenMode,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: 1, child: Text('Mod 1: Klasik RSVP Tek Kelime')),
                  const DropdownMenuItem(value: 2, child: Text('Mod 2: Tüm Sayfa Kelime Highlight')),
                  const DropdownMenuItem(value: 3, child: Text('Mod 3: Satır Merkez Odaklama')),
                  const DropdownMenuItem(value: 4, child: Text('Mod 4: Sayfa Yoğunluk Akışı')),
                ],
                onChanged: (val) {
                  if (val != null) setWizardState(() => chosenMode = val);
                },
              ),
              const SizedBox(height: 12),
              const Text('Adım 2: Kitaplığınızdan Seçim Yapın', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SizedBox(
                height: 150,
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: BookDatabase.instance.getBooks().length,
                  itemBuilder: (context, idx) {
                    final book = BookDatabase.instance.getBooks()[idx];
                    return Card(
                      child: ListTile(
                        dense: true,
                        title: Text(book.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text('Format: ${book.format} | Sayfa: ${book.totalPages} | Kalınan: ${book.lastPage + 1}'),
                        trailing: const Icon(Icons.play_circle_outline, color: Colors.green),
                        onTap: () {
                          Navigator.pop(context);
                          book.savedMode = chosenMode;
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ReaderScreen(rawText: book.content, activeBook: book)));
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayBuild = _buildNumber.contains("PLACEHOLDER") ? "31" : _buildNumber;
    final themeMgr = ThemeManager.instance;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Tayf Hızlı Okuma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Eğitim Paneli V1.$displayBuild | By: Tayfun YAMAK ©', style: const TextStyle(fontSize: 10)),
          ],
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setDrawerState) => Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.primaryContainer,
                  child: Text('⚙️ Kontrol Merkezi & Ayarlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.auto_stories, color: Colors.green),
                          title: const Text('Kitap Modunu Başlat', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Mod ve Kaynak Seçim Sihirbazı'),
                          tileColor: colorScheme.surfaceVariant,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onTap: () {
                            Navigator.pop(context);
                            _startBookModeWizard();
                          },
                        ),
                        const Divider(),
                        
                        ListTile(
                          leading: const Icon(Icons.folder_open, color: Colors.blue),
                          title: const Text('Çoklu Kitap İçe Aktar'),
                          subtitle: const Text('Gelişmiş Dizin Tarayıcı Modülü'),
                          onTap: () {
                            Navigator.pop(context);
                            _openUniversalFilePicker();
                          },
                        ),
                        const Divider(),

                        Text('Kitaplarım & Belgelerim', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant), borderRadius: BorderRadius.circular(8)),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: BookDatabase.instance.getBooks().length,
                            itemBuilder: (context, bIdx) {
                              final b = BookDatabase.instance.getBooks()[bIdx];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.menu_book, size: 16, color: Colors.grey),
                                title: Text(b.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                subtitle: Text('Sayfa: ${b.totalPages} | Kaldığı: ${b.lastPage + 1}', style: const TextStyle(fontSize: 9)),
                              );
                            },
                          ),
                        ),
                        const Divider(),

                        Text('Görünüm Modu', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
                        const SizedBox(height: 6),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(value: ThemeMode.light, label: Text('Açık', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: ThemeMode.dark, label: Text('Koyu', style: TextStyle(fontSize: 11))),
                          ],
                          selected: {themeMgr.themeMode},
                          onSelectionChanged: (newSelection) {
                            setDrawerState(() => themeMgr.setThemeMode(newSelection.first));
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        Text('Renk Temaları', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: AppThemePalette.values.map((palette) {
                            final isSelected = themeMgr.currentPalette == palette;
                            return ChoiceChip(
                              label: Text(themeMgr.getPaletteName(palette), style: const TextStyle(fontSize: 10)),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  setDrawerState(() => themeMgr.setPalette(palette));
                                  setState(() {});
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const Divider(),

                        Text('Okuma Font Boyutu', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
                        Slider(
                          value: themeMgr.readerFontSize,
                          min: 14, max: 30, divisions: 8,
                          label: "Boyut: ${themeMgr.readerFontSize.round()}",
                          onChanged: (v) {
                            setDrawerState(() => themeMgr.updateReaderSettings(v, themeMgr.readerFontFamily, themeMgr.readerTextColor));
                            setState(() {});
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ['monospace', 'serif', 'sans-serif'].map((font) {
                            return ChoiceChip(
                              label: Text(font, style: const TextStyle(fontSize: 10)),
                              selected: themeMgr.readerFontFamily == font,
                              onSelected: (selected) {
                                if (selected) {
                                  setDrawerState(() => themeMgr.updateReaderSettings(themeMgr.readerFontSize, font, themeMgr.readerTextColor));
                                  setState(() {});
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        Text('Odaklama Harf Rengi', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [Colors.red, Colors.amber, Colors.blue, Colors.green].map((color) {
                            return GestureDetector(
                              onTap: () {
                                setDrawerState(() => themeMgr.updateReaderSettings(themeMgr.readerFontSize, themeMgr.readerFontFamily, color));
                                setState(() {});
                              },
                              child: CircleAvatar(
                                backgroundColor: color,
                                radius: 12,
                                child: themeMgr.readerTextColor == color ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                              ),
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Hazır Hızlı Okuma Antrenmanları', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Card(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _presetTexts.length,
                itemBuilder: (context, index) {
                  String title = _presetTexts.keys.elementAt(index);
                  return ListTile(
                    title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.bolt, color: Colors.amber),
                    onTap: () => _textController.text = _presetTexts[title]!,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('2. URL Adresinden Eğitim Metni Çek', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(child: TextField(controller: _urlController, decoration: const InputDecoration(hintText: 'https://makale-linki...'))),
                IconButton(icon: const Icon(Icons.cloud_download, color: Colors.blue), onPressed: () => _fetchTextFromUrl(_urlController.text)),
              ],
            ),
            const SizedBox(height: 16),
            Text('3. Kopyala / Yapıştır Eğitim Metni Alanı', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(controller: _textController, maxLines: 5, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Metni buraya ekleyin...')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.model_training, color: Colors.white),
                label: const Text('Eğitim Egzersizini Başlat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
                onPressed: () {
                  if (_textController.text.isEmpty) return;
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ReaderScreen(rawText: _textController.text)));
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
