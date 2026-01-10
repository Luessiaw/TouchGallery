import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/media_service.dart';
import '../services/settings_service.dart';
import 'photo_grid_page.dart';
import 'dart:typed_data';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  List<AssetPathEntity> _albums = [];
  List<int> _albumCounts = [];
  bool _loading = true;
  bool _showHidden = false;

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

    final counts = await Future.wait(albums.map((a) => a.assetCountAsync));

    if (!mounted) return;

    setState(() {
      _albums = albums;
      _albumCounts = counts;
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
      appBar: AppBar(title: const Text('相册'), actions: [
        IconButton(
          tooltip: '切换显示隐藏相册',
          icon: Icon(_showHidden ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _showHidden = !_showHidden),
        )
      ]),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: SettingsService.instance.hiddenAlbumsNotifier,
        builder: (context, hidden, _) {
          // 根据 _showHidden 与 hidden 集合决定显示哪些相册
          final visibleEntries = <MapEntry<AssetPathEntity, int>>[];
          for (var i = 0; i < _albums.length; i++) {
            final a = _albums[i];
            final count = _albumCounts.length > i ? _albumCounts[i] : 0;
            final isHidden = hidden.contains(a.id);
            if (!_showHidden && isHidden) continue;
            visibleEntries.add(MapEntry(a, count));
          }

          if (visibleEntries.isEmpty) {
            return const Center(child: Text('未找到相册'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: visibleEntries.length,
            itemBuilder: (context, index) {
              final entry = visibleEntries[index];
              final album = entry.key;
              final albumCount = entry.value;
              final isHidden = hidden.contains(album.id);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PhotoGridPage(
                        title: album.name,
                        album: album,
                        albumCount: albumCount,
                        allAlbums: _albums,
                      ),
                    ),
                  ).then((_) async {
                    await _loadAlbums();
                  });
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
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                album.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "$albumCount",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isHidden && _showHidden)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: Colors.redAccent.withOpacity(0.8),
                          child: const Text('隐藏', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                  ],
                ),
              );
            },
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
