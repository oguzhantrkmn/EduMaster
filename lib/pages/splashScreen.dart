import 'package:edumaster/pages/backgrounds.dart';
import 'package:edumaster/pages/loginScreen.dart';
import 'package:flutter/material.dart';
 // LoginScreen'i içe aktar

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    // 3 saniye sonra login sayfasına yönlendirme
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen()), // LoginScreen'e yönlendirme
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: Backgrounds.getRandomBackground(),
            fit: BoxFit.cover, // Resmi tüm ekranı kaplayacak şekilde ayarla
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _animation,
            child: Opacity(
              opacity: 1,
              child: Image.asset('assets/images/logo.png'),
            ),
          ),
        ),
      ),
    );
  }
}