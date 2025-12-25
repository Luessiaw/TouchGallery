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

  double _dragOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
    _visiblePhotos = List.of(widget.photos);
  }

  void _deleteCurrentPhoto() {
    if (_currentIndex < 0 || _currentIndex >= _visiblePhotos.length) return;

    final asset = _visiblePhotos[_currentIndex];

    setState(() {
      _deletedStack.add(_DeletedPhoto(asset, _currentIndex));
      _visiblePhotos.removeAt(_currentIndex);
      debugPrint("删除的照片 id：$_currentIndex");
      debugPrint(
        "当前相册长度：${_visiblePhotos.length}, 已删除照片数量：${_deletedStack.length}",
      );

      if (_currentIndex >= _visiblePhotos.length) {
        _currentIndex = _visiblePhotos.length - 1;
      }
    });
  }

  void _undoDelete() {
    if (_deletedStack.isEmpty) return;

    final last = _deletedStack.removeLast();

    setState(() {
      _visiblePhotos.insert(last.index, last.photo);
      _currentIndex = last.index;
      debugPrint("撤销删除的照片 id：${last.index}");
      debugPrint(
        "当前相册长度：${_visiblePhotos.length}, 已删除照片数量：${_deletedStack.length}",
      );
    });

    // 等待一帧，确保 PageView 已更新 itemCount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.jumpToPage(last.index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _visiblePhotos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _transformationController.value = Matrix4.identity();
                debugPrint("当前查看的照片 id：$index");
                debugPrint(
                  "当前相册长度：${_visiblePhotos.length}, 已删除照片数量：${_deletedStack.length}",
                );
              });
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
                  const deleteThreshold = -150;

                  if (_dragOffsetY < deleteThreshold) {
                    _dragOffsetY = 0;
                    _deleteCurrentPhoto();
                  } else {
                    setState(() {
                      _dragOffsetY = 0;
                    });
                  }
                  // if (details.primaryVelocity != null &&
                  //     details.primaryVelocity! < -300) {
                  //   _deleteCurrentPhoto();
                  // }
                },
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _dragOffsetY += details.delta.dy;
                    // 只允许向上拖（负值）
                    if (_dragOffsetY > 0) {
                      _dragOffsetY = 0;
                    }
                  });
                },
                child: Transform.translate(
                  offset: Offset(0, _dragOffsetY),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    // transform: Matrix4.translationValues(0, 0, 0),
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
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _dragOffsetY < -50 ? 0.8 : 0.0,
              child: Container(
                color: const Color.fromARGB(255, 132, 31, 23).withValues(),
                child: const Center(
                  child: Icon(Icons.delete, color: Colors.white, size: 36),
                ),
              ),
            ),
          ),
          // ===== 撤销删除按钮 =====
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.undo),
              color: Colors.white,
              onPressed: _deletedStack.isEmpty ? null : _undoDelete,
              tooltip: '撤销删除',
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletedPhoto {
  final AssetEntity photo;
  final int index;

  _DeletedPhoto(this.photo, this.index);
}
