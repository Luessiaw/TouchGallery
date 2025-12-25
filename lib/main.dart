import 'package:flutter/material.dart';
import 'screens/album_page.dart'; // 导入相册页面
// import 'screens/photos_by_date_page.dart'; // 导入按日期分组页面
// import 'screens/photo_detail_page.dart'; // 导入照片详情页面

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => AlbumPage(),
        // '/photos-by-date': (context) => PhotosByDatePage(),
        // '/photo-detail': (context) => PhotoDetailPage(),
      },
    );
  }
}
