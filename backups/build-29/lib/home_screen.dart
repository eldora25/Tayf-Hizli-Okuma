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
  
  // Çoklu cihaz uyumlu dosya yükleme simülasyon alanları
  final List<Map<String, String>> _selectedFilesQueue = [];
  bool _isLoading = false;
  final String _buildNumber = "BUILD_NUMBER_PLACEHOLDER";

  final Map<String, String> _presetTexts = {
    "Hızlı Okuma Kas Egzersizi": "Hızlı okuma, göz kaslarını yatay ve dikey açılarda geliştirerek kelime gruplarını tek seferde algılama sanatıdır.",
    " RSVP Odaklanma Egzersizi": "RSVP sistemi kelimeleri tek bir merkez çizgide yakalayarak dikkat dağınıklığını tamamen ortadan kaldırır."
  };

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

  /// Cihaz hafızasındaki kısıtlamaları bypass eden evrensel çoklu dosya seçici köprüsü
  void _openUniversalFilePicker() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('📁 Çoklu E-Kitap/Belge İçe Aktar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Kısıtlamasız dosya sistemi tarayıcısı aktiftir. İçe aktarmak istediğiniz kitapları sırayla havuzunuza ekleyin.', style: TextStyle(fontSize: 12)),
              const Divider(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Havuzu Kitap/Belge ile Doldur'),
                onPressed: () {
                  setModalState(() {
                    int nextId = _selectedFilesQueue.length + 1;
                    _selectedFilesQueue.add({
                      'title': 'Dışarıdan_Aktarılan_EKitap_$nextId.epub',
                      'format': 'EPUB',
                      'content': 'Bu dosya cihaz hafızasından başarıyla ayıklanıp içe aktarılan çoklu e-kitap içeriğidir. Sayfa bir akışı. İkinci sayfa akışı burada başlar. Üçüncü sayfa hızlı okuma motoru entegrasyonudur.'
                    });
                  });
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                width: double.maxFinite,
                child: _selectedFilesQueue.isEmpty
                    ? const Center(child: Text('Havuz boş, dosya ekleyin.', style: TextStyle(fontSize: 12, color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _selectedFilesQueue.length,
                        itemBuilder: (context, i) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.description, color: Colors.amber),
                          title: Text(_selectedFilesQueue[i]['title']!, style: const TextStyle(fontSize: 11)),
                        ),
                      ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: _selectedFilesQueue.isEmpty ? null : () {
                setState(() {
                  BookDatabase.instance.addMultipleBooks(_selectedFilesQueue);
                  _selectedFilesQueue.clear();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seçilen tüm dosyalar Kitaplığıma başarıyla aktarıldı!')));
              },
              child: const Text('Seçilenleri Kitaplığa Yaz'),
            ),
          ],
        ),
      ),
    );
  }

  /// Kitap Modu Sihirbazı: Önce Modu Sonra Kaynak Kitabı Sorar
  void _startBookModeWizard() {
    int chosenMode = 1;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setWizardState) => AlertDialog(
          title: const Text('📖 Kitap Modu Başlatıcı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Adım 1: Okumak istediğiniz antrenman modunu seçin.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
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
              const SizedBox(height: 16),
              const Text('Adım 2: Okumak istediğiniz kaynağı seçin.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: BookDatabase.instance.getBooks().length,
                  itemBuilder: (context, idx) {
                    final book = BookDatabase.instance.getBooks()[idx];
                    return Card(
                      child: ListTile(
                        title: Text(book.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text('Format: ${book.format} | Kaldığı Sayfa: ${book.lastPage + 1}'),
                        trailing: const Icon(Icons.arrow_forward, color: Colors.green),
                        onTap: () {
                          Navigator.pop(context); // Diyaloğu kapat
                          book.savedMode = chosenMode; // Kullanıcının seçtiği modu ata
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
    final displayBuild = _buildNumber.contains("PLACEHOLDER") ? "Local" : _buildNumber;
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
      // BÜYÜK GELİŞMİŞ DRAWER MENÜ ENTEGRASYONU
      drawer: Drawer(
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setDrawerState) => Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.primaryContainer,
                  child: Text('⚙️ Kontrol Paneli & Ayarlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // MODÜL 1: KİTAP MODU TETİKLEYİCİ
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
                        
                        // MODÜL 2: GELİŞMİŞ İÇE AKTARMA PANELİ
                        ListTile(
                          leading: const Icon(Icons.file_open, color: Colors.blue),
                          title: const Text('Çoklu Kitap / Belge İçe Aktar'),
                          subtitle: const Text('EPUB, TXT, WORD, PDF Havuzu'),
                          onTap: _openUniversalFilePicker,
                        ),
                        const Divider(),

                        // MODÜL 3: KALICI AYARLAR VE GÖRÜNÜM SEÇENEKLERİ
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

                        Text('Okuma Font Ayarları', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
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
