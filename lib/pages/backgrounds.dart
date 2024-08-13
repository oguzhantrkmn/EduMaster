import 'dart:math';
import 'package:flutter/material.dart';

class Backgrounds {
  static final List<String> _images = [
    'assets/images/bg_1.jpg',
    'assets/images/bg_2.jpg',
    'assets/images/bg_4.jpg',
    'assets/images/bg_5.jpg',
    'assets/images/bg_6.jpg',
    'assets/images/bg_7.jpg',
    'assets/images/bg_8.jpg',
    'assets/images/bg_9.jpg',
    'assets/images/bg_10.jpg',
    
    
    // Diğer resimlerinizin yollarını buraya ekleyebilirsiniz.
  ];

  static ImageProvider getRandomBackground() {
    final random = Random();
    int index = random.nextInt(_images.length);
    return AssetImage(_images[index]);
  }
}
