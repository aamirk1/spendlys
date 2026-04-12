import 'package:flutter/material.dart';
import 'package:spendly/utils/colors.dart';
import 'package:spendly/res/components/shimmer_loading.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;
  final double borderRadius;
  final EdgeInsets padding;
  final double elevation;
  final bool isLoading;
  final Widget? icon;
  final double width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 16,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
    this.elevation = 4,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
    final effectiveTextColor = textColor ?? Colors.white;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          elevation: elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding,
        ),
        child: isLoading
            ? const ButtonShimmer()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: effectiveTextColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
