import 'dart:io';
import 'package:file_manager/bussiness_logic/bloc/file_manager_bloc.dart';
import 'package:file_manager/constants/app_colors.dart';
import 'package:file_manager/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FileManagerListTile extends StatefulWidget {
  const FileManagerListTile({
    super.key,
    required this.entity,
    required this.bloc,
    this.onSelect,
    this.onUnselect,
    this.isSelected = false,
    this.isSelectable = true,
  });

  final FileSystemEntity entity;
  final FileManagerBloc bloc;
  final Function(EntityType entityType)? onSelect;
  final Function(EntityType entityType)? onUnselect;
  final bool isSelected;
  final bool isSelectable;

  @override
  State<FileManagerListTile> createState() => _FileManagerListTileState();
}

class _FileManagerListTileState extends State<FileManagerListTile> {
  bool isSelected = false;
  FileStat? stats;

  @override
  void initState() {
    initObjects();
    super.initState();
  }

  initObjects() async {
    stats = await widget.entity.stat();
    // debugPrint(stats.toString());
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant FileManagerListTile oldWidget) {
    isSelected = widget.isSelected;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () {
        if(!widget.isSelectable) return;
        setState(() {
          isSelected = true;
        });
        callOnSelect();
      },
      onTap: () {
        if (widget.bloc.selectedEntities.isNotEmpty && widget.isSelectable) {
          setState(() {
            isSelected = !isSelected;
          });
          isSelected ? callOnSelect() : callOnUnselect();
        } else {
          widget.entity is Directory
              ? widget.bloc.add(OpenDirectoryEvent(widget.entity as Directory))
              : widget.bloc.add(OpenFileEvent(File(widget.entity.path)));
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 3),
        color: isSelected
            ?  AppColors.appColor.shade100
            : AppColors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: ListTile(
          selectedColor: AppColors.appColor.shade50,
          leading: Icon(widget.entity is Directory
              ? Icons.folder
              : Icons.insert_drive_file),
          title: Text(widget.entity.path.split('/').last),
          subtitle: stats != null ? Text('${DateFormat('yyyy/MM/dd hh:mm a').format(stats!.modified)}' /*, ${stats!.size.getSize()}' */, style: const TextStyle(fontSize: 11, color: AppColors.grey)) : null,
        ),
      ),
    );
  }

  void callOnSelect() {
    widget.onSelect?.call(
        widget.entity is Directory ? EntityType.directory : EntityType.file);
  }

  void callOnUnselect() {
    widget.onUnselect?.call(
        widget.entity is Directory ? EntityType.directory : EntityType.file);
  }
}
