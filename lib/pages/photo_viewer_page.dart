import 'package:flutter/material.dart';

class PhotoViewerPage extends StatelessWidget {
  final int index;

  const PhotoViewerPage({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('照片 $index')),
      body: Center(
        child: Text('这里是照片 $index', style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
