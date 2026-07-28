import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'book_database.dart';

class FilePickerScreen extends StatefulWidget {
  const FilePickerScreen({Key? key}) : super(key: key);

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  final List<Map<String, dynamic>> _pickedFilesResult = [];
  bool _isSaving = false;

  Future<void> _pickRealFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'txt', 'docx'], // DOCX uzantısı eklendi
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (file.bytes != null) {
              _pickedFilesResult.add({
                'title': file.name,
                'format': file.extension?.toUpperCase() ?? 'BİLİNMİYOR',
                'bytes': file.bytes!,
              });
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Dosya seçilemedi: $e')),
        );
      }
    }
  }

  Future<void> _handleSaveBooks() async {
    if (_pickedFilesResult.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce yüklenecek bir kitap seçin.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await BookDatabase.instance.addMultipleBooks(List.from(_pickedFilesResult));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kitaplar başarıyla kütüphaneye eklendi.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yükleme sırasında hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap İçe Aktar'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickRealFiles,
                    icon: const Icon(Icons.file_open),
                    label: const Text('Cihazdan Kitap Seç (EPUB / TXT / DOCX)'), // UI Güncellendi
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _pickedFilesResult.isEmpty
                        ? const Center(child: Text('Henüz dosya seçilmedi.'))
                        : ListView.builder(
                            itemCount: _pickedFilesResult.length,
                            itemBuilder: (context, index) {
                              final file = _pickedFilesResult[index];
                              return ListTile(
                                leading: const Icon(Icons.book),
                                title: Text(file['title'] ?? ''),
                                subtitle: Text(file['format'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _pickedFilesResult.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _handleSaveBooks,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Kitabı Uygulamaya Yükle'),
                  ),
                ],
              ),
            ),
    );
  }
}
