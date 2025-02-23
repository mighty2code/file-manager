import 'dart:io';
import 'package:file_manager/constants/constants.dart';
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
            title: const Text("File Manager", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
          body: BlocBuilder<FileManagerBloc, FileManagerState>(
            builder: (context, state) {
              if(state is FileManagerError) {
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
                });
              }
        
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, top: 20, bottom: 10),
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
                    child: state is FileManagerLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state is FileManagerShowList
                        ? ListView.builder(
                          itemCount: state.files.length,
                          itemBuilder: (context, index) {
                            FileSystemEntity entity = state.files[index];
                            return FileManagerListTile(
                              entity: entity,
                              bloc: bloc,
                              onSelect: (entityType) {
                                bloc.add(SelectEntityEvent(entity: entity, type: entityType));
                              },
                              isSelected: bloc.selectedEntities.contains(entity)
                            );
                          },
                        )
                        : state is FileManagerEmpty
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_copy_outlined),
                                SizedBox(width: 10),
                                Text('No Content'),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error),
                                SizedBox(width: 10),
                                Text('Someting goes Wrong'),
                              ],
                            )
                  ),
                ],
              );
            }
          )
        ),
      ),
    );
  }
}

class FileManagerListTile extends StatelessWidget {
  const FileManagerListTile({
    super.key,
    required this.entity,
    required this.bloc,
    this.onSelect,
    this.isSelected = false,
  });

  final FileSystemEntity entity;
  final FileManagerBloc bloc;
  final Function(EntityType entityType)? onSelect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedColor: Colors.red.shade50,
      leading: Icon(entity is Directory ? Icons.folder : Icons.insert_drive_file),
      title: Text(entity.path.split('/').last),
      onLongPress: onSelect?.call(entity is Directory ? EntityType.directory : EntityType.file),
      onTap: () {
        entity is Directory
          ? bloc.add(OpenDirectoryEvent(entity as Directory))
          : bloc.add(OpenFileEvent(File(entity.path)));
      }
    );
  }
}