import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoGridPage extends StatelessWidget {
  final String title;
  final AssetPathEntity album;

  const PhotoGridPage({super.key, required this.title, required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('下一步加载真实照片')),
    );
  }
}
