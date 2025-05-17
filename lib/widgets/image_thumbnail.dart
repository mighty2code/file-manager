import 'dart:io';
import 'package:flutter/material.dart';

class ImageThumbnail extends StatelessWidget {
  final File image;
  final Size size;
  final double borderRadius;

  const ImageThumbnail({
    super.key,
    required this.image,
    this.size = const Size(50, 50),
    this.borderRadius = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: size.width,
      height: size.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image.existsSync() ? Image.file(
          image,
          width: size.width,
          height: size.height,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading image thumbnail: $error');
            return Icon(Icons.broken_image, color: Colors.grey, size: size.width);
          },
        ) : Icon(Icons.broken_image, color: Colors.grey, size: size.width),
      ),
    );
  }
}
