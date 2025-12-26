import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class PhotoViewerPage extends StatefulWidget {
  final List<AssetEntity> photos;
  final int initialIndex;
  final AssetPathEntity currentAlbum;
  final List<AssetPathEntity> allAlbums;

  const PhotoViewerPage({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.currentAlbum,
    required this.allAlbums,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage>
    with SingleTickerProviderStateMixin {
  late final PageController _controller;
  late final TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;
  int _currentIndex = 0;

  late List<AssetEntity> _visiblePhotos; // 当前可浏览照片
  final List<_DeletedPhoto> _deletedStack = [];
  final List<_MovedPhoto> _movedStack = [];

  double _dragOffsetY = 0.0;

  late AnimationController _deleteAnimController;
  // late Animation<double> _deleteAnim;

  bool _isDeleting = false;

  bool get _isZoomed =>
      _transformationController.value.getMaxScaleOnAxis() > 1.01;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
    _visiblePhotos = List.of(widget.photos);

    _deleteAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // _deleteAnim =
    //     Tween<double>(
    //       begin: 0.0,
    //       end: -1.0, // 向上飞出
    //     ).animate(
    //       CurvedAnimation(parent: _deleteAnimController, curve: Curves.easeIn),
    //     );

    _deleteAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _deleteAnimController.reset();
        _isDeleting = false;
        _deleteCurrentPhoto();
      }
    });
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

  void _moveCurrentPhotoToAlbum(AssetPathEntity targetAlbum) {
    if (_currentIndex < 0 || _currentIndex >= _visiblePhotos.length) return;

    final photo = _visiblePhotos[_currentIndex];

    setState(() {
      _movedStack.add(_MovedPhoto(photo, targetAlbum, _currentIndex));

      _visiblePhotos.removeAt(_currentIndex);

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
  void dispose() {
    _deleteAnimController.dispose();
    _controller.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _applyChanges() {
    // Step 1：仅占位
    debugPrint('点击了应用按钮。');

    // 后续 Step 中会在这里：
    // - 提交删除列表
    // - pop 回 PhotoGridPage
    // - 返回结果
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('照片查看'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: '应用更改',
            onPressed: _applyChanges,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _visiblePhotos.length,
            physics: _isZoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
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
              final deleteOffset = (_isDeleting && index == _currentIndex)
                  ? _deleteAnimController.value *
                        MediaQuery.of(context).size.height
                  : 0.0;
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
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
                onVerticalDragEnd: _isZoomed
                    ? null
                    : (details) {
                        const deleteThreshold = -150;

                        if (_isDeleting) return;

                        if (_dragOffsetY < deleteThreshold) {
                          _dragOffsetY = 0;
                          setState(() {
                            _isDeleting = true;
                          });
                          _deleteAnimController.forward();
                        } else {
                          setState(() {
                            _dragOffsetY = 0;
                          });
                        }
                      },
                onVerticalDragUpdate: _isZoomed
                    ? null
                    : (details) {
                        setState(() {
                          _dragOffsetY += details.delta.dy;
                          // 只允许向上拖（负值）
                          if (_dragOffsetY > 0) {
                            _dragOffsetY = 0;
                          }
                        });
                      },
                child: Transform.translate(
                  offset: Offset(0, _dragOffsetY + deleteOffset),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    // transform: Matrix4.translationValues(0, 0, 0),
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      panEnabled: true,
                      scaleEnabled: true,
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
      bottomNavigationBar: _buildAlbumActionBar(),
    );
  }

  Widget _buildAlbumActionBar() {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: widget.allAlbums.length + 1,
        itemBuilder: (context, index) {
          if (index == widget.allAlbums.length) {
            // 新建相册占位
            return _buildCreateAlbumButton();
          }

          final album = widget.allAlbums[index];
          final isCurrent = album.id == widget.currentAlbum.id;

          return _buildAlbumButton(album: album, disabled: isCurrent);
        },
      ),
    );
  }

  Widget _buildAlbumButton({
    required AssetPathEntity album,
    required bool disabled,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_downward,
            color: disabled ? Colors.grey : Colors.white,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: disabled ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAlbumButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () {
          debugPrint('新建相册（占位）');
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Colors.white),
            SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                '新建',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeletedPhoto {
  final AssetEntity photo;
  final int index;

  _DeletedPhoto(this.photo, this.index);
}

class _MovedPhoto {
  final AssetEntity photo;
  final AssetPathEntity targetAlbum;
  final int originalIndex;

  _MovedPhoto(this.photo, this.targetAlbum, this.originalIndex);
}
