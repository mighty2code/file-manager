import 'package:file_manager/constants/app_colors.dart';
import 'package:file_manager/constants/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UIErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;
  const UIErrorWidget({
    super.key,
    required this.errorDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: kReleaseMode && AppConfig.areLogsEnabled || kDebugMode ? Column(
      children: [
        AppBar(title: const Text('UI Error [Developer Logs]')),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: .10, bottom: 80),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error, color: AppColors.red),
                      const SizedBox(width: 5),
                      Flexible(child: Text('Caught Unhandled Exception - ${errorDetails.exception}', maxLines: 10, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: Colors.orange),
                      const SizedBox(width: 5),
                      Flexible(
                        child: RichText(text: TextSpan(text: 'Stacktrace - ', style: const TextStyle(fontSize: 14), children: [
                          TextSpan(text: '${errorDetails.stack}', style: const TextStyle(fontSize: 12)),
                        ])),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      ) : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Icon(Icons.warning_amber, size: 100, color: AppColors.red),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Something Went Wrong. UI has been broken. Sorry for the inconvience.', textAlign: TextAlign.center, maxLines: 5, style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 100),
            ]
          ),
    );
  }
}