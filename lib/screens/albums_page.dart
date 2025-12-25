import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart'; // 引入权限处理库

class AlbumsPage extends StatefulWidget {
  @override
  _AlbumsPageState createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  List<AssetPathEntity> albums = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // 请求权限
  }

  // 请求权限
  Future<void> _requestPermissions() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      // 权限获取成功，加载相册
      _loadAlbums();
    } else {
      // 如果没有权限，可以提示用户
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("权限请求"),
          content: Text("我们需要读取您的照片，请授权权限。"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("确定"),
            ),
          ],
        ),
      );
    }
  }

  // 加载相册
  Future<void> _loadAlbums() async {
    final albums = await PhotoManager.getAssetPathList(onlyAll: true);
    setState(() {
      this.albums = albums;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('相册')),
      body: albums.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 每行展示 3 个相册
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // 跳转到该相册的照片列表页面
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Container(
                          height: 100,
                          color: Colors.grey,
                          child: Icon(Icons.photo), // 这里你可以设置一个封面图
                        ),
                        Text(albums[index].name),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
