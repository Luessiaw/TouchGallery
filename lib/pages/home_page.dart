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

class PhotoTile extends StatefulWidget {
  final int index;

  const PhotoTile({super.key, required this.index});

  @override
  State<PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<PhotoTile> {
  double _dragOffsetY = 0.0;
  static const double _deleteThreshold = -80.0;

  @override
  Widget build(BuildContext context) {
    final bool isDeleting = _dragOffsetY < _deleteThreshold;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffsetY += details.delta.dy;
          if (_dragOffsetY > 0) _dragOffsetY = 0; // 只允许上滑
        });
      },
      onVerticalDragEnd: (_) {
        if (_dragOffsetY < _deleteThreshold) {
          debugPrint('Request delete photo ${widget.index}');
        }
        setState(() {
          _dragOffsetY = 0;
        });
      },
      child: Stack(
        children: [
          // 背景：删除提示
          Container(
            color: Colors.red.shade400,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            child: const Icon(Icons.delete, color: Colors.white),
          ),

          // 前景：照片本体
          Transform.translate(
            offset: Offset(0, _dragOffsetY),
            child: Container(
              color: isDeleting ? Colors.red.shade200 : Colors.grey.shade300,
              child: Center(
                child: Text(
                  '${widget.index}',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
