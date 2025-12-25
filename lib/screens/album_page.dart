import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class AlbumPage extends StatefulWidget {
  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  List<AssetPathEntity> albums = [];

  @override
  void initState() {
    super.initState();
    loadAlbums();
  }

  Future<void> loadAlbums() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth) {
      final albumList = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );
      setState(() {
        albums = albumList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("相册")),
      body: albums.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return GestureDetector(
                  onTap: () {
                    // 跳转到按日期分组的照片列表页面
                    Navigator.pushNamed(
                      context,
                      '/photos-by-date',
                      arguments: album,
                    );
                  },
                  child: GridTile(
                    child: Icon(Icons.photo_album), // 这里用一个图标代替
                    footer: GridTileBar(
                      backgroundColor: Colors.black54,
                      title: Text(album.name),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
