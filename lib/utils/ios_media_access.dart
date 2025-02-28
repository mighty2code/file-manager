import 'dart:io';
import 'package:photo_manager/photo_manager.dart';

class IosMediaAccess {
  // Request photos permission and get all albums
  static Future<List<AssetPathEntity>> getAlbums() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth) {
      // Get all albums (folders)
      return await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );
    }
    throw Exception('Permission not granted for photos access');
  }
  
  // Get all images from a specific album
  static Future<List<AssetEntity>> getImagesFromAlbum(AssetPathEntity album, {int page = 0, int pageSize = 80}) async {
    final media = await album.getAssetListPaged(page: page, size: pageSize);
    return media;
  }
  
  // Get file path from AssetEntity
  static Future<String?> getFilePath(AssetEntity asset) async {
    final file = await asset.file;
    return file?.path;
  }

  /// Simulate conversion of albums to directories.
  /// Note: These directories are not the actual albums in the Photos library,
  /// but are derived from the file path of a representative asset.
  static Future<List<Directory>> getAlbumDirectories() async {
    List<AssetPathEntity> albums = await getAlbums();
    List<Directory> albumDirs = [];

    for (var album in albums) {
      // Get one asset from the album to attempt deriving a directory
      final assets = await getImagesFromAlbum(album, page: 0, pageSize: 1);
      if (assets.isNotEmpty) {
        final filePath = await getFilePath(assets.first);
        if (filePath != null) {
          // Get the parent directory of the asset file
          final directory = Directory(File(filePath).parent.path);
          albumDirs.add(directory);
        }
      } else {
        // If there are no assets, you might simulate a directory name
        // (This directory is not an actual file system folder.)
        albumDirs.add(Directory('/album/${album.name}'));
      }
    }
    return albumDirs;
  }
}