import 'package:file_manager/constants/app_colors.dart';
import 'package:flutter/material.dart';

class BookmarkTile extends StatelessWidget {
  const BookmarkTile({
    super.key,
    required this.title,
    this.leadingIcon,
    this.fontSize = 16,
    this.onTap,
  });

  final String title;
  final IconData? leadingIcon;
  final double fontSize;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(radius: fontSize, backgroundColor: AppColors.appColor.shade600, child: Icon(leadingIcon ?? Icons.circle, size: fontSize, color: AppColors.white)),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: fontSize)),
          ]
        ),
      ),
    );
  }
}