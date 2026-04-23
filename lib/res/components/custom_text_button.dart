import 'dart:async';
import 'package:flutter/material.dart';

class CustomTextButton extends StatefulWidget {
  final String text;
  final FutureOr<void> Function()? onPressed;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsets padding;
  final bool isLoading;

  const CustomTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor = Colors.deepPurple,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    this.isLoading = false,
  });

  @override
  State<CustomTextButton> createState() => _CustomTextButtonState();
}

class _CustomTextButtonState extends State<CustomTextButton> {
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
    final bool loading = widget.isLoading || _innerLoading;

    return TextButton(
      onPressed: loading ? null : _handlePress,
      style: TextButton.styleFrom(
        padding: widget.padding,
        foregroundColor: widget.textColor,
      ),
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            )
          : Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
                color: widget.textColor,
              ),
            ),
    );
  }
}
