import 'dart:io';
import 'package:path/path.dart' as p;

class FileUtils {
  static bool isApkFile(File file) {
    // Extract the file extension and convert it to lowercase
    final ext = p.extension(file.path).toLowerCase();
    // Check if it's an APK file (Android application package)
    return ext == '.apk';
  }
}