import 'package:file_manager/bussiness_logic/bloc/file_manager_bloc.dart';
import 'package:file_manager/constants/app_colors.dart';
import 'package:flutter/material.dart';

class ClipBoardMenu extends StatelessWidget {
  const ClipBoardMenu({
    super.key,
    required this.bloc,
  });

  final FileManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
      color: AppColors.white,
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
                  Row(
                    children: [
                      InkWell(
                        onTap: () => bloc.add(SelectAllEntityEvent()),
                        child: const Icon(Icons.select_all)
                      ),
                      const SizedBox(width: 20),
                      InkWell(
                        onTap: () => bloc.add(UnselectAllEntityEvent()),
                        child: const Icon(Icons.deselect)
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => bloc.add(ShareEvent()),
                        child: const Icon(Icons.share)
                      ),
                      const SizedBox(width: 20),
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
                      const SizedBox(width: 10),

                      PopupMenuButton<String>(
                        surfaceTintColor: AppColors.white,
                        offset: const Offset(10, 10),
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem<String>(
                              onTap: () => bloc.add(ArchiveEvent()),
                              child: const Row(
                                children: [
                                  Icon(Icons.archive),
                                  SizedBox(width: 10),
                                  Text('Archive'),
                                ],
                              ),
                            ),
                          if(bloc.isSelectionHaveOnlyAZipFile())
                            PopupMenuItem<String>(
                              onTap: () => bloc.add(ExtractFileEvent()),
                              child: const Row(
                                children: [
                                  Icon(Icons.unarchive),
                                  SizedBox(width: 10),
                                  Text('Extract'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              // onTap: () => bloc.add(ArchiveEvent()),
                              child: Row(
                                children: [
                                  Icon(Icons.info),
                                  SizedBox(width: 10),
                                  Text('Get Info'),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ]
                  ),
                ],
              ),
          ),
          
        ]
      ),
    );
  }
}