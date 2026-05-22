import 'package:flutter/material.dart';
import 'pages/albums_page.dart';
import 'package:flutter/foundation.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化 settings service（内部会初始化 Hive）
  await SettingsService.instance.init();

  // 重写 debugPrint，只打印前缀带 @ 的消息
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null && message.startsWith('@')) {
      debugPrintSynchronously(message, wrapWidth: wrapWidth);
    }
  };

  runApp(const PhotoManagerApp());
}

class PhotoManagerApp extends StatelessWidget {
  const PhotoManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Manager',
      theme: ThemeData(useMaterial3: true),
      home: const AlbumsPage(),
    );
  }
}
