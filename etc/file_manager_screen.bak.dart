import 'package:file_manager/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  _FileManagerScreenState createState() => _FileManagerScreenState();
}


class _FileManagerScreenState extends State<FileManagerScreen> {
  List<FileSystemEntity> files = [];
  Directory? currentDirectory;
  Directory? previousDirectory;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions0() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      _loadFiles();
    } else {
      debugPrint("Permission denied");
    }
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.manageExternalStorage.request();
    var status2 = await Permission.requestInstallPackages.request();
    
    if (status.isGranted && status2.isGranted) {
      _loadFiles();
    } else {
      debugPrint("Permission denied");
      // Optionally, direct the user to app settings.
      // openAppSettings();
    }
  }


  Future<void> _loadFiles() async {
    setState(() {
      isLoading = true;
    });
    List<Directory>? externalDirs = await getExternalStorageDirectories();
    
    if (externalDirs != null && externalDirs.isNotEmpty) {
      // Get root storage path
      String rootPath = externalDirs.first.path.split("Android").first;
      currentDirectory = Directory(rootPath);

      if (currentDirectory!.existsSync()) {
        setState(() {
          files = currentDirectory!.listSync();
          isLoading = false;
        });
      }
    }
  }

  void _openDirectory(Directory? dir) {
    if(dir == null) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      if (dir.existsSync()) {
        setState(() {
          currentDirectory = dir;
          files = dir.listSync();
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      _openDirectory(previousDirectory);
    }
  }

  _openFileWithIntent(File file) {
    try {
      OpenFile.open(file.path).then((result) => debugPrint("Result: ${result.message}"));
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _goBack() {
    if (currentDirectory != null) {
      // Get the parent directory
      Directory parentDir = currentDirectory!.parent;
      
      // Check if the parent directory exists and is different from the current
      if (parentDir.path != currentDirectory!.path) {
        previousDirectory = currentDirectory;
        _openDirectory(parentDir);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("File Manager", style: TextStyle(color: AppColors.white)), backgroundColor: AppColors.appColor),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10.0, top: 20, bottom: 10),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    _goBack();
                  },
                  child: const Icon(Icons.arrow_back)
                ),
                const SizedBox(width: 12),
                Text(currentDirectory?.path ?? '', style: const TextStyle(fontSize: 20),),
              ],
            ),
          ),
          isLoading
            ? const LinearProgressIndicator(color: AppColors.appColor)
            : const Divider(),
          Expanded(
            child: files.isEmpty
                ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_copy_outlined),
                    SizedBox(width: 10),
                    Text('No Content'),
                  ],
                )
                : ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      FileSystemEntity file = files[index];
                      return ListTile(
                        leading: Icon(file is Directory ? Icons.folder : Icons.insert_drive_file),
                        title: Text(file.path.split('/').last),
                        onTap: file is Directory
                            ? () => _openDirectory(file)
                            : () => _openFileWithIntent(File(file.path)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}