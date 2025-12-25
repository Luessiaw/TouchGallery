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
  int _currentIndex = 0;

  late List<AssetEntity> _visiblePhotos; // 当前可浏览照片
  final List<_DeletedPhoto> _deletedStack = [];

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
    _visiblePhotos = List.of(widget.photos);
  }

  void _deleteCurrentPhoto() {
    debugPrint("删除照片");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _controller,
        itemCount: _visiblePhotos.length,
        onPageChanged: (index) {
          _currentIndex = index;
          _transformationController.value = Matrix4.identity();
        },
        itemBuilder: (context, index) {
          final asset = _visiblePhotos[index];
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
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < -300) {
                _deleteCurrentPhoto();
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

class _DeletedPhoto {
  final AssetEntity photo;
  final int index;

  _DeletedPhoto(this.photo, this.index);
}
