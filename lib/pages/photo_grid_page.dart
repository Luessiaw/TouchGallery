import 'package:flutter/material.dart';
import 'photo_viewer_page.dart';

class PhotoGridPage extends StatelessWidget {
  final String title;

  const PhotoGridPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: 30,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoViewerPage(index: index),
                ),
              );
            },
            child: Container(
              color: Colors.grey.shade400,
              child: Center(child: Text('$index')),
            ),
          );
        },
      ),
    );
  }
}
