import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/media_service.dart';
import 'logs_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, String> _albumNames = {}; // id -> name
  bool _loadingAlbums = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final albums = await MediaService.getAlbums();
    final map = <String, String>{};
    for (final a in albums) {
      map[a.id] = a.name;
    }
    if (!mounted) return;
    setState(() {
      _albumNames = map;
      _loadingAlbums = false;
    });
  }

  void _openManageHiddenPage(BuildContext context, Set<String> hiddenIds) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageHiddenAlbumsPage(albumNames: _albumNames),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   '常用设置',
            //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            // ),
            const SizedBox(height: 8),
            if (_loadingAlbums) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            ValueListenableBuilder<Set<String>>(
              valueListenable: SettingsService.instance.hiddenAlbumsNotifier,
              builder: (context, hidden, _) {
                return ListTile(
                  title: const Text('批量管理隐藏相册'),
                  // subtitle: Text('当前隐藏 ${hidden.length} 个相册'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openManageHiddenPage(context, hidden),
                );
              },
            ),
            // const Divider(),
            // ListTile(
            //   title: const Text('查看操作日志'),
            //   // subtitle: const Text('导出为 JSON 或 清空日志'),
            //   trailing: const Icon(Icons.chevron_right),
            //   onTap: () async {
            //     Navigator.of(
            //       context,
            //     ).push(MaterialPageRoute(builder: (_) => const LogsPage()));
            //   },
            // ),
            // const Divider(),
            // if (_loadingAlbums) const LinearProgressIndicator(),
            // const SizedBox(height: 8),
            // const Text('注意', style: TextStyle(fontWeight: FontWeight.w500)),
            // const SizedBox(height: 6),
            // const Text('隐藏相册仅影响应用内显示，不会从系统相册删除任何照片。'),
          ],
        ),
      ),
    );
  }
}

class ManageHiddenAlbumsPage extends StatefulWidget {
  final Map<String, String> albumNames;
  const ManageHiddenAlbumsPage({super.key, required this.albumNames});

  @override
  State<ManageHiddenAlbumsPage> createState() => _ManageHiddenAlbumsPageState();
}

class _ManageHiddenAlbumsPageState extends State<ManageHiddenAlbumsPage> {
  late final List<MapEntry<String, String>> _albums;

  @override
  void initState() {
    super.initState();
    _albums = widget.albumNames.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('管理隐藏相册')),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: SettingsService.instance.hiddenAlbumsNotifier,
        builder: (context, hidden, _) {
          return ListView.builder(
            itemCount: _albums.length,
            itemBuilder: (context, index) {
              final entry = _albums[index];
              final id = entry.key;
              final name = entry.value;
              final isHidden = hidden.contains(id);
              return SwitchListTile(
                title: Text(name),
                // subtitle: Text(id, style: const TextStyle(fontSize: 11)),
                value: isHidden,
                onChanged: (v) async {
                  if (v) {
                    await SettingsService.instance.hideAlbum(id);
                  } else {
                    await SettingsService.instance.unhideAlbum(id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
