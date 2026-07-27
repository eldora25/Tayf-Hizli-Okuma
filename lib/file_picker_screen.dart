import 'package:flutter/material.dart';
import 'book_database.dart';

class FilePickerScreen extends StatefulWidget {
  const FilePickerScreen({super.key});

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  // Simüle edilmiş kısıtlamasız yerel Android depolama ağacı
  final Map<String, List<Map<String, String>>> _deviceStorage = {
    "/Cihaz Hafızası/Downloads": [
      {"title": "Suc_ve_Ceza_Bolum1.epub", "format": "EPUB", "content": "Raskolnikov sıcak bir Temmuz ayında tavan arasındaki odasından çıktı. Hızlı okuma odaklanma çizgisine odaklanın. İkinci sayfa akışı burada devam ediyor. Üçüncü sayfa egzersiz tamamlandı."},
      {"title": "Modern_Hizli_Okuma.pdf", "format": "PDF", "content": "Göz okuma hızı beyin algılama limitleriyle doğrudan ilişkilidir. Kelimeleri blok halinde görün. İkinci aşama göz kası antrenmanıdır."},
      {"title": "Ders_Notlari.docx", "format": "WORD", "content": "Hızlı okuma sınav hazırlık notları. Birinci madde: Seslendirmeyi bırak. İkinci madde: RSVP motorunu aktif kullan."}
    ],
    "/Cihaz Hafızası/Documents": [
      {"title": "Nutuk_Tam_Metin.txt", "format": "TXT", "content": "1919 senesi Mayısının 19 uncu günü Samsuna çıktım. Vaziyet ve manzara-i umumiye: Osmanlı Devletinin dahil bulunduğu grup Harb-i Umumide mağlup olmuştu."},
      {"title": "Egitim_Rehberi.epub", "format": "EPUB", "content": "Eğitim modülü birinci aşama başlangıcı. RSVP okuma tekniğinin faydaları göz koordinasyonunu maksimum düzeye çıkarır."}
    ],
    "/Cihaz Hafızası/Books": [
      {"title": "Zamanin_Kisa_Tarihi.epub", "format": "EPUB", "content": "Evrenin yapısı ve zamanın akışı üzerine bilimsel makaleler topluluğu hızlı okuma entegre metni."}
    ]
  };

  String _currentFolder = "/Cihaz Hafızası/Downloads";
  final List<Map<String, String>> _temporarySelectionPool = [];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çoklu Dosya İçe Aktar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Android Depolama Dizinleri:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Klasörler arası geçiş çubuğu
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _deviceStorage.keys.map((folderPath) {
                  bool isCurrent = _currentFolder == folderPath;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(folderPath.split('/').last),
                      selected: isCurrent,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _currentFolder = folderPath;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 24),
            Text(
              '$_currentFolder İçeriği:',
              style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            // Dosya Listesi
            Expanded(
              child: ListView.builder(
                itemCount: _deviceStorage[_currentFolder]!.length,
                itemBuilder: (context, idx) {
                  final file = _deviceStorage[_currentFolder]![idx];
                  bool isSelected = _temporarySelectionPool.contains(file);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: CheckboxListTile(
                      title: Text(file['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('Format: ${file['format']}'),
                      secondary: Icon(Icons.description, color: colorScheme.primary),
                      value: isSelected,
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _temporarySelectionPool.add(file);
                          } else {
                            _temporarySelectionPool.remove(file);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            // Alt Bilgi ve Onay Butonu
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seçilen Kitap Sayısı: ${_temporarySelectionPool.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Kitaplığa Aktar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    onPressed: _temporarySelectionPool.isEmpty
                        ? null
                        : () {
                            BookDatabase.instance.addMultipleBooks(List.from(_temporarySelectionPool));
                            Navigator.pop(context, true); // Başarılı flag'i ile dön
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
