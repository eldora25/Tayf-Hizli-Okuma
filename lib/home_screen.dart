import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'reader_screen.dart';
import 'theme_manager.dart';
import 'book_database.dart';
import 'file_picker_screen.dart';

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

  final Map<String, String> _presetTexts = {
    "Hızlı Okuma Kas Egzersizi": "Hızlı okuma, göz kaslarını yatay ve dikey açılarda geliştirerek kelime gruplarını tek seferde algılama sanatıdır.",
    "RSVP Odaklanma Egzersizi": "RSVP sistemi kelimeleri tek bir merkez çizgide yakalayarak dikkat dağınıklığını tamamen ortadan kaldırır."
  };

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    await BookDatabase.instance.loadDefaultAssets();
    if (mounted) setState(() {}); 
  }

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

  void _startBookModeWizard() {
    int chosenMode = 1;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setWizardState) => AlertDialog(
          title: const Text('📖 Kitap Okuma Sihirbazı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. Okuma Modunu Seçin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              DropdownButton<int>(
                value: chosenMode,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Mod 1: Klasik RSVP Odak')),
                  DropdownMenuItem(value: 2, child: Text('Mod 2: Sayfa İçi Highlight')),
                  DropdownMenuItem(value: 3, child: Text('Mod 3: Satır Odaklaması')),
                  DropdownMenuItem(value: 4, child: Text('Mod 4: Sayfa Merkez Odaklaması')),
                ],
                onChanged: (val) {
                  if (val != null) setWizardState(() => chosenMode = val);
                },
              ),
              const SizedBox(height: 12),
              const Text('2. Kütüphanenizden Kitap Seçin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SizedBox(
                height: 220,
                width: double.maxFinite,
                child: BookDatabase.instance.getBooks().isEmpty
                    ? const Center(child: Text('Kitaplığınız boş. İçe aktarın.', style: TextStyle(fontSize: 12, color: Colors.grey)))
                    : ListView.builder(
                        itemCount: BookDatabase.instance.getBooks().length,
                        itemBuilder: (context, idx) {
                          final book = BookDatabase.instance.getBooks()[idx];
                          return Card(
                            elevation: 2,
                            child: ListTile(
                              dense: true,
                              title: Text(book.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text('Sayfa: ${book.totalPages} | Kalınan: ${book.lastPage + 1}'),
                              trailing: const Icon(Icons.play_circle_fill, color: Colors.blueAccent),
                              onTap: () {
                                Navigator.pop(context);
                                book.savedMode = chosenMode;
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ReaderScreen(rawText: book.content, activeBook: book))).then((_) {
                                  setState(() {}); // Okuma ekranından dönünce kalınan sayfayı güncelle
                                });
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
    final displayBuild = _buildNumber.contains("PLACEHOLDER") ? "71" : _buildNumber;
    final themeMgr = ThemeManager.instance;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Tayf Eğitim Merkezi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Build V1.$displayBuild | By: Tayfun YAMAK ©', style: const TextStyle(fontSize: 10)),
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
                  child: Text('⚙️ Ayarlar & Kütüphane', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.auto_stories, color: Colors.blueAccent),
                          title: const Text('Kitap Okuma Modu', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Kütüphaneye Git'),
                          tileColor: colorScheme.surfaceVariant,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onTap: () {
                            Navigator.pop(context);
                            _startBookModeWizard();
                          },
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.folder_open, color: Colors.green),
                          title: const Text('Dosya İçe Aktar'),
                          subtitle: const Text('EPUB, TXT Cihazdan Seç'),
                          onTap: () async {
                            Navigator.pop(context); 
                            final bool? success = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FilePickerScreen()),
                            );
                            if (success == true) setState(() {}); 
                          },
                        ),
                        const Divider(),

                        Text('Kitaplarım (${BookDatabase.instance.getBooks().length})', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant), borderRadius: BorderRadius.circular(8)),
                          child: BookDatabase.instance.getBooks().isEmpty
                              ? const Center(child: Text('Kütüphane Boş', style: TextStyle(fontSize: 11, color: Colors.grey)))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: BookDatabase.instance.getBooks().length,
                                  itemBuilder: (context, bIdx) {
                                    final b = BookDatabase.instance.getBooks()[bIdx];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.menu_book, size: 16, color: Colors.grey),
                                      title: Text(b.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      subtitle: Text('Sayfa: ${b.totalPages} | Kaldığı: ${b.lastPage + 1}', style: const TextStyle(fontSize: 9)),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _startBookModeWizard();
                                      },
                                    );
                                  },
                                ),
                        ),
                        const Divider(),

                        Text('Görünüm & Tema', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
                        const SizedBox(height: 6),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(value: ThemeMode.light, label: Text('Açık', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: ThemeMode.dark, label: Text('Koyu', style: TextStyle(fontSize: 11))),
                          ],
                          selected: {themeMgr.themeMode},
                          onSelectionChanged: (newSelection) {
                            themeMgr.setThemeMode(newSelection.first);
                            setDrawerState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: AppThemePalette.values.map((palette) {
                            return ChoiceChip(
                              label: Text(themeMgr.getPaletteName(palette), style: const TextStyle(fontSize: 10)),
                              selected: themeMgr.currentPalette == palette,
                              onSelected: (val) {
                                if (val) themeMgr.setPalette(palette);
                                setDrawerState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const Divider(),

                        Text('Okuma Ayarları (Kalıcı)', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
                        Slider(
                          value: themeMgr.readerFontSize,
                          min: 14, max: 40, divisions: 13,
                          label: "Punto: ${themeMgr.readerFontSize.round()}",
                          onChanged: (v) {
                            themeMgr.updateReaderSettings(v, themeMgr.readerFontFamily, themeMgr.readerTextColor);
                            setDrawerState(() {});
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ['monospace', 'serif', 'sans-serif'].map((font) {
                            return ChoiceChip(
                              label: Text(font, style: const TextStyle(fontSize: 10)),
                              selected: themeMgr.readerFontFamily == font,
                              onSelected: (s) {
                                if (s) themeMgr.updateReaderSettings(themeMgr.readerFontSize, font, themeMgr.readerTextColor);
                                setDrawerState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [Colors.red, Colors.amber, Colors.blue, Colors.green].map((color) {
                            return GestureDetector(
                              onTap: () {
                                themeMgr.updateReaderSettings(themeMgr.readerFontSize, themeMgr.readerFontFamily, color);
                                setDrawerState(() {});
                              },
                              child: CircleAvatar(
                                backgroundColor: color,
                                radius: 12,
                                child: themeMgr.readerTextColor.value == color.value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                              ),
                            );
                          }).toList(),
                        ),
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
            Text('1. Hazır Egzersizler', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
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
            Text('2. İnternetten Metin Çek', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(child: TextField(controller: _urlController, decoration: const InputDecoration(hintText: 'https://makale-linki...'))),
                IconButton(icon: const Icon(Icons.cloud_download, color: Colors.blue), onPressed: () => _fetchTextFromUrl(_urlController.text)),
              ],
            ),
            const SizedBox(height: 16),
            Text('3. Serbest Eğitim Alanı', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(controller: _textController, maxLines: 5, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Metni buraya yapıştırın...')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.model_training, color: Colors.white),
                label: const Text('Eğitimi Başlat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
