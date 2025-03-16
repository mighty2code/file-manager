enum EntityType {
  file, directory
}

enum ErrorSeverity {
  critical, major, minor, moderate
}

enum StorageType {
  internal, sdcard,
  download, documents,
  pictures, music
}

class SharedPrefKeys {
  static const sdcardUri = 'sdcard-uri'; 
}