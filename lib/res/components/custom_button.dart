import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spendly/utils/colors.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final FutureOr<void> Function()? onPressed;
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
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _innerLoading = false;

  Future<void> _handlePress() async {
    if (widget.onPressed == null) return;

    // Hide keyboard when button is clicked
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _innerLoading = true;
    });

    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() {
          _innerLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = widget.backgroundColor ?? AppColors.primary;
    final effectiveTextColor = widget.textColor ?? Colors.white;
    final bool loading = widget.isLoading || _innerLoading;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ElevatedButton(
        onPressed: loading ? null : _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          elevation: widget.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          padding: widget.padding,
          disabledBackgroundColor: effectiveBackgroundColor.withOpacity(0.6),
        ),
        child: loading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: effectiveTextColor,
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
