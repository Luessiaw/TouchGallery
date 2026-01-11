import 'package:photo_manager/photo_manager.dart';

/// Public model representing a photo node used by viewer and timeline.
///
/// - Keeps essential fields (asset, album, index, targetAlbum).
/// - Optional linked-list helpers `last`/`next` are provided for the
///   viewer where removal/recovery logic uses them, but they can be
///   ignored by consumers (e.g., timeline) if not needed.
/// - Includes serialization helpers for logging purposes.

enum PhotoState { none, markedDeleted, markedMoved, applied }

class PhotoNode {
  final AssetEntity assetEntity;
  final AssetPathEntity album;
  int index;

  PhotoNode? last;
  PhotoNode? next;
  AssetPathEntity? targetAlbum;

  PhotoState state = PhotoState.none;

  String currentAssetId;

  PhotoNode(this.assetEntity, this.album, this.index)
    : currentAssetId = assetEntity.id;

  String get id => assetEntity.id;

  /// Return the previous node that is not in `applied` state, or null.
  PhotoNode? getLast() {
    if (last == null) return null;
    if (last!.state != PhotoState.applied) return last;
    return last!.getLast();
  }

  /// Return the next node that is not in `applied` state, or null.
  PhotoNode? getNext() {
    if (next == null) return null;
    if (next!.state != PhotoState.applied) return next;
    return next!.getNext();
  }

  Map<String, dynamic> toMap() => {
    'assetId': assetEntity.id,
    'currentAssetId': currentAssetId,
    'albumId': album.id,
    'index': index,
    'state': state.index,
    'targetAlbumId': targetAlbum?.id,
  };

  /// fromMap cannot fully restore AssetEntity/AssetPathEntity; use MediaService
  /// to resolve assetId/albumId at runtime. This is primarily for log parsing.
  static PhotoNode fromMap(Map<String, dynamic> map) {
    throw UnimplementedError(
      'Use MediaService to rebuild PhotoNode from assetId when needed.',
    );
  }
}
