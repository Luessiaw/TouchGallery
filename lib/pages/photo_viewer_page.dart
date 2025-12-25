import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class PhotoViewerPage extends StatefulWidget {
  final List<AssetEntity> photos;
  final int initialIndex;

  const PhotoViewerPage({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late final PageController _controller;
  late final TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (_) {
          _transformationController.value = Matrix4.identity();
        },
        itemBuilder: (context, index) {
          final asset = widget.photos[index];
          return GestureDetector(
            onDoubleTapDown: (details) {
              _doubleTapDetails = details;
            },
            onDoubleTap: () {
              final position = _doubleTapDetails!.localPosition;

              final currentScale = _transformationController.value
                  .getMaxScaleOnAxis();

              if (currentScale > 1.0) {
                _transformationController.value = Matrix4.identity();
              } else {
                _transformationController.value = Matrix4.identity()
                  ..translateByDouble(
                    -position.dx * 1.5,
                    -position.dy * 1.5,
                    0.0,
                    1.0,
                  )
                  ..scaleByDouble(3.0, 3.0, 1.0, 1.0);
              }
            },
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: AssetEntityImage(
                  asset,
                  isOriginal: false,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
