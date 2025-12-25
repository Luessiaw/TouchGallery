import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/media_service.dart';
import 'photo_grid_page.dart';
import 'dart:typed_data';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  List<AssetPathEntity> _albums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final granted = await MediaService.requestPermission();
    if (!granted) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final albums = await MediaService.getAlbums();
    setState(() {
      _albums = albums;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_albums.isEmpty) {
      return const Scaffold(body: Center(child: Text('未找到相册')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('相册')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _albums.length,
        itemBuilder: (context, index) {
          final album = _albums[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PhotoGridPage(title: album.name, album: album),
                ),
              );
            },
            child: Stack(
              children: [
                Positioned.fill(child: AlbumCover(album: album)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black54,
                    child: Text(
                      album.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AlbumCover extends StatelessWidget {
  final AssetPathEntity album;

  const AlbumCover({super.key, required this.album});

  Future<Uint8List?> _loadCover() async {
    final assets = await album.getAssetListPaged(page: 0, size: 1);
    if (assets.isEmpty) return null;

    return await assets.first.thumbnailDataWithSize(
      const ThumbnailSize(400, 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _loadCover(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: Colors.grey.shade400);
        }

        return Image.memory(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}
