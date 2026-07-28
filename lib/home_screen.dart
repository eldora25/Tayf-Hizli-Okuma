import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'reader_screen.dart';
import 'theme_manager.dart';
import 'book_database.dart';
import 'file_picker_screen.dart';
import 'advanced_exercise_screen.dart';

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

  Map<String, String> _presetTexts = {
    "Hazır Metin 1: Hızlı Okuma Kas Egzersizi": "Hızlı okuma, göz kaslarını yatay ve dikey açılarda geliştirerek kelime gruplarını tek seferde algılama sanatıdır. RSVP sistemi kelimeleri tek bir merkez çizgide yakalayarak dikkat dağınıklığını tamamen ortadan kaldırır."
  };

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    await BookDatabase.instance.loadDefaultAssets();
    try {
      final String teknikler = await rootBundle.loadString('assets/Okuma_Teknikleri.txt');
      _presetTexts["Hazır Metin 2: Anlayarak Hızlı Okuma Teknikleri"] = teknikler;
    } catch (e) {
      debugPrint("Hazır metin 2 yüklenemedi: $e");
    }
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
    int chosenMode = ThemeManager.instance.savedReaderMode;
    BookModel? selectedBook;

    if (BookDatabase.instance.getBooks().isNotEmpty) {
      try {
        selectedBook = BookDatabase.instance.getBooks().firstWhere((b) => b.id == ThemeManager.instance.savedBookId);
      } catch (_) {
        selectedBook = BookDatabase.instance.getBooks().first;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) => StatefulBuilder(
            builder: (context, setWizardState) => SafeArea(
              bottom: true,
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📖 Kitap Okuma Sihirbazı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    const Text('1. Okuma Modunu Seçin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                    const SizedBox(height: 20),
                    const Text('2. Kütüphanenizden Kitap Seçin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    BookDatabase.instance.getBooks().isEmpty
                        ? const Center(child: Text('Kitaplığınız boş. Lütfen menüden içe aktarın.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: BookDatabase.instance.getBooks().length,
                            itemBuilder: (context, idx) {
                              final book = BookDatabase.instance.getBooks()[idx];
                              bool isSelected = selectedBook?.id == book.id;
                              return Card(
                                elevation: isSelected ? 4 : 1,
                                color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                                child: ListTile(
                                  dense: true,
                                  title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  subtitle: Text('Sayfa: ${book.totalPages} | Kalınan: ${book.lastPage + 1}'),
                                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                                  onTap: () {
                                    setWizardState(() => selectedBook = book);
                                  },
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: selectedBook == null ? null : () {
                          ThemeManager.instance.saveReaderWizardSettings(chosenMode, selectedBook!.id);
                          Navigator.pop(context);
                          selectedBook!.savedMode = chosenMode;
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ReaderScreen(rawText: selectedBook!.content, activeBook: selectedBook!))).then((_) => setState(() {}));
                        },
                        child: const Text('Okumaya Başla', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startAdvancedExerciseWizard() {
    int chosenExercise = ThemeManager.instance.savedAdvancedMode;
    int chosenSourceType = ThemeManager.instance.savedSourceType;
    BookModel? selectedBook;

    if (BookDatabase.instance.getBooks().isNotEmpty) {
      try {
        selectedBook = BookDatabase.instance.getBooks().firstWhere((b) => b.id == ThemeManager.instance.savedBookId);
      } catch (_) {
        selectedBook = BookDatabase.instance.getBooks().first;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) => StatefulBuilder(
            builder: (context, setWizardState) => SafeArea(
              bottom: true,
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎯 Gelişmiş Egzersiz Kurulumu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    const Text('1. Egzersiz Türü Seçin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    DropdownButton<int>(
                      value: chosenExercise,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Mod 1: Blok Okuma')),
                        DropdownMenuItem(value: 2, child: Text('Mod 2: Gölgeleme (Aktif Blok)')),
                        DropdownMenuItem(value: 3, child: Text('Mod 3: Gruplama (Aktif Açık)')),
                        DropdownMenuItem(value: 4, child: Text('Mod 4: Takistoskop (Klavye)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setWizardState(() => chosenExercise = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('2. Metin Kaynağını Seçin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    DropdownButton<int>(
                      value: chosenSourceType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Kaynak: Ekrandaki Serbest Metnim')),
                        DropdownMenuItem(value: 2, child: Text('Kaynak: Hazır Egzersiz Metinleri')),
                        DropdownMenuItem(value: 3, child: Text('Kaynak: Kütüphanemdeki Bir Kitap')),
                      ],
                      onChanged: (val) {
                        if (val != null) setWizardState(() {
                          chosenSourceType = val;
                          if (val == 3 && BookDatabase.instance.getBooks().isNotEmpty) {
                            selectedBook ??= BookDatabase.instance.getBooks().first;
                          }
                        });
                      },
                    ),
                    if (chosenSourceType == 3) ...[
                      const SizedBox(height: 20),
                      const Text('3. Kütüphane Kitabı Seçin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      BookDatabase.instance.getBooks().isEmpty
                        ? const Text('Kütüphaneniz boş.', style: TextStyle(color: Colors.red))
                        : DropdownButton<BookModel>(
                            value: selectedBook,
                            isExpanded: true,
                            items: BookDatabase.instance.getBooks().map((b) => DropdownMenuItem(value: b, child: Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) {
                              if (val != null) setWizardState(() => selectedBook = val);
                            },
                          )
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          ThemeManager.instance.saveAdvancedWizardSettings(chosenExercise, chosenSourceType, selectedBook?.id ?? "");
                          Navigator.pop(context);
                          String exerciseText = "";
                          
                          if (chosenSourceType == 1) {
                            exerciseText = _textController.text.isNotEmpty ? _textController.text : "Önce ana ekrana bir metin yapıştırın.";
                          } else if (chosenSourceType == 2) {
                            exerciseText = _presetTexts.values.join(" "); 
                          } else if (chosenSourceType == 3 && selectedBook != null) {
                            exerciseText = selectedBook!.content;
                          }

                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => AdvancedExerciseScreen(
                              rawText: exerciseText,
                              initialExerciseType: chosenExercise, 
                              activeBook: chosenSourceType == 3 ? selectedBook : null,
                            )
                          )).then((_) => setState(() {}));
                        },
                        child: const Text('Egzersize Başla', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayBuild = _buildNumber.contains("PLACEHOLDER") ? "96" : _buildNumber;
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
          bottom: true,
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
                          subtitle: const Text('EPUB, TXT, DOCX Cihazdan Seç'),
                          onTap: () async {
                            Navigator.pop(context); 
                            final bool? success = await Navigator.push(context, MaterialPageRoute(builder: (context) => const FilePickerScreen()));
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
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Göz ve Algı Egzersizleri (Yeni)', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Card(
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.psychology, color: Colors.deepPurpleAccent, size: 32),
                  title: const Text('Gelişmiş Egzersizler Modülü', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Takistoskop, Blok, Gölgeleme ve Gruplama çalışmaları.'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _startAdvancedExerciseWizard,
                ),
              ),
              const SizedBox(height: 16),
              
              Text('2. Hazır Egzersizler', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
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
                      onTap: () {
                        _textController.text = _presetTexts[title]!;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Metin serbest eğitim alanına kopyalandı!')));
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              Text('3. İnternetten Metin Çek', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: TextField(controller: _urlController, decoration: const InputDecoration(hintText: 'https://makale-linki...'))),
                  IconButton(icon: const Icon(Icons.cloud_download, color: Colors.blue), onPressed: () => _fetchTextFromUrl(_urlController.text)),
                ],
              ),
              const SizedBox(height: 16),
              
              Text('4. Serbest Eğitim Alanı', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(controller: _textController, maxLines: 5, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Metni buraya yapıştırın...')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.menu_book, color: Colors.white),
                  label: const Text('Kitap Okuma Moduyla Başlat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
      ),
    );
  }
}
