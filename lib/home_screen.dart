import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;

  // Uygulama içerisindeki hazır eğitim metinleri
  final Map<String, String> _presetTexts = {
    "Hızlı Okuma Nedir?": "Hızlı okuma, göz kaslarını geliştirerek ve kelimeleri tek tek değil gruplar halinde görerek okuma hızını artırma tekniğidir. İnsan beyni kelimeleri resim gibi algılar. Bu sayede odaklanma artar ve zamandan tasarruf edilir.",
    "Odaklanma Egzersizi": "Gözlerimiz okuma yaparken sürekli geriye sıçrama eğilimindedir. RSVP tekniği kelimeleri tek bir noktada göstererek bu sıçramaları engeller. Böylece dikkat dağınıklığı minimuma iner ve algılama hızı maksimuma çıkar.",
  };

  // URL üzerinden ham metin çekme fonksiyonu
  Future<void> _fetchTextFromUrl(String url) async {
    if (url.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Basitçe HTML etiketlerinden arındırma simülasyonu
        String cleanText = response.body
            .replaceAll(RegExp(r'<[^>]*>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ');
        setState(() {
          _textController.text = cleanText;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bağlantı başarıyla yüklendi!')),
        );
      } else {
        throw Exception('Veri çekilemedi.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: Bağlantı okunamadı ($e)')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tayf Hızlı Okuma Paneli'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KAYNAK: HAZIR METİNLER
            Text('1. Hazır Eğitim Metinleri', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _presetTexts.length,
                itemBuilder: (context, index) {
                  String title = _presetTexts.keys.elementAt(index);
                  return ListTile(
                    title: Text(title),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _textController.text = _presetTexts[title]!;
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 2. KAYNAK: BAĞLANTI (URL) ÜZERİNDEN METİN ALMA
            Text('2. İnternet Bağlantısından Metin Çek', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'https://example.com/article',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () => _fetchTextFromUrl(_urlController.text),
                        child: const Text('Getir'),
                      ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. KAYNAK: DOSYA VEYA MANUEL YAPIŞTIRMA ALANI
            Text('3. Okunacak Metin Alanı (Dosya / Yapıştır)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Metninizi buraya yapıştırın veya yukarıdaki kaynakları kullanın...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // ÇALIŞMAYI BAŞLATMA BUTONU
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Okuma Egzersizini Başlat', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
                onPressed: () {
                  if (_textController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen önce bir metin ekleyin!')),
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
