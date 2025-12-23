import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const int _mockPhotoCount = 60;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Manager')),
      body: GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 每行 3 张
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _mockPhotoCount,
        itemBuilder: (context, index) {
          return PhotoTile(index: index);
        },
      ),
    );
  }
}

class PhotoTile extends StatelessWidget {
  final int index;

  const PhotoTile({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        debugPrint('Tapped photo $index');
      },
      child: Container(
        color: Colors.grey.shade300,
        child: Center(
          child: Text(
            '$index',
            style: const TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
