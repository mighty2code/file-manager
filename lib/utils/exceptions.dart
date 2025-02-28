import 'package:file_manager/constants/constants.dart';
import 'package:flutter/services.dart';

class ExceptionUtils {
  static ErrorSeverity isFatalError(Object error) {
    // Prioritize specific fatal errors
    if (error is OutOfMemoryError || error is StackOverflowError || (error is Exception && error.runtimeType.toString().toLowerCase().contains('fatal'))) {
      return ErrorSeverity.critical;
    }

    // Check for assertions with clear fatal indications
    if (error is AssertionError) {
      if (error.message?.toString().toLowerCase().contains('fatal') == true ||
            error.message?.toString().toLowerCase().contains('crash') == true) return ErrorSeverity.critical;
    }

    if(error is Exception && (error.runtimeType.toString().toLowerCase().contains('network') || error.runtimeType.toString().toLowerCase().contains('timeout'))) {
        return ErrorSeverity.minor;
    }

    // Use a stricter regex for generic "Assertion failed" errors
    final isAssertionFailure = error.toString().toLowerCase().contains(RegExp(r'assertion failed: .+'));

    // Consider error type and platform-specific details for better categorization
    switch (error.runtimeType) {
      // case FirebaseException:
      //   return ErrorSeverity.major;
      case PlatformException _:
        return ErrorSeverity.major;
      default:
        return isAssertionFailure ? ErrorSeverity.moderate : ErrorSeverity.minor;
    }
  }
}