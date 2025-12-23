import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const PhotoManagerApp());
}

class PhotoManagerApp extends StatelessWidget {
  const PhotoManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}
