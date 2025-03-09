import 'package:file_manager/bussiness_logic/bloc/file_manager_bloc.dart';
import 'package:file_manager/constants/app_colors.dart';
import 'package:file_manager/constants/constants.dart';
import 'package:file_manager/widgets/bookmark_tile.dart';
import 'package:flutter/material.dart';

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
                
                BookmarkTile(
                  title: 'Internal Storage',
                  leadingIcon: Icons.storage_rounded,
                  onTap: () {
                    bloc.init();
                  },
                ),
                BookmarkTile(
                  title: 'SD Card',
                  leadingIcon: Icons.sd_card_rounded, 
                  onTap: () {
                    bloc.init(storageType: StorageType.sdcard);
                  }
                ),
                
                const SizedBox(height: 8),
                const Text('Bookmarks', style: TextStyle(fontSize: 15, color: AppColors.appColor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                
                const BookmarkTile(title: 'Downloads', leadingIcon: Icons.download_rounded),
                const BookmarkTile(title: 'Documents', leadingIcon: Icons.insert_drive_file_rounded),
                const BookmarkTile(title: 'Pictures', leadingIcon: Icons.photo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
