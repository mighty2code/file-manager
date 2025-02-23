import 'package:bloc/bloc.dart';
import 'package:file_manager/presentation/file_manager_screen.dart';
import 'package:flutter/material.dart';
import 'package:pretty_bloc_observer/pretty_bloc_observer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  // ]);
  Bloc.observer = PrettyBlocObserver();
  runApp(const FileManagerApp());
}

class FileManagerApp extends StatelessWidget {
  const FileManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FileManagerScreen(),
    );
  }
}