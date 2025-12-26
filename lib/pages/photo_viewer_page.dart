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
  int _pageIndex = 0;

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
    _pageIndex = widget.initialIndex;
    _transformationController = TransformationController();
    // _visiblePhotos = List.of(widget.photos);
    _Photo? lastPhoto;
    for (var i = 0; i < widget.photos.length; i++) {
      _Photo photo = _Photo(widget.photos[i], widget.currentAlbum, i);
      photo.last = lastPhoto;
      if (lastPhoto != null) {
        lastPhoto.next = photo;
      }
      lastPhoto = photo;
      _photos.add(photo);
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

    // 找到链表的头结点：lastIndex == null 或者链表中没有对应 lastIndex 的
    _Photo? head = photos.cast<_Photo?>().firstWhere(
      (p) => (p!.last == null && p.state == 0),
      orElse: () => null,
    );

    List<_Photo> visible = [];
    _Photo? current = head;
    while (current != null) {
      visible.add(current);
      if (current.next != null) {
        current = current._getNext();
      } else {
        break;
      }
    }
    return visible;
  }

  void _deletePhoto() {
    if (_pageIndex < 0 || _pageIndex >= _visiblePhotos.length) {
      debugPrint("@@删除照片时，当前触及边界。pageIndex: $_pageIndex");
      return;
    }

    setState(() {
      _Photo photo = _popPhoto();
      photo.state = 1;
      _visiblePhotos = getVisiblePhotos(_photos);
      debugPrint("@@照片已标记为：删除。");
    });
  }

  void _movePhoto(AssetPathEntity album) {
    if (_pageIndex < 0 || _pageIndex >= _visiblePhotos.length) {
      return;
    }

    setState(() {
      _Photo photo = _popPhoto();
      photo.state = 2;
      photo.targetAlbum = album;
      _visiblePhotos = getVisiblePhotos(_photos);
      debugPrint("@@照片已标记为：移动。target album: ${album.name}");
    });
  }

  _Photo _popPhoto() {
    final photo = _visiblePhotos[_pageIndex];
    _Photo? last = photo._getLast();
    _Photo? next = photo._getNext();
    _changedPhotos.add(photo);

    if (last != null) {
      last.next = next;
    }
    if (next != null) {
      next.last = last;
    }

    if (_pageIndex >= _visiblePhotos.length) {
      _pageIndex = _visiblePhotos.length - 1;
    }

    debugPrint(
      "@@取出照片：index=${photo.index}, lastIndex=${last?.index}, nextIdex=${next?.index}, pageIndex=$_pageIndex",
    );
    return photo;
  }

  void _recoverPhoto(_Photo photo) {
    final last = photo._getLast();
    final next = photo._getNext();
    final index = photo.index;

    if (last != null) {
      last.next = photo;
    }
    if (next != null) {
      next.last = photo;
    }

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
      "@@恢复照片。index=$index, lastIndex=${last?.index}, nextIndex=${next?.index}.",
    );
    photo.state = 0;
    photo.targetAlbum = null;
    _visiblePhotos = getVisiblePhotos(_photos);
    _pageIndex = _visiblePhotos.indexWhere((p) => p.index == photo.index);
  }

  void _undo() {
    if (_changedPhotos.isEmpty) return;

    final photo = _changedPhotos.removeLast();

    setState(() {
      _recoverPhoto(photo);
    });

    // // 等待一帧，确保 PageView 已更新 itemCount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.jumpToPage(_pageIndex);
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

    List<String> deletedIds = await _deleteMedia(_changedPhotos);
    if (deletedIds.length < _changedPhotos.length) {
      if (deletedIds.isEmpty) {
        debugPrint("@@未删除照片，可能是用户取消授权。");
      } else {
        debugPrint(
          "@@ ${_changedPhotos.length} 张照片中的 ${_changedPhotos.length - deletedIds.length} 张未成功删除。",
        );
      }
    } else {
      debugPrint('@@成功删除 ${deletedIds.length} 张照片。');
    }
    _changedPhotos.removeWhere((_Photo photo) {
      if (deletedIds.contains(photo.assetEntity.id)) {
        photo.state = 3;
        return true;
      }
      return false;
    });
    // _changedPhotos.clear();
  }

  // static Future<bool> _requestPermission() async {
  //   final result = await PhotoManager.requestPermissionExtend();
  //   return result.isAuth || result.hasAccess;
  // }

  /// 删除单张或多张照片/视频
  /// assetIds: photo_manager 获取的 AssetEntity.id
  static Future<List<String>> _deleteMedia(List<_Photo> changedPhotos) async {
    final List<String> toDeleteIds = [];
    final List<String> toMoveIds = [];
    for (int i = 0; i < changedPhotos.length; i++) {
      var photo = changedPhotos[i];
      if (photo.state == 1) {
        toDeleteIds.add(photo.assetEntity.id);
      } else if (photo.state == 2) {
        toMoveIds.add(photo.assetEntity.id);
      }
    }
    try {
      var deletedIds = await PhotoManager.editor.deleteWithIds(toDeleteIds);
      return deletedIds;
    } catch (e) {
      debugPrint('@@删除失败: $e');
      return [];
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
                      _pageIndex = index; //页码索引，与 _photos 中 photo 的索引不同。
                      _transformationController.value = Matrix4.identity();
                      debugPrint(
                        "@@当前页面索引：$_pageIndex, 照片 index: ${_visiblePhotos[_pageIndex].index}, id: ${_visiblePhotos[_pageIndex].assetEntity.id}",
                      );
                      // debugPrint(
                      //   "@@当前相册长度：${_visiblePhotos.length}, 已标记照片数量：${_changedPhotos.length}.",
                      // );
                    });
                  },
                  itemBuilder: (context, index) {
                    final asset = _visiblePhotos[index];
                    final deleteOffset = (_isDeleting && index == _pageIndex)
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
  int index;
  _Photo? last;
  _Photo? next;
  AssetPathEntity? targetAlbum;

  int state = 0; //0: 未操作 1: 标记为删除 2: 标记为移动 3: 已应用删除或移动

  _Photo(this.assetEntity, this.album, this.index);

  _Photo? _getLast() {
    // 从链表中
    if (last == null) {
      return null;
    }
    if (last!.state < 3) {
      return last;
    } else {
      return last!._getLast();
    }
  }

  _Photo? _getNext() {
    // 从链表中
    if (next == null) {
      return null;
    }
    if (next!.state < 3) {
      return next;
    } else {
      return next!._getNext();
    }
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
