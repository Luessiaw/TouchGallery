import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
// import 'package:flutter_media_delete/flutter_media_delete.dart';
// import 'dart:io';

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
  int _currentPageIndex = 0;

  final List<_Photo> _photos = [];
  late List<_Photo> _visiblePhotos = []; // 当前可浏览照片
  final List<_Photo> _changedPhotos = [];

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
    debugPrint("@@初始化，当前index: ${widget.initialIndex}");
    _currentPageIndex = widget.initialIndex;
    _transformationController = TransformationController();
    // _visiblePhotos = List.of(widget.photos);
    for (var i = 0; i < widget.photos.length; i++) {
      int? lastIndex = (i == 0) ? null : (i - 1);
      int? nextIndex = (i == widget.photos.length - 1) ? null : (i + 1);
      _photos.add(
        _Photo(widget.photos[i], widget.currentAlbum, i, lastIndex, nextIndex),
      );
    }
    _visiblePhotos = getVisiblePhotos(_photos);

    _deleteAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _deleteAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _deleteAnimController.reset();
        _isDeleting = false;
        _deletePhoto();
      }
    });
  }

  List<_Photo> getVisiblePhotos(List<_Photo> photos) {
    // 用 Map 快速根据 index 查找 Photo
    final Map<int, _Photo> photoMap = {for (var p in photos) p.index: p};

    // 找到链表的头结点：lastIndex == null 或者链表中没有对应 lastIndex 的
    _Photo? head = photos.firstWhere(
      (p) => p.lastIndex == null,
      orElse: () => photos.first,
    );

    List<_Photo> visible = [];
    _Photo? current = head;
    while (current != null) {
      visible.add(current);
      if (current.nextIndex != null) {
        current = photoMap[current.nextIndex!];
      } else {
        break;
      }
    }
    return visible;
  }

  void _deletePhoto() {
    if (_currentPageIndex < 0 || _currentPageIndex >= _visiblePhotos.length) {
      return;
    }

    setState(() {
      _Photo photo = _popPhoto();
      photo.state = 1;
      debugPrint("@@照片已标记为：删除。");
    });
  }

  void _movePhoto(AssetPathEntity album) {
    if (_currentPageIndex < 0 || _currentPageIndex >= _visiblePhotos.length) {
      return;
    }

    setState(() {
      _Photo photo = _popPhoto();
      photo.state = 2;
      photo.targetAlbum = album;
      debugPrint("@@照片已标记为：移动。target album: ${album.name}");
    });
  }

  _Photo _popPhoto() {
    final photo = _visiblePhotos[_currentPageIndex];
    int? lastIndex = photo.lastIndex;
    int? nextIndex = photo.nextIndex;
    _changedPhotos.add(photo);

    while ((lastIndex != null) && (_photos[lastIndex].state == 3)) {
      lastIndex = _photos[lastIndex].lastIndex;
    }
    while ((nextIndex != null) && (_photos[nextIndex].state == 3)) {
      nextIndex = _photos[nextIndex].nextIndex;
    }

    if (lastIndex != null) {
      _photos[lastIndex].nextIndex = nextIndex;
    }
    if (nextIndex != null) {
      _photos[nextIndex].lastIndex = lastIndex;
    }
    photo.pageIndex = _currentPageIndex;
    _visiblePhotos.removeAt(_currentPageIndex);

    if (_currentPageIndex >= _visiblePhotos.length) {
      _currentPageIndex = _visiblePhotos.length - 1;
    }

    debugPrint(
      "@@照片信息：index=${photo.index}, lastIndex=$lastIndex, nextIdex=$nextIndex, pageIndex=$_currentPageIndex",
    );
    return photo;
  }

  void _recoverPhoto(_Photo photo) {
    final lastIndex = photo.lastIndex;
    final nextIndex = photo.nextIndex;
    final pageIndex = photo.pageIndex;
    final index = photo.index;
    _visiblePhotos.insert(pageIndex ?? 0, photo);

    if (lastIndex != null) {
      _photos[lastIndex].nextIndex = index;
    }
    if (nextIndex != null) {
      _photos[nextIndex].lastIndex = index;
    }
    _currentPageIndex = pageIndex ?? 0;
    photo.state = 0;
    photo.pageIndex = null;

    if (photo.state == 1) {
      debugPrint("@@恢复标记为删除的照片。");
    } else if (photo.state == 2) {
      debugPrint("@@恢复标记为移动的照片。target album: ${photo.targetAlbum?.name}.");
      photo.targetAlbum = null;
    } else {
      debugPrint("@@照片 ${photo.index} 的状态为未修改！");
      return;
    }
    debugPrint(
      "@@恢复照片。index=$index, lastIndex=$lastIndex, nextIndex=$nextIndex, pageIndex=$pageIndex.",
    );
  }

  void _undo() {
    if (_changedPhotos.isEmpty) return;

    final photo = _changedPhotos.removeLast();

    setState(() {});

    // // 等待一帧，确保 PageView 已更新 itemCount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.jumpToPage(_currentPageIndex);
    });
  }

  @override
  void dispose() {
    _deleteAnimController.dispose();
    _controller.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _applyChanges() async {
    debugPrint('@@点击了应用按钮。');

    List<_Photo> undeletedPhotos = await _deleteMedia(_changedPhotos);
    for (_Photo photo in _changedPhotos) {
      if (undeletedPhotos.contains(photo)) {}
    }
    _changedPhotos.clear();
  }

  // static Future<bool> _requestPermission() async {
  //   final result = await PhotoManager.requestPermissionExtend();
  //   return result.isAuth || result.hasAccess;
  // }

  /// 删除单张或多张照片/视频
  /// assetIds: photo_manager 获取的 AssetEntity.id
  static Future<List<_Photo>> _deleteMedia(List<_Photo> changedPhotos) async {
    final List<String> toDeleteIds = [];
    final Map<String, _Photo> mapIdPhoto = {
      for (var photo in changedPhotos) photo.assetEntity.id: photo,
    };
    for (int i = 0; i < changedPhotos.length; i++) {
      var photo = changedPhotos[i];
      if (photo.state == 1) {
        toDeleteIds.add(photo.assetEntity.id);
      }
    }
    try {
      var deletedIds = await PhotoManager.editor.deleteWithIds(toDeleteIds);
      debugPrint('@@删除了 ${deletedIds.length} 张照片。');
      List<String> undeletedIds = toDeleteIds
          .toSet()
          .difference(deletedIds.toSet())
          .toList();
      List<_Photo> undeletedPhotos = [
        for (var id in undeletedIds) mapIdPhoto[id]!,
      ];
      return undeletedPhotos;
    } catch (e) {
      debugPrint('@@删除失败: $e');
      List<_Photo> undeletedPhotos = changedPhotos;
      return undeletedPhotos;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('照片查看')),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: _visiblePhotos.length,
                  physics: _isZoomed
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index; //页码索引，与 _photos 中 photo 的索引不同。
                      _transformationController.value = Matrix4.identity();
                      debugPrint(
                        "@@当前页面索引：$index, 当前照片id: ${_visiblePhotos[_currentPageIndex].index}",
                      );
                      debugPrint(
                        "@@当前相册长度：${_visiblePhotos.length}, 已标记照片数量：${_changedPhotos.length}.",
                      );
                    });
                  },
                  itemBuilder: (context, index) {
                    final asset = _visiblePhotos[index];
                    final deleteOffset =
                        (_isDeleting && index == _currentPageIndex)
                        ? _deleteAnimController.value *
                              MediaQuery.of(context).size.height
                        : 0.0;
                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTapDown: (details) {
                        _doubleTapDetails = details;
                        debugPrint("@@点击事件：双击按下");
                      },
                      onDoubleTap: () {
                        debugPrint("@@点击事件：双击");
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
                              debugPrint("点击事件：竖直拖动松开");
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
                                asset.assetEntity,
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
                      color: const Color.fromARGB(
                        255,
                        132,
                        31,
                        23,
                      ).withValues(),
                      child: const Center(
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  color: Colors.white,
                  onPressed: _changedPhotos.isEmpty ? null : _undo,
                  tooltip: '撤销删除',
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  color: Colors.green,
                  onPressed: _changedPhotos.isEmpty ? null : _applyChanges,
                  tooltip: '撤销删除',
                ),
              ],
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
          IconButton(
            icon: Icon(
              Icons.arrow_downward,
              color: disabled ? Colors.grey : Colors.white,
            ),
            onPressed: () {
              _movePhoto(album);
            },
            tooltip: '移动照片',
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
          // debugPrint('@@点击了新建相册。');
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

class _Photo {
  final AssetEntity assetEntity;
  final AssetPathEntity album;
  final int index;
  int? lastIndex;
  int? nextIndex;
  int? pageIndex; //删除或移动时用，标记原来所在的页面。
  int state = 0; //0: 未操作 1: 标记为删除 2: 标记为移动 3: 已应用删除或移动
  AssetPathEntity? targetAlbum;

  _Photo(
    this.assetEntity,
    this.album,
    this.index,
    this.lastIndex,
    this.nextIndex,
  );

  int? getLastIndex(List<_Photo> photos) {
    // 从链表中
    return 0;
  }
}

// class _MediaUtils {
//   /// 请求相册权限

//   /// 移动单张或多张资源到指定相册
//   /// targetAlbumName: 目标相册名称
//   static Future<void> moveToAlbum(
//     List<AssetEntity> assets,
//     String targetAlbumName,
//   ) async {
//     // 获取所有相册
//     final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
//       type: RequestType.image,
//       hasAll: true,
//     );

//     // 查找目标相册
//     AssetPathEntity? targetAlbum = albums.firstWhere(
//       (album) => album.name == targetAlbumName,
//       orElse: () => null,
//     );

//     // 移动资源
//     for (var asset in assets) {
//       try {
//         await PhotoManager.editor.copyAssetToPath(
//           asset: asset,
//           pathEntity: targetAlbum,
//         );
//       } catch (e) {
//         print('移动 ${asset.id} 异常: $e');
//       }
//     }
//   }
// }
