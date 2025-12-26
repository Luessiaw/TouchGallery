import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/foundation.dart';

class MediaService {
  /// 请求权限
  static Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    debugPrint(
      '权限状态: '
      'isAuth=${result.isAuth}, '
      'hasAccess=${result.hasAccess}, '
      'isLimited=${result.isLimited}',
    );
    return result.hasAccess;
  }

  /// 获取所有系统相册
  // static Future<List<AssetPathEntity>> getAlbums() async {
  //   return await PhotoManager.getAssetPathList(
  //     type: RequestType.image,
  //     hasAll: true,
  //   );
  // }
  static Future<List<AssetPathEntity>> getAlbums() async {
    final filterOption = FilterOptionGroup(
      orders: [OrderOption(type: OrderOptionType.createDate, asc: false)],
    );
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
      filterOption: filterOption,
    );

    debugPrint("获取相册");
    for (final album in albums) {
      debugPrint('相册: ${album.name}');
    }

    return albums;
  }
}
