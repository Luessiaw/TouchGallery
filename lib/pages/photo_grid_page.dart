import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoGridPage extends StatefulWidget {
  final String title;
  final AssetPathEntity album;

  const PhotoGridPage({super.key, required this.title, required this.album});

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
          final asset = _photos[index];

          return FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(color: Colors.grey.shade300);
              }

              return Image.memory(snapshot.data!, fit: BoxFit.cover);
            },
          );
        },
      ),
    );
  }
}
