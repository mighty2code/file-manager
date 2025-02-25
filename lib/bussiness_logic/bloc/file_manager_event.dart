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

final class UnselectEntityEvent extends FileManagerEvent {
  final FileSystemEntity entity;
  final EntityType type;
  UnselectEntityEvent({required this.entity, required this.type});
}

final class SelectAllEntityEvent extends FileManagerEvent {}
final class UnselectAllEntityEvent extends FileManagerEvent {}

final class ShareEvent extends FileManagerEvent {}
final class CopyEvent extends FileManagerEvent {}
final class MoveEvent extends FileManagerEvent {}
final class DeleteEvent extends FileManagerEvent {}
final class PasteEvent extends FileManagerEvent {}

final class ArchiveEvent extends FileManagerEvent {}
final class ExtractFileEvent extends FileManagerEvent {}

final class RefreshEvent extends FileManagerEvent {}

final class GoBackEvent extends FileManagerEvent {}
