import 'package:file_manager/constants/app_colors.dart';
import 'package:file_manager/widgets/input_text_feild.dart';
import 'package:flutter/material.dart';

class DialogUtils {
  static showInputBox(
    BuildContext context,
    {String title = 'Write Content',
    String hintText = 'Type Content here',
    String buttonText = 'Ok',
    Function()? onCancel,
    Function(String value)? onSubmit}) {
    
    TextEditingController inputController = TextEditingController();

    showDialog(context: context, builder:(context) {
      return AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(title, style: const TextStyle(fontSize: 18, color: AppColors.appColor, fontWeight: FontWeight.bold)),
              ),
              InputTextField(
                controller: inputController,
                color: AppColors.appColor.shade50,
                borderRadius: 10,
                borderColor: AppColors.appColor,
                boldStyle: true,
                style: const TextStyle(
                  fontSize: 12),
                hintText: hintText,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                validator: (s) => s == null || s.isEmpty ? 'Please ${hintText.toLowerCase()}.' : null,
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                onCancel?.call();
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: AppColors.appColor, fontWeight: FontWeight.bold))
            ),
          ),
          InkWell(
            onTap: () {
              onSubmit?.call(inputController.text);
              Navigator.pop(context);
            },
            child: Text(buttonText, style: const TextStyle(color: AppColors.appColor, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    });
  }
}