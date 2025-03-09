import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:file_manager/presentation/file_manager_screen.dart';
import 'package:file_manager/widgets/ui_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:pretty_bloc_observer/pretty_bloc_observer.dart';
import 'constants/constants.dart';
import 'utils/exceptions.dart';

void main0() {
  WidgetsFlutterBinding.ensureInitialized();
  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  // ]);
  Bloc.observer = PrettyBlocObserver();  
  runApp(const FileManagerApp());
}

void main() async {
  // Run the app within a guarded zone to catch unhandled async errors
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    Bloc.observer = PrettyBlocObserver();

    // Catch framework-level Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      catchAllExceptions(details.exception, details.stack, errorCategory: 'unhandled-sync');
    };
    ErrorWidget.builder = (details) {
      return UIErrorWidget(errorDetails: details);
    };
    runApp(const FileManagerApp());
  }, catchAllExceptions);
}


Future<void> catchAllExceptions(Object error, StackTrace? stack, {String errorCategory = 'unhandled-async'}) async {
  // Set custom context for the error report
  // await setFirbaseCrashlyticsCustomKeys(error, errorCategory);
  ErrorSeverity errorSeverity = ExceptionUtils.isFatalError(error);
  // Debug print to log errors in debug mode
  debugPrint('DebugX: Caught Unhandled Exception [${error.runtimeType}] [$errorSeverity] - $error,\nStacktrace - $stack');
}

class FileManagerApp extends StatelessWidget {
  const FileManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PageView(
        children: const [
          FileManagerScreen(),
          // FileManagerScreen(),
        ],
      ),
    );
  }
}