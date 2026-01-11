import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/settings_service.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({Key? key}) : super(key: key);

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    try {
      final logs = SettingsService.instance.queryOperations(limit: 1000);
      setState(() {
        _logs = logs;
      });
    } catch (e) {
      debugPrint('@@加载日志失败: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载日志失败：$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _exportJsonToClipboard() async {
    try {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(_logs);
      await Clipboard.setData(ClipboardData(text: jsonStr));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已复制日志 JSON 到剪贴板。')));
    } catch (e) {
      debugPrint('@@导出日志失败: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败：$e')));
    }
  }

  Future<void> _clearAllLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空所有日志'),
        content: const Text('确定要删除所有操作日志吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SettingsService.instance.clearAllLogs();
        await _loadLogs();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已清空所有日志。')));
      } catch (e) {
        debugPrint('@@清空日志失败: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('清空日志失败：$e')));
      }
    }
  }

  Widget _buildLogTile(Map<String, dynamic> log) {
    final ts = DateTime.fromMillisecondsSinceEpoch(log['timestamp'] as int);
    final type = log['type'] ?? 'unknown';
    final assetId = log['assetId'] ?? '';
    final newAssetId = log['newAssetId'];
    final from = log['fromAlbumId'];
    final to = log['toAlbumId'];

    return ListTile(
      title: Text('$type — $assetId'),
      subtitle: Text(
        '${ts.toLocal()}\nto: ${newAssetId ?? '-'}  from: ${from ?? '-'}  to: ${to ?? '-'}',
      ),
      isThreeLine: true,
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('$type — ${assetId ?? ""}'),
            content: SingleChildScrollView(
              child: Text(const JsonEncoder.withIndent('  ').convert(log)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('操作日志'),
        actions: [
          IconButton(
            onPressed: _exportJsonToClipboard,
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            onPressed: _clearAllLogs,
            icon: const Icon(Icons.delete_forever),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLogs,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _logs.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('暂无日志记录。')),
                ],
              )
            : ListView.separated(
                itemCount: _logs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, idx) => _buildLogTile(_logs[idx]),
              ),
      ),
    );
  }
}
