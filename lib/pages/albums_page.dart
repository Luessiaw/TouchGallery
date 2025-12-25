import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/media_service.dart';
import 'photo_grid_page.dart';

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
            child: Container(
              color: Colors.blueGrey,
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_album, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    album.name,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Text(
                  //   '${album.assetCount} 张',
                  //   style: const TextStyle(color: Colors.white70, fontSize: 12),
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
