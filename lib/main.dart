import 'package:flutter/material.dart';
import 'screens/albums_page.dart'; // 引入相册页面

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '照片管理',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AlbumsPage(), // 设置启动页为相册页面
    );
  }
}
