import 'dart:io';
import 'dart:isolate';
import 'package:file_manager/constants/constants.dart';
import 'package:file_manager/data/local/shared_prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
// import 'package:flutter_audio_trimmer/flutter_audio_trimmer.dart';

import 'sdcard_file_utils.dart';

class FileUtils {
  /// Check if file is an APK file (Android application package)
  static bool isApkFile(File file) => p.extension(file.path).toLowerCase() == '.apk';

  /// Check if file is a Zip file (Zip Archive)
  static bool isZipFile(File file) => p.extension(file.path).toLowerCase() == '.zip';

  static bool isInternal(Directory directory) =>directory.path.contains(SharedPrefs.getString(StorageType.internal.name) ?? 'XXXX');

  static Future<void> createFile({required String name, required Directory destination, bool rethrowException = false}) async {
    try {
      if(!isInternal(destination)) {
        await SDCardFileUtils.createFile(name: name, destination: destination.path);
        return;
      }

      File file = File(p.join(destination.path, name));
      if(await file.exists()) {
        throw Exception("File ${file.path} already exist.");
      } else {
        await file.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error: $e');
      if(rethrowException) rethrow;
    }
  }
  
  static Future<void> createDirectory({required String name, required Directory destination, bool rethrowException = false}) async {
    try {
      if(!isInternal(destination)) {
        await SDCardFileUtils.createDirectory(name: name, destination: destination.path);
        return;
      }
      Directory directory = Directory(p.join(destination.path, name));
      if(await directory.exists()) {
        throw Exception("Directory ${directory.path} already exist.");
      } else {
        await directory.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error: $e');
      if(rethrowException) rethrow;
    }
  }

  static Future<void> cloneDirectory({required Directory source, required Directory destination}) async {
    try {
      if(!isInternal(destination)) {
        await SDCardFileUtils.cloneDirectory(source: source.path, destination: destination.path);
        return;
      }
      Isolate.run(() async {
        if (await source.exists()) {
          // Get the list of all the files in the source directory recursively
          var entities = source.listSync(recursive: true);
          
          for (var entity in entities) {
            if (entity is File) {
              await cloneFile(source: entity, destination: File(entity.path.replaceFirst(source.parent.path, destination.path)));
            }
          }
        } else {
          debugPrint("Error: Source directory does not exist.");
        }
      }, debugName: 'CloneDirectoryIsolate');
    } catch (e) {
      debugPrint('Error occurred while cloning directory: $e');
    }
  }

  static Future<void> cloneFile({required File source, required File destination}) async {
    try {
      if(!isInternal(destination.parent)) {
        await SDCardFileUtils.cloneFile(source: source.path, destination: destination.parent.path);
        return;
      }
      if (await source.exists()) {
        // Copy the content of the file to the destination
        if (!(await destination.parent.exists())) {
          await destination.parent.create(recursive: true);
        }
        await source.copy(destination.path);
        // Get file metadata from the source file
        var sourceStat = await source.stat();
        // Preserve the last modified time
        await destination.setLastModified(sourceStat.modified);
        debugPrint('File cloned successfully..');
        debugPrint('From: ${source.path}');
        debugPrint('To: ${destination.path}');
      } else {
        debugPrint('Error: Source file does not exist.');
      }
    } catch (e) {
      debugPrint('Error occurred while cloning file: $e');
    }
  }

  static Future<File> zipFiles(List<FileSystemEntity> entities, File zipFile) async {
    try {
      Isolate.run(() async {
        final archive = Archive();
        for (var entity in entities) {
          if (entity is File) {
            await _addFileToArchive(archive, entity, entity.parent.path);
          } else if (entity is Directory) {
            await _addDirectoryToArchive(archive, entity, entity.parent.path);
          }
        }
        // Encode the archive to ZIP format
        final zipData = ZipEncoder().encode(archive);
        // Write the ZIP data to the file
        await zipFile.writeAsBytes(zipData);
        debugPrint('Entities zipped successfully..');
      }, debugName: 'ZipIsolate');
    } catch (e) {
      debugPrint('Error occurred while zipping entities: $e');
    }
    return zipFile;
  }

  static Future<void> _addFileToArchive(Archive archive, File file, String rootPath) async {
    final fileData = await file.readAsBytes();
    var relativePath = p.relative(file.path, from: rootPath);
    archive.addFile(ArchiveFile(relativePath, fileData.length, fileData));
    debugPrint('Item Added: ${file.path} to [$relativePath]');
  }

  static Future<void> _addDirectoryToArchive(Archive archive, Directory directory, String rootPath) async {
    archive.add(ArchiveFile.directory(p.relative(directory.path, from: rootPath)));
    final entities = directory.listSync(recursive: false);

    for (var entity in entities) {
      if (entity is File) {
        await _addFileToArchive(archive, entity, rootPath);
      } else if(entity is Directory) {
        await _addDirectoryToArchive(archive, entity, rootPath);
      }
    }
  }

  static Future<void> unZipFile(File zipFile, String extractToPath) async {
    try {
      Isolate.run(() async {
        final bytes = await zipFile.readAsBytes();
        final Archive archive = ZipDecoder().decodeBytes(bytes);
        
        for (final ArchiveFile file in archive) {
          final String filename = file.name;
          final String destinationPath = p.join(extractToPath, filename);
        
          if (file.isFile) {
            final data = file.content as List<int>;
            final outFile = File(destinationPath);
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(data);
          } else {
            await Directory(destinationPath).create(recursive: true);
          }
        }
        debugPrint('File unzipped successfully..');
      }, debugName: 'UnZipIsolate');
    } catch (e) {
      debugPrint('Error occurred while unzipping file [${zipFile.path}]: $e');
    }
  }

  // static Future<int> trimAudio({required String path, required String outputPath, required int startTime, required int endTime}) async {
  //   try {
  //     File? trimmedAudioFile = await FlutterAudioTrimmer.trim(
  //       inputFile: File(path),
  //       outputDirectory: Directory(p.dirname(outputPath)),
  //       fileName: p.basename(outputPath),
  //       fileType:
  //       //  Platform.isAndroid ? AudioFileType.mp3 :
  //       AudioFileType.m4a,
  //       time: AudioTrimTime(
  //         start: Duration(seconds: startTime),
  //         end: Duration(seconds: endTime),
  //       ),
  //     );
  //     return 0;
  //   } catch (e) {
  //     debugPrint('Error came while triming audio: $e');
  //     return 1;
  //   }
  // }

  /// Recursively calculates the total size (in bytes) of a directory.
  Future<int> getDirectorySize(Directory directory) async {
    int totalSize = 0;
    try {
      await for (FileSystemEntity entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      debugPrint("Error reading directory: $e");
    }
    return totalSize;
  }
}