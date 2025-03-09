import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:file_manager/constants/constants.dart';
import 'package:file_manager/utils/file_utils.dart';
import 'package:file_manager/utils/ios_media_access.dart';
import 'package:file_manager/utils/permission_manager.dart';
import 'package:flutter/foundation.dart';
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
        String rootPath = '/storage/emualated/0/';
        if(storageType == StorageType.internal) {
          rootPath = externalDirs.first.path.split("Android").first;
        } else if(storageType == StorageType.sdcard && externalDirs.length > 1) {
          rootPath = externalDirs[1].path.split("Android").first;
        }
        currentDirectory = Directory(rootPath);
      } else {
        currentDirectory = externalDirs.first;
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
}