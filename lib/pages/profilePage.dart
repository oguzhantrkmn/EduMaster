import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edumaster/pages/loginScreen.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _saveThemePreference(bool isDarkMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDarkMode);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && _imageFile != null) {
      try {
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child(user.uid + '.jpg');
        UploadTask uploadTask = storageRef.putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadURL = await snapshot.ref.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profileImageURL': downloadURL});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil resmi güncellendi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim yüklenemedi: $e')),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Uygulamadan çıkmak istiyor musunuz?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Hayır'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Evet'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profil'),
          backgroundColor: Color(0xFFF4F1FF),
        ),
        body: Center(
          child: Text(
            'Kullanıcı bilgileri bulunamadı. Lütfen giriş yapın.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Profil'),
          backgroundColor: Color(0xFFF4F1FF),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.brightness_7 : Icons.brightness_2),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
                _saveThemePreference(_isDarkMode);
                _applyTheme(_isDarkMode);
              },
            ),
          ],
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Bir hata oluştu'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('Kullanıcı bilgileri bulunamadı'));
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            String? profileImageUrl = userData['profileImageURL'];

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blueAccent,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: profileImageUrl == null
                              ? Text(
                                  userData['name'] != null
                                      ? userData['name']
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : '',
                                  style: TextStyle(
                                      fontSize: 40, color: Colors.white),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.grey[200],
                              child: Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      userData['name'] ?? 'Ad Soyad bilgisi yok',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      user.email ?? 'E-posta bilgisi yok',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 30),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 5,
                      child: ListTile(
                        leading: Icon(Icons.location_city),
                        title: Text('Şehir'),
                        subtitle: Text(userData['city'] ?? 'Şehir bilgisi yok'),
                      ),
                    ),
                    SizedBox(height: 10),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 5,
                      child: ListTile(
                        leading: Icon(Icons.calendar_today),
                        title: Text('Doğum Tarihi'),
                        subtitle: Text(userData['birthDate'] ?? 'Doğum tarihi bilgisi yok'),
                      ),
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      child: Text('Çıkış Yap'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _applyTheme(bool isDarkMode) {
    ThemeMode themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    MyApp.of(context).setThemeMode(themeMode); // Tema modunu uygula
  }
}

class MyApp extends StatefulWidget {
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void setThemeMode(ThemeMode themeMode) {
    if (_themeMode != themeMode) {
      setState(() {
        _themeMode = themeMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduMaster',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode, // Dinamik tema modu
      home: ProfilePage(),
    );
  }
}
