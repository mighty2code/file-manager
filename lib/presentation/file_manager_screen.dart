import 'dart:io';
import 'package:file_manager/constants/app_colors.dart';
import 'package:file_manager/presentation/clip_board_menu.dart';
import 'package:file_manager/utils/dialog_utils.dart';
import 'package:file_manager/utils/file_utils.dart';
import 'package:file_manager/widgets/file_manager_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_manager/bussiness_logic/bloc/file_manager_bloc.dart';

class FileManagerScreen extends StatelessWidget {
  const FileManagerScreen({super.key});

  static final FileManagerBloc bloc = FileManagerBloc();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => bloc..init(),
      child: WillPopScope(
        onWillPop: () async {
          bloc.add(GoBackEvent());
          return false;
        },
        child: Scaffold(
            appBar: AppBar(
              title: const Text("File Manager",
                  style: TextStyle(color: AppColors.white)),
              backgroundColor: AppColors.appColor,
              iconTheme: const IconThemeData(color: AppColors.white),
            ),
            backgroundColor: AppColors.white,

            drawer: Drawer(
              child: Column(
                children: [
                  Container(
                    height: 167,
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

                  const Padding(
                    padding: EdgeInsets.only(top: 20, left: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bookmarks', style: TextStyle(fontSize: 15, color: AppColors.appColor, fontWeight: FontWeight.w600)),
                        SizedBox(height: 10),
                        ListTile(title: Text('Downloads')),
                        ListTile(title: Text('Documents')),
                        ListTile(title: Text('Pictures')),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            body: BlocBuilder<FileManagerBloc, FileManagerState>(
                builder: (context, state) {
              if (state is FileManagerError) {
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${state.error}')));
                  bloc.add(RefreshEvent());
                });
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 10.0, top: 20, bottom: 10),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            bloc.add(GoBackEvent());
                          },
                          child: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              bloc.currentDirectory?.path ?? '',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                  state is FileManagerLoading
                    ? const LinearProgressIndicator(color: AppColors.appColor)
                    : const Divider(),
                  Expanded(
                    child: state is FileManagerLoading
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.appColor),
                        ],
                      )
                      : state is FileManagerShowList || state is FileManagerPasteState || state is FileManagerError
                          ? RefreshIndicator(
                            color: AppColors.appColor,
                            onRefresh: () => Future.delayed(
                              const Duration(seconds: 1), () {
                                bloc.add(RefreshEvent());
                              }
                            ),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 70),
                              itemCount: bloc.entities.length,
                              cacheExtent: 1000,
                              itemBuilder: (context, index) {
                                FileSystemEntity entity =
                                    bloc.entities[index];
                                return FileManagerListTile(
                                  entity: entity,
                                  bloc: bloc,
                                  onSelect: (entityType) {
                                    bloc.add(SelectEntityEvent(
                                        entity: entity, type: entityType));
                                  },
                                  onUnselect: (entityType) {
                                    bloc.add(UnselectEntityEvent(
                                        entity: entity, type: entityType));
                                  },
                                  isSelectable: bloc.clipBoardEntities.isEmpty,
                                  isSelected: bloc.selectedEntities
                                      .contains(entity) || bloc.clipBoardEntities.contains(entity),
                                );
                              },
                            ),
                          )
                          : state is FileManagerEmpty
                              ? const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.folder_copy_outlined),
                                    SizedBox(width: 10),
                                    Text('No Content'),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error),
                                    SizedBox(width: 10),
                                    Text('Someting goes Wrong'),
                                  ],
                                ),
                    ),
                ],
              );
            }),
            bottomNavigationBar: BlocBuilder<FileManagerBloc, FileManagerState>(
                builder: (context, state) {
                return bloc.selectedEntities.isNotEmpty || bloc.clipBoardEntities.isNotEmpty ? ClipBoardMenu(bloc: bloc) : const SizedBox.shrink();
              }
            ),  
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.appColor.shade100,
              child: FloatingMenu(bloc: bloc),
            ),
        ),
      ),
    );
  }
}

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