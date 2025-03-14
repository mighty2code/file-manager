import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:file_manager/constants/constants.dart';
import 'package:file_manager/constants/native_config.dart';
import 'package:file_manager/data/local/shared_prefs.dart';
import 'package:file_manager/utils/file_utils.dart';
import 'package:file_manager/utils/ios_media_access.dart';
import 'package:file_manager/utils/permission_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;

part 'file_manager_event.dart';
part 'file_manager_state.dart';

class FileManagerBloc extends Bloc<FileManagerEvent, FileManagerState> {
  FileManagerBloc() : super(FileManagerInitial()) {
    on<OpenDirectoryEvent>(_openDirectory);
    on<OpenFileEvent>(_openFileWithIntent);
    on<SelectEntityEvent>(_onSelectEntity);
    on<SelectAllEntityEvent>(_onSelectAllEntities);
    on<UnselectAllEntityEvent>(_onUnselectAllEntities);
    on<UnselectEntityEvent>(_onUnselectEntity);

    on<CopyEvent>(_copyEvent);
    on<MoveEvent>(_moveEvent);
    on<DeleteEvent>(_deleteEvent);
    on<PasteEvent>(_pasteEvent);

    on<ArchiveEvent>(_onArchiveEvent);
    on<ExtractFileEvent>(_onExtractZipEvent);

    on<CreateNewFileEvent>(_onCreateNewFileEvent);
    on<CreateNewDirectoryEvent>(_onCreateNewDirectoryEvent);

    on<RefreshEvent>(_refreshEvent);
    on<GoBackEvent>(_goBack);
  }

  List<FileSystemEntity> entities = [];
  Set<FileSystemEntity> selectedEntities = {};
  Set<FileSystemEntity> clipBoardEntities = {};

  Directory? rootDirectory;
  Directory? currentDirectory;
  Directory? previousDirectory;
  bool isLoading = false;
  bool isMoveEvent = false;

  init({StorageType storageType = StorageType.internal}) {
    emit(FileManagerLoading());
    _requestPermissions().then((value) => _loadFiles(storageType: storageType));
  }

  Future<bool> _requestPermissions() async {
    return await PermissionManager.requestFullStorageAccessPermission(
        openAppSettingsIfDenied: false);
  }

  Future<void> _loadFiles({StorageType storageType = StorageType.internal}) async {
    List<Directory>? externalDirs;
    if(Platform.isAndroid) {
      externalDirs = await getExternalStorageDirectories();
    } else {
      externalDirs = [await getLibraryDirectory()];
    }

    if (externalDirs != null && externalDirs.isNotEmpty) {
      if(Platform.isAndroid) {
        // Get root storage path
        String rootPath = externalDirs.first.path.split("Android").first;
        String? externalPath = externalDirs.length > 1 ? externalDirs[1].path.split("Android").first : null;
        
        /// Saving root paths
        SharedPrefs.setString(StorageType.internal.name, rootPath);
        if(externalPath != null) {
          SharedPrefs.setString(StorageType.sdcard.name, externalPath);
        }

        if(storageType == StorageType.sdcard && externalPath != null) {
          rootPath = externalPath;
          await grantSDCardPermission(rootPath);
          listenForSDCardPermission();
        }
        currentDirectory = Directory(rootPath);
        rootDirectory = Directory(rootPath);
      } else {
        currentDirectory = externalDirs.first;
        rootDirectory = externalDirs.first;

      }
      add(OpenDirectoryEvent(currentDirectory));
    }
  }

  Future<List<Directory>> listEssentialDirectories() async {
    List<Directory> directories = [];
    // Get application documents directory (for user files)
    directories.add(await getApplicationDocumentsDirectory());
    // Get application support directory (for app-specific files)
    directories.add(await getApplicationSupportDirectory());
    // Get temporary directory (for temporary files)
    directories.add(await getTemporaryDirectory());
    // Get library directory (for app-specific storage, not user-accessible)
    directories.add(await getLibraryDirectory());
    return directories;
  }

  void _openDirectory(OpenDirectoryEvent event, Emitter<FileManagerState> emit) async {
    Directory? dir = event.directory;
    // if(dir!.path.contains('ios') && Platform.isIOS) {
      // entities = await IosMediaAccess.getAlbumDirectories();
    //     isLoading = false;
    //     if (entities.isEmpty) {
    //       emit(FileManagerEmpty());
    //     } else {
    //       emit(FileManagerShowList());
    //     }
    //     return;
    // }

    if (dir == null) return;

    emit(FileManagerLoading());

    try {
      if (dir.existsSync()) {
        currentDirectory = dir;
        entities = dir.listSync();
        if(dir.path == rootDirectory?.path) {
          for (var dir in entities) {
            // Extract the last segment of the directory path
            String dirBaseName = p.basename(dir.path).toLowerCase();
            if(dirBaseName.contains(StorageType.download.name)) {
              SharedPrefs.setString(StorageType.download.name, dir.path);
            } else if(dirBaseName.contains(StorageType.documents.name)) {
              SharedPrefs.setString(StorageType.documents.name, dir.path);
            } else if(dirBaseName.contains(StorageType.pictures.name)) {
              SharedPrefs.setString(StorageType.pictures.name, dir.path);
            } else if(dirBaseName.contains(StorageType.music.name)) {
              SharedPrefs.setString(StorageType.music.name, dir.path);
            } 
          }
        }
        isLoading = false;
        if (entities.isEmpty) {
          emit(FileManagerEmpty());
        } else {
          emit(FileManagerShowList());
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      emit(FileManagerError(e));
      Future.delayed(const Duration(milliseconds: 500), () {
        add(OpenDirectoryEvent(previousDirectory));
      });
    }
  }

  _openFileWithIntent(OpenFileEvent event, Emitter<FileManagerState> emit) {
    File? file = event.file;
    if (file == null) return;

    try {
      if (FileUtils.isApkFile(file)) {
        PermissionManager.requestPermission(Permission.requestInstallPackages)
            .then((isGranted) {
          if (isGranted) {
            OpenFile.open(file.path)
                .then((result) => debugPrint("Result: ${result.type}"));
          }
        });
      } else {
        OpenFile.open(file.path)
            .then((result) => debugPrint("Result: ${result.type}"));
      }
    } catch (e) {
      debugPrint("Error: $e");
      emit(FileManagerError(e));
    }
  }

  void _onSelectEntity(SelectEntityEvent event, Emitter<FileManagerState> emit) {
    selectedEntities.add(event.entity);
    debugPrint('selectedEntities: $selectedEntities [FileManagerBloc._onSelectEntity]');
    emit(FileManagerShowList());
  }

  void _onSelectAllEntities(SelectAllEntityEvent event, Emitter<FileManagerState> emit) {
    selectedEntities.addAll(entities);
    debugPrint('selectedEntities: $selectedEntities [FileManagerBloc._onSelectAllEntities]');
    emit(FileManagerShowList());
  }

  void _onUnselectAllEntities(UnselectAllEntityEvent event, Emitter<FileManagerState> emit) {
    selectedEntities = {};
    debugPrint('selectedEntities: $selectedEntities [FileManagerBloc._onUnselectAllEntities]');
    emit(FileManagerShowList());
  }

  void _onUnselectEntity(UnselectEntityEvent event, Emitter<FileManagerState> emit) {
    selectedEntities.remove(event.entity);
    debugPrint('selectedEntities: $selectedEntities [FileManagerBloc._onUnselectEntity]');
    emit(FileManagerShowList());
  }

  void _copyEvent(CopyEvent event, Emitter<FileManagerState> emit) {
    clipBoardEntities.addAll(selectedEntities);
    selectedEntities = {};
    debugPrint('clipBoardEntities: $clipBoardEntities [FileManagerBloc._copyEvent]');
    emit(FileManagerPasteState());
  }

  void _moveEvent(MoveEvent event, Emitter<FileManagerState> emit) {
    clipBoardEntities.addAll(selectedEntities);
    selectedEntities = {};
    isMoveEvent = true;
    debugPrint('clipBoardEntities: $clipBoardEntities [FileManagerBloc._copyEvent]');
    emit(FileManagerPasteState());
  }

  void _deleteEvent(DeleteEvent event, Emitter<FileManagerState> emit) async {
    for (FileSystemEntity entity in selectedEntities) {
      await entity.delete(recursive: true);
    }   
    selectedEntities = {};
    add(RefreshEvent());
  }

  void _pasteEvent(PasteEvent event, Emitter<FileManagerState> emit) async {
    if(currentDirectory == null) return;
    for (FileSystemEntity entity in clipBoardEntities) {
      if(entity is File) {
        await FileUtils.cloneFile(source: entity, destination: File('${currentDirectory!.path}/${entity.uri.pathSegments.last}'));
      } else if(entity is Directory) {
        await FileUtils.cloneDirectory(source: entity, destination: currentDirectory!);
      }
    }
    if(isMoveEvent) {
      for (FileSystemEntity entity in clipBoardEntities) {
        await entity.delete(recursive: true);
      }
      isMoveEvent = false;
    }
    clipBoardEntities = {};
    add(RefreshEvent());
  }

  void _onArchiveEvent(ArchiveEvent event, Emitter<FileManagerState> emit) async {
    if(currentDirectory == null) return;
    await FileUtils.zipFiles(selectedEntities.toList(), File(p.join(currentDirectory!.path, event.name)));
    selectedEntities = {};
    add(RefreshEvent());
  }

  void _onExtractZipEvent(ExtractFileEvent event, Emitter<FileManagerState> emit) async {
    if(currentDirectory == null || !isSelectionHaveOnlyAZipFile()) return;
    await FileUtils.unZipFile(selectedEntities.first as File, currentDirectory!.path);
    selectedEntities = {};
    add(RefreshEvent());
  }

  void _onCreateNewFileEvent(CreateNewFileEvent event, Emitter<FileManagerState> emit) async {
    if(currentDirectory == null) return;
    try {
      await FileUtils.createFile(name: event.name, destination: currentDirectory!, rethrowException: true);
      add(RefreshEvent());
    }  catch (e) {
      emit(FileManagerError(e));
    }
  }

  void _onCreateNewDirectoryEvent(CreateNewDirectoryEvent event, Emitter<FileManagerState> emit) async {
    if(currentDirectory == null) return;
    try {
      await FileUtils.createDirectory(name: event.name, destination: currentDirectory!, rethrowException: true);
      add(RefreshEvent());
    }  catch (e) {
      emit(FileManagerError(e));
    }
  }

  bool isSelectionHaveOnlyAZipFile() {
    if(selectedEntities.isEmpty || selectedEntities.length != 1) return false;
    FileSystemEntity entity = selectedEntities.first;
    if(entity is File && FileUtils.isZipFile(entity)) return true;
    return false;
  }

  void _refreshEvent(RefreshEvent event, Emitter<FileManagerState> emit) {
    add(OpenDirectoryEvent(currentDirectory));
    debugPrint('DebugX: on refresh called..');
  }

  void _goBack(GoBackEvent event, Emitter<FileManagerState> emit) {
    if (selectedEntities.isNotEmpty) {
      selectedEntities = {};
      emit(FileManagerShowList());
      return;
    }
    if (currentDirectory != null) {
      // Get the parent directory
      Directory parentDir = currentDirectory!.parent;

      // Check if the parent directory exists and is different from the current
      if (parentDir.path != currentDirectory!.path) {
        previousDirectory = currentDirectory;
        add(OpenDirectoryEvent(parentDir));
      }
    }
  }

  Future<bool> grantSDCardPermission(String path) async {
    const channel = MethodChannel(NativeChannels.android);
     try {
      final bool result = await channel.invokeMethod(
        AndroidMethods.getSDCardPermission,
        {'path': path},
      );
      debugPrint('${AndroidMethods.getSDCardPermission}: $result');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to get SD Card permission: ${e.message} [${AndroidMethods.getSDCardPermission}]");
      return false;
    }
  }

  // Listen for SD card permission result
  static Future<void> listenForSDCardPermission() async {
    const channel = MethodChannel(NativeChannels.android);
    channel.setMethodCallHandler((call) async {
      if (call.method == AndroidMethods.onSDCardPermissionResolved) {
        String uri = call.arguments;
        print("Received SD Card URI: $uri [${AndroidMethods.onSDCardPermissionResolved}]");
        // Handle the URI here (e.g., access SD card files)
      }
    });
  }
}