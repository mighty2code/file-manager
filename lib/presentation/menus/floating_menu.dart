import 'package:file_manager/bussiness_logic/bloc/file_manager_bloc.dart';
import 'package:file_manager/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/utils/dialog_utils.dart';

class FloatingMenu extends StatefulWidget {
  const FloatingMenu({
    super.key,
    required this.bloc,
  });

  final FileManagerBloc bloc;

  @override
  State<FloatingMenu> createState() => _FloatingMenuState();
}

class _FloatingMenuState extends State<FloatingMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0,
      upperBound: 0.625
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(10, -140),
      popUpAnimationStyle: AnimationStyle(
        curve: Curves.easeOut,                   // Forward animation curve
        duration: const Duration(milliseconds: 400),  // Forward animation duration
        reverseCurve: Curves.easeIn,           // Reverse animation curve when closing
        reverseDuration: const Duration(milliseconds: 400), // Reverse animation duration
      ),
      color: AppColors.appColor.shade50,
      child: RotationTransition(
        turns: _controller,
        child: const Icon(
          Icons.add,
          size: 30,
          color: AppColors.appColor
        ),
      ),
      onOpened: () {
        _controller.forward();
        // FileUtils.trimAudio(path: '/storage/emulated/0/New/audioTrimmed.m4a.m4a', outputPath: '/storage/emulated/0/New/output.m4a', startTime: 1, endTime: 3);
      },
      onCanceled: () {
        _controller.reverse();
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            onTap: () => DialogUtils.showInputBox(
              context,
              title: 'Create a folder',
              hintText: 'Enter folder name',
              buttonText: 'Create',
              onSubmit: (value) {
                widget.bloc.add(CreateNewDirectoryEvent(name: value));
              }
            ),
            child: Row(
              children: [
                Icon(Icons.folder, color: AppColors.appColor.shade900),
                const SizedBox(width: 10),
                const Text('New Folder'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            onTap: () => DialogUtils.showInputBox(
              context,
              title: 'Create a file',
              hintText: 'Enter file name',
              buttonText: 'Create',
              onSubmit: (value) {
                widget.bloc.add(CreateNewFileEvent(name: value));
              }
            ),
            child:  Row(
              children: [
                Icon(Icons.insert_drive_file, color: AppColors.appColor.shade900),
                const SizedBox(width: 10),
                const Text('New File'),
              ],
            ),
          ),
        ];
      },
    );
  }
}