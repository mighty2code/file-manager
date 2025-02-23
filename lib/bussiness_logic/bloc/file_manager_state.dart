part of 'file_manager_bloc.dart';

@immutable
sealed class FileManagerState {}

final class FileManagerInitial extends FileManagerState {}
final class FileManagerLoading extends FileManagerState {}
final class FileManagerEmpty extends FileManagerState {}

final class FileManagerShowList extends FileManagerState {
  final List<FileSystemEntity> files;
  FileManagerShowList(this.files);
}

final class FileManagerError extends FileManagerState {
  final Object error;
  FileManagerError(this.error);
}