import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<String> _notes = [];
  List<String> _filePaths = [];
  List<String> _urls = []; // URL'leri saklayacağımız liste

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      String fileName = result.files.single.name;

      setState(() {
        _notes.add(fileName);
        _filePaths.add(filePath);
        _urls.add(''); // URL yer tutucusu
      });

      // Dosyayı uygulamanın depolamasına kopyalama
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File savedFile = File('${appDocDir.path}/$fileName');
      await File(filePath).copy(savedFile.path);
      _filePaths[_filePaths.length - 1] = savedFile.path; // Yolu güncelle

      print('Dosya yolu: $savedFile.path'); // Dosya yolunu yazdır
    }
  }

  Future<void> _uploadFile(int index) async {
    String filePath = _filePaths[index];
    File file = File(filePath);

    try {
      String fileName = filePath.split('/').last;
      Reference ref = FirebaseStorage.instance.ref().child('notes/$fileName');
      UploadTask uploadTask = ref.putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();

      // Firebase'den indirilen dosyayı cihaza kaydetme
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String savedFilePath = '${appDocDir.path}/$fileName';
      Dio dio = Dio();
      await dio.download(downloadURL, savedFilePath);

      // Dosyanın gerçekten var olup olmadığını kontrol edin
      bool fileExists = File(savedFilePath).existsSync();
      print('Saved File Path: $savedFilePath');
      print('File exists: $fileExists');

      setState(() {
        _filePaths[index] = savedFilePath; // Dosya yolunu güncelle
        _urls[index] = downloadURL; // URL'yi sakla
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL oluşturuldu ve kopyalandı')),
      );

      Clipboard.setData(ClipboardData(text: downloadURL)); // URL'yi kopyala
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL oluşturulamadı: $e')),
      );
    }
  }

  Future<void> _deleteFile(int index) async {
    setState(() {
      _notes.removeAt(index);
      _filePaths.removeAt(index);
      _urls.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dosya silindi')),
    );
  }

  Future<void> _downloadFileFromUrl(String url) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String fileName = url.split('/').last;
      String filePath = '${appDocDir.path}/$fileName';

      Dio dio = Dio();
      await dio.download(url, filePath);

      setState(() {
        _notes.add(fileName);
        _filePaths.add(filePath);
        _urls.add(''); // Yeni indirilen dosya için yer tutucu URL
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya indirildi: $fileName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya indirilemedi: $e')),
      );
    }
  }

  Future<void> _showUrlDialog() async {
    TextEditingController urlController = TextEditingController();
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('URL ile dosya ekle'),
          content: TextField(
            controller: urlController,
            decoration: InputDecoration(hintText: "Dosya URL'sini buraya yapıştırın"),
          ),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Aktar'),
              onPressed: () {
                Navigator.of(context).pop();
                _downloadFileFromUrl(urlController.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUploadOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.file_upload),
                title: Text('Dışarıdan Aktar'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showUrlDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.file_open),
                title: Text('İçeriden Aktar'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilePreview(String filePath) {
    String fileExtension = filePath.split('.').last.toLowerCase();
    print('File Path: $filePath'); // Dosya yolunu yazdır
    print('File Extension: $fileExtension'); // Dosya uzantısını yazdır

    if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
      return Image.file(
        File(filePath),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    } else if (fileExtension == 'pdf') {
      return Icon(Icons.picture_as_pdf, size: 100);  // PDF dosyaları için genel bir simge
    } else {
      return Icon(Icons.insert_drive_file, size: 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notlar'),
        backgroundColor: Color(0xFFF4F1FF),
      ),
      body: _notes.isEmpty
          ? Center(
              child: Text(
                'Henüz bir not eklenmedi',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: _buildFilePreview(_filePaths[index]),
                  title: Text(_notes[index]),
                  onTap: () {
                    OpenFile.open(_filePaths[index]);
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_urls[index].isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _urls[index]));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('URL kopyalandı')),
                            );
                          },
                          child: Icon(Icons.copy, color: Colors.blue),
                        ),
                      PopupMenuButton<String>(
                        onSelected: (String value) {
                          if (value == 'Link Oluştur') {
                            _uploadFile(index);
                          } else if (value == 'Sil') {
                            _deleteFile(index);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: 'Link Oluştur',
                            child: Text('Link Oluştur'),
                          ),
                          PopupMenuItem(
                            value: 'Sil',
                            child: Text('Sil'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadOptions,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
