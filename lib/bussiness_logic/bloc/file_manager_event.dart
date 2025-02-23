part of 'file_manager_bloc.dart';

@immutable
sealed class FileManagerEvent {}

final class FileManagerStartup extends FileManagerEvent {}

final class OpenDirectoryEvent extends FileManagerEvent {
  final Directory? directory;
  OpenDirectoryEvent(this.directory);
}

final class OpenFileEvent extends FileManagerEvent {
  final File? file;
  OpenFileEvent(this.file);
}

final class SelectEntityEvent extends FileManagerEvent {
  final FileSystemEntity entity;
  final EntityType type;
  SelectEntityEvent({required this.entity, required this.type});
}

final class GoBackEvent extends FileManagerEvent {}
