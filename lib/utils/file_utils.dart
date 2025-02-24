import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class FileUtils {
  static bool isApkFile(File file) {
    // Extract the file extension and convert it to lowercase
    final ext = p.extension(file.path).toLowerCase();
    // Check if it's an APK file (Android application package)
    return ext == '.apk';
  }

  static Future<void> cloneDirectory({required Directory source, required Directory destination}) async {
    try {
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
    } catch (e) {
      debugPrint('Error occurred while cloning directory: $e');
    }
  }

  static Future<void> cloneDirectory0({required Directory source, required Directory destination}) async {
    try {
      if (await source.exists()) {
        // Create the destination directory if it doesn't exist
        // if (!(await destination.exists())) {
        //   await destination.create(recursive: true);
        // }
        // Get the list of files and directories in the source directory
        var entities = source.listSync(recursive: false);
        
        for (var entity in entities) {
          // If the entity is a directory, recursively clone it
          if (entity is Directory) {
            await cloneDirectory(source: entity, destination: Directory(entity.path.replaceFirst(source.parent.path, destination.path)));
            // await cloneDirectory(source: entity, destination: Directory('${destination.path}/${entity.uri.pathSegments.last}'));
          }
          // If the entity is a file, clone it using the cloneFile function
          else if (entity is File) {
            await cloneFile(source: entity, destination: File(entity.path.replaceFirst(source.parent.path, destination.path)));
            // await cloneFile(source: entity, destination: File('${destination.path}/${entity.uri.pathSegments.last}'));
          }
        }
      } else {
        debugPrint("Error: Source directory does not exist.");
      }
    } catch (e) {
      debugPrint('Error occurred while cloning diectory: $e');
    }
  }

  static Future<void> cloneFile({required File source, required File destination}) async {
    try {
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
}
