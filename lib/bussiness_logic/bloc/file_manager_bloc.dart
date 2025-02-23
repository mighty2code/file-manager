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
    on<GoBackEvent>(_goBack);
  }
  
  List<FileSystemEntity> entities = [];
  Set<FileSystemEntity> selectedEntities = {};

  Directory? currentDirectory;
  Directory? previousDirectory;
  bool isLoading = false;

  init() {
    emit(FileManagerLoading());
    _requestPermissions().then((value) => _loadFiles());
  }

  Future<bool> _requestPermissions() async {
    return await PermissionManager.requestFullStorageAccessPermission(openAppSettingsIfDenied: false);
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

  void _openDirectory(OpenDirectoryEvent event, Emitter<FileManagerState> emit) {
    Directory? dir = event.directory;
    if(dir == null) return;
    
    emit(FileManagerLoading());

    try {
      if (dir.existsSync()) {
          currentDirectory = dir;
          entities = dir.listSync();
          isLoading = false;
          if(entities.isEmpty) {
            emit(FileManagerEmpty());
          } else {
            emit(FileManagerShowList(entities));
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
    if(file == null) return;

    try {
      if(FileUtils.isApkFile(file)) {
        PermissionManager.requestPermission(Permission.requestInstallPackages).then((isGranted) {
          if(isGranted) {
            OpenFile.open(file.path).then((result) => debugPrint("Result: ${result.message}"));
          }
        });
      } else {
        OpenFile.open(file.path).then((result) => debugPrint("Result: ${result.message}"));
      }
    } catch (e) {
      debugPrint("Error: $e");
      emit(FileManagerError(e));
    }
  }

  FutureOr<void> _onSelectEntity(SelectEntityEvent event, Emitter<FileManagerState> emit) {
    selectedEntities.add(event.entity);
  }

  void _goBack(GoBackEvent event, Emitter<FileManagerState> emit) {
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