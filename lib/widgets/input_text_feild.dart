import 'package:file_manager/constants/app_colors.dart';
import 'package:flutter/material.dart';

class InputTextField extends StatelessWidget {
  final String? label;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final String? initialValue;
  final Widget? prefixIcon;
  final Widget? sufixIcon;
  final TextEditingController? controller;
  final Color? color;
  final double? height;
  final double? borderRadius;
  final Color? borderColor;
  final int? maxlines;
  final bool heightEnable;
  final bool boldStyle;
  final String? hintText;
  final bool? isObscureText;
  final TextInputType? keyboardType;
  final FloatingLabelBehavior floatingLabelBehavior;
  final TextStyle? style;
  final String? Function(String?)? validator;
  final bool readOnly;
  final EdgeInsets? contentPadding;

  const InputTextField(
      {super.key,
      this.height,
      this.maxlines,
      this.label,
      this.labelStyle,
      this.hintStyle,
      this.initialValue,
      this.prefixIcon,
      this.controller,
      this.color,
      this.borderColor,
      this.heightEnable = true,
      this.boldStyle = false,
      this.borderRadius,
      this.hintText,
      this.style,
      this.sufixIcon,
      this.isObscureText,
      this.keyboardType,
      this.floatingLabelBehavior = FloatingLabelBehavior.auto,
      this.validator,
      this.readOnly = false,
      this.contentPadding
      });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextFormField(
        readOnly: readOnly,
        validator: validator,
        /// DevChanges&FixesT108
        keyboardType: keyboardType,
        initialValue: initialValue,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        obscureText: isObscureText ?? false,
        enableSuggestions: !(isObscureText ?? false),
        autocorrect: !(isObscureText ?? false),
        maxLines: maxlines ?? 1,
        obscuringCharacter: "*",
        style:
            style ?? const TextStyle(fontSize:  15, color: Colors.black),
        cursorColor: AppColors.appColor,
        controller: controller,
        decoration: InputDecoration(
            isDense: true,
            contentPadding: contentPadding,
            floatingLabelBehavior: floatingLabelBehavior,
            prefixIcon: prefixIcon,
            suffixIcon: sufixIcon,
            filled: true,
            fillColor: color ?? AppColors.white,
            enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(borderRadius ?? 20),
                borderSide: BorderSide(
                  color: borderColor ?? const Color(0xFFD8D8D8),
                )),
            errorBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(borderRadius ?? 20),
                borderSide: BorderSide(
                  color: borderColor ?? const Color(0xFFD8D8D8),
                )),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(borderRadius ?? 20),
                borderSide: BorderSide(
                  color: borderColor ?? const Color(0xFFD8D8D8),
                )),
            focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(borderRadius ?? 20),
                borderSide: BorderSide(
                  color: borderColor ?? const Color(0xFFD8D8D8),
                )),
            border: const OutlineInputBorder(borderSide: BorderSide.none),
            labelText: label,
            hintText: hintText,
            hintStyle: hintStyle,
            floatingLabelStyle: boldStyle
                ? const TextStyle(
                    fontSize: 18, color: Colors.black)
                : const TextStyle(fontSize: 18, color:  Colors.black),
            labelStyle: labelStyle ?? const TextStyle(fontSize: 14, color: Colors.black)),
      ),
    );
  }
}