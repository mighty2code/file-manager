class NativeChannels {
  static const android = 'file_manager/android';
  static const iOS = 'file_manager/iOS';
}

class AndroidMethods {
  static const getSDCardPermission = 'get-sdcard-permission';
  static const onSDCardPermissionResolved = 'on-sdcard-permission-resolved';

  static const sdcardCreateFile = 'sdcard-create-file';
  static const sdcardCreateDirectory = 'sdcard-create-directory';
  static const sdcardCloneFile = 'sdcard-clone-file';
  static const sdcardCloneDirectory = 'sdcard-clone-directory';
}