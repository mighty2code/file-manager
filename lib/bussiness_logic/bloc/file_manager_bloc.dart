import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:file_manager/constants/constants.dart';
import 'package:file_manager/utils/file_utils.dart';
import 'package:file_manager/utils/permission_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

part 'file_manager_event.dart';
part 'file_manager_state.dart';

class FileManagerBloc extends Bloc<FileManagerEvent, FileManagerState> {
  FileManagerBloc() : super(FileManagerInitial()) {
    on<OpenDirectoryEvent>(_openDirectory);
    on<OpenFileEvent>(_openFileWithIntent);
    on<SelectEntityEvent>(_onSelectEntity);
    on<SelectAllEntityEvent>(_onSelectAllEntities);
    on<UnselectEntityEvent>(_onUnselectEntity);

    on<CopyEvent>(_copyEvent);
    on<MoveEvent>(_moveEvent);
    on<DeleteEvent>(_deleteEvent);
    on<PasteEvent>(_pasteEvent);

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

  init() {
    emit(FileManagerLoading());
    _requestPermissions().then((value) => _loadFiles());
  }

  Future<bool> _requestPermissions() async {
    return await PermissionManager.requestFullStorageAccessPermission(
        openAppSettingsIfDenied: false);
  }

  Future<void> _loadFiles() async {
    List<Directory>? externalDirs = await getExternalStorageDirectories();

    if (externalDirs != null && externalDirs.isNotEmpty) {
      // Get root storage path
      String rootPath = externalDirs.first.path.split("Android").first;
      currentDirectory = Directory(rootPath);
      add(OpenDirectoryEvent(currentDirectory));
    }
  }

  void _openDirectory(
      OpenDirectoryEvent event, Emitter<FileManagerState> emit) {
    Directory? dir = event.directory;
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
    add(RefreshEvent());
  }

  void _onSelectAllEntities(SelectAllEntityEvent event, Emitter<FileManagerState> emit) {
    selectedEntities.addAll(entities);
    debugPrint('selectedEntities: $selectedEntities [FileManagerBloc._onSelectAllEntities]');
    add(RefreshEvent());
  }

  void _onUnselectEntity(UnselectEntityEvent event, Emitter<FileManagerState> emit) {
    selectedEntities.remove(event.entity);
    debugPrint('selectedEntities: $selectedEntities [FileManagerBloc._onUnselectEntity]');
    add(RefreshEvent());
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
    add(OpenDirectoryEvent(currentDirectory));
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
    add(OpenDirectoryEvent(currentDirectory));
  }

  void _refreshEvent(RefreshEvent event, Emitter<FileManagerState> emit) {
    emit(FileManagerShowList());
  }

  void _goBack(GoBackEvent event, Emitter<FileManagerState> emit) {
    if (selectedEntities.isNotEmpty) {
      selectedEntities = {};
      add(RefreshEvent());
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