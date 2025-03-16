import 'dart:io';

import 'package:file_manager/bussiness_logic/bloc/file_manager_bloc.dart';
import 'package:file_manager/constants/app_colors.dart';
import 'package:file_manager/constants/constants.dart';
import 'package:file_manager/data/local/shared_prefs.dart';
import 'package:file_manager/widgets/bookmark_tile.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class QuickDrawer extends StatelessWidget {
  
  const QuickDrawer({
    super.key,
    required this.bloc,
  });

  final FileManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).padding.top + kToolbarHeight + 67,
            color: AppColors.appColor.shade700,
            padding: const EdgeInsets.only(bottom: 10, left: 15, right: 15),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('File Manager', style: TextStyle(fontSize: 24, color: AppColors.white, fontWeight: FontWeight.w600)),
                    Icon(Icons.settings, color: AppColors.white),
                  ],
                ),
              ],
            ),
          ),
    
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Storage', style: TextStyle(fontSize: 15, color: AppColors.appColor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                
                if(SharedPrefs.getString(StorageType.internal.name) != null)
                  BookmarkTile(title: 'Internal Storage',
                  leadingIcon: Icons.storage_rounded, 
                    onTap: () async {
                      bloc.add(OpenDirectoryEvent(Directory(SharedPrefs.getString(StorageType.internal.name)!)));
                      Navigator.pop(context);
                    },
                  ),
                if(SharedPrefs.getString(StorageType.sdcard.name) != null)
                  BookmarkTile(title: 'SD Card', leadingIcon: Icons.sd_card_rounded, 
                    onTap: () async {
                      if((SharedPrefs.getString(SharedPrefKeys.sdcardUri) ?? '').isEmpty) {
                        await bloc.grantSDCardPermission(SharedPrefs.getString(StorageType.sdcard.name)!);
                      }
                      bloc.add(OpenDirectoryEvent(Directory(SharedPrefs.getString(StorageType.sdcard.name)!)));
                      Navigator.pop(context);
                    },
                  ),

                const SizedBox(height: 8),
                const Text('Bookmarks', style: TextStyle(fontSize: 15, color: AppColors.appColor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                
                if(SharedPrefs.getString(StorageType.download.name) != null)
                  BookmarkTile(title: 'Downloads', leadingIcon: Icons.download_rounded,
                    onTap: () async {
                      bloc.add(OpenDirectoryEvent(Directory(SharedPrefs.getString(StorageType.download.name)!)));
                      Navigator.pop(context);
                    },
                  ),
                if(SharedPrefs.getString(StorageType.documents.name) != null)
                  BookmarkTile(title: 'Documents', leadingIcon: Icons.insert_drive_file_rounded,
                    onTap: () async {
                      bloc.add(OpenDirectoryEvent(Directory(SharedPrefs.getString(StorageType.documents.name)!)));
                      Navigator.pop(context);
                    },
                  ),
                if(SharedPrefs.getString(StorageType.pictures.name) != null)
                  BookmarkTile(title: 'Pictures', leadingIcon: Icons.photo,
                    onTap: () async {
                      bloc.add(OpenDirectoryEvent(Directory(SharedPrefs.getString(StorageType.pictures.name)!)));
                      Navigator.pop(context);
                    },
                  ),
                if(SharedPrefs.getString(StorageType.music.name) != null)
                  BookmarkTile(title: 'Music', leadingIcon: Icons.music_note,
                    onTap: () async {
                      bloc.add(OpenDirectoryEvent(Directory(SharedPrefs.getString(StorageType.music.name)!)));
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
