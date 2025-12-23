import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Manager')),
      body: const Center(
        child: Text('Hello, Photo Manager', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
