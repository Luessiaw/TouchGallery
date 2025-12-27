// import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'photo_viewer_page.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class PhotoGridPage extends StatefulWidget {
  final String title;
  final AssetPathEntity album;
  final int albumCount;
  final List<AssetPathEntity> allAlbums;

  const PhotoGridPage({
    super.key,
    required this.title,
    required this.album,
    required this.albumCount,
    required this.allAlbums,
  });

  @override
  State<PhotoGridPage> createState() => _PhotoGridPageState();
}

class _PhotoGridPageState extends State<PhotoGridPage> {
  final List<AssetEntity> _photos = [];
  final ScrollController _controller = ScrollController();

  int _page = 0;
  final int _pageSize = 60;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMore();

    _controller.addListener(() {
      if (_controller.position.pixels >=
              _controller.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    _isLoading = true;

    final newPhotos = await widget.album.getAssetListPaged(
      page: _page,
      size: _pageSize,
    );

    if (newPhotos.isEmpty) {
      _hasMore = false;
    } else {
      _photos.addAll(newPhotos);
      _page++;
    }

    _isLoading = false;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: GridView.builder(
        controller: _controller,
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoViewerPage(
                    photos: _photos,
                    initialIndex: index,
                    currentAlbum: widget.album,
                    currentAlbumCount: widget.albumCount,
                    allAlbums: widget.allAlbums,
                  ),
                ),
              ).then((_) async {
                _page = 0;
                _photos.clear();
                await _loadMore();
              });
            },
            child: AssetEntityImage(
              _photos[index],
              isOriginal: false,
              thumbnailSize: const ThumbnailSize(200, 200),
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
