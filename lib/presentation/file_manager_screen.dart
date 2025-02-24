import 'dart:io';
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
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
            body: BlocBuilder<FileManagerBloc, FileManagerState>(
                builder: (context, state) {
              if (state is FileManagerError) {
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${state.error}')));
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
                      ? const LinearProgressIndicator(color: Colors.red)
                      : const Divider(),
                  Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          state is FileManagerLoading
                              ? const CircularProgressIndicator()
                              : state is FileManagerShowList || state is FileManagerPasteState
                                  ? ListView.builder(
                                      padding: const EdgeInsets.only(bottom: 70),
                                      itemCount: bloc.entities.length,
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

                                        if(bloc.selectedEntities.isNotEmpty || bloc.clipBoardEntities.isNotEmpty)
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        decoration: const BoxDecoration(
                                        color: Colors.white,
                                        border: Border(top: BorderSide())
                                        ),
                                        height: 70,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if(bloc.clipBoardEntities.isNotEmpty)
                                              InkWell(
                                                onTap: () => bloc.add(PasteEvent()),
                                                child: const Icon(Icons.paste)
                                              )
                                            else Expanded(
                                              child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    InkWell(
                                                      onTap: () => bloc.add(SelectAllEntityEvent()),
                                                      child: const Icon(Icons.select_all)
                                                    ),
                                                    Row(
                                                      children: [
                                                        InkWell(
                                                          onTap: () => bloc.add(CopyEvent()),
                                                          child: const Icon(Icons.copy)
                                                        ),
                                                        const SizedBox(width: 20),
                                                        InkWell(
                                                          onTap: () => bloc.add(MoveEvent()),
                                                          child: const Icon(Icons.cut)
                                                        ),
                                                        const SizedBox(width: 20),
                                                        InkWell(
                                                          onTap: () => bloc.add(DeleteEvent()),
                                                          child: const Icon(Icons.delete)
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                            ),
                                            
                                          ]
                                        ),
                                      )
                                    )
                        ],
                      )),
                ],
              );
            })),
      ),
    );
  }
}
