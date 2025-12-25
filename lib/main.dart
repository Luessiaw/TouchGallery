import 'package:flutter/material.dart';
import 'pages/albums_page.dart';
import 'pages/timeline_page.dart';

void main() {
  runApp(const PhotoManagerApp());
}

class PhotoManagerApp extends StatelessWidget {
  const PhotoManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Manager',
      theme: ThemeData(useMaterial3: true),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final _pages = const [AlbumsPage(), TimelinePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.photo_album), label: '相册'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '日期',
          ),
        ],
      ),
    );
  }
}
