import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';  // Firebase Core import edildi
import 'package:edumaster/pages/homeScreen.dart';
import 'package:edumaster/pages/loginScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Firebase başlatılıyor
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduMaster',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _getLandingPage(),
    );
  }

  Widget _getLandingPage() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Eğer kullanıcı oturum açmışsa ana ekrana yönlendir
      return HomeScreen();
    } else {
      // Eğer kullanıcı oturum açmamışsa giriş ekranına yönlendir
      return LoginScreen();
    }
  }
}
