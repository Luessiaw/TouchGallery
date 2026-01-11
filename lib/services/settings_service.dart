import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A simple settings service using Hive for persistence.
///
/// - Hidden albums are stored under box `settings` with key `hidden_albums` as List<String>.
/// - Operation logs are stored in box `op_logs` as Map entries (append-only).
class SettingsService {
  SettingsService._internal();

  static final SettingsService instance = SettingsService._internal();

  late Box _settingsBox;
  late Box _logsBox;

  final ValueNotifier<Set<String>> hiddenAlbumsNotifier = ValueNotifier({});

  bool _inited = false;

  /// Initialize Hive and open boxes. Safe to call multiple times.
  Future<void> init() async {
    if (_inited) return;
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox('settings');
    _logsBox = await Hive.openBox('op_logs');

    final List? hidden = _settingsBox.get('hidden_albums') as List?;
    hiddenAlbumsNotifier.value = hidden == null
        ? {}
        : hidden.cast<String>().toSet();

    // Listen to notifier changes and persist
    hiddenAlbumsNotifier.addListener(() {
      _settingsBox.put('hidden_albums', hiddenAlbumsNotifier.value.toList());
    });

    _inited = true;
  }

  /// Returns current hidden albums set (snapshot)
  Set<String> getHiddenAlbums() => hiddenAlbumsNotifier.value;

  Future<void> setHiddenAlbums(Set<String> ids) async {
    hiddenAlbumsNotifier.value = Set.from(ids);
    await _settingsBox.put(
      'hidden_albums',
      hiddenAlbumsNotifier.value.toList(),
    );
  }

  Future<void> hideAlbum(String albumId) async {
    final set = Set<String>.from(hiddenAlbumsNotifier.value);
    if (set.add(albumId)) {
      hiddenAlbumsNotifier.value = set;
      await _settingsBox.put('hidden_albums', set.toList());
    }
  }

  Future<void> unhideAlbum(String albumId) async {
    final set = Set<String>.from(hiddenAlbumsNotifier.value);
    if (set.remove(albumId)) {
      hiddenAlbumsNotifier.value = set;
      await _settingsBox.put('hidden_albums', set.toList());
    }
  }

  /// Operation log format stored as Map<String, dynamic>:
  /// {
  ///   'id': int (auto increment by Hive),
  ///   'timestamp': millisSinceEpoch,
  ///   'type': 'move'|'delete'|'restore'...,
  ///   'assetId': String,
  ///   'fromAlbumId': String?,
  ///   'toAlbumId': String?,
  ///   'fromIndex': int?,
  ///   'toIndex': int?,
  ///   'extra': Map<String, dynamic>?
  /// }
  Future<int> appendOperation(Map<String, dynamic> op) async {
    final entry = Map<String, dynamic>.from(op);
    entry['timestamp'] = (entry['timestamp'] is int)
        ? entry['timestamp']
        : DateTime.now().millisecondsSinceEpoch;
    return await _logsBox.add(entry);
  }

  /// Query operations with simple filters. This is in-memory filtering.
  /// For large logs consider migrating to a proper DB (Drift/SQLite).
  List<Map<String, dynamic>> queryOperations({
    String? type,
    String? assetId,
    int? limit,
    int? offset,
    DateTime? from,
    DateTime? to,
  }) {
    final all = _logsBox.values
        .whereType<Map>()
        .cast<Map<String, dynamic>>()
        .toList(growable: false);

    Iterable<Map<String, dynamic>> iter = all;

    if (type != null) {
      iter = iter.where((m) => m['type'] == type);
    }
    if (assetId != null) {
      iter = iter.where((m) => m['assetId'] == assetId);
    }
    if (from != null) {
      final f = from.millisecondsSinceEpoch;
      iter = iter.where((m) => (m['timestamp'] as int) >= f);
    }
    if (to != null) {
      final t = to.millisecondsSinceEpoch;
      iter = iter.where((m) => (m['timestamp'] as int) <= t);
    }

    final list = iter.toList();
    // sort by timestamp desc
    list.sort(
      (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
    );

    final s = offset ?? 0;
    final e = limit == null ? list.length : (s + limit).clamp(0, list.length);
    if (s >= list.length) return [];
    return list.sublist(s, e).cast<Map<String, dynamic>>();
  }

  /// Clear logs older than the provided date.
  Future<void> clearOperationsOlderThan(DateTime date) async {
    final cutoff = date.millisecondsSinceEpoch;
    final keysToDelete = <dynamic>[];
    for (final key in _logsBox.keys) {
      final v = _logsBox.get(key);
      if (v is Map && (v['timestamp'] as int) < cutoff) keysToDelete.add(key);
    }
    if (keysToDelete.isNotEmpty) {
      await _logsBox.deleteAll(keysToDelete);
    }
  }

  /// Wipe all logs (dangerous)
  Future<void> clearAllLogs() async {
    await _logsBox.clear();
  }

  /// Close boxes (for tests or graceful shutdown)
  Future<void> dispose() async {
    await _settingsBox.close();
    await _logsBox.close();
    hiddenAlbumsNotifier.dispose();
    _inited = false;
  }
}
