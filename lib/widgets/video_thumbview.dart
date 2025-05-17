import 'dart:io';
import 'package:file_manager/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class VideoThumbView extends StatelessWidget {
  final File video;
  final Size size;
  final double borderRadius;

  const VideoThumbView({
    super.key,
    required this.video,
    this.size = const Size(50, 50),
    this.borderRadius = 5,
  });

  Future<Widget> videoThumbnailWidget(String videoPath) async {
    final tempDir = await getTemporaryDirectory();
    final thumbPath = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: '${tempDir.path}/thumb.jpg',
      imageFormat: ImageFormat.JPEG,
      maxHeight: size.height.toInt(),
      quality: 40,
    );

    if (thumbPath == null) return const Icon(Icons.broken_image);

    return Image.file(
      File(thumbPath),
      width: size.width,
      height: size.height,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: size.width,
      height: size.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: FutureBuilder<Widget>(
          future: videoThumbnailWidget(video.path),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              return snapshot.data!;
            } else {
              return SizedBox(
                width: size.width/2.5,
                height: size.width/2.5,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 1, color: AppColors.appColor)),
              );
            }
          },
        ),
      ),
    );
  }
}