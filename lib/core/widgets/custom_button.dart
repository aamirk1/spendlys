import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spendly/core/theme/colors.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final FutureOr<void> Function()? onPressed;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? textColor;
  final double fontSize;
  final double borderRadius;
  final EdgeInsets padding;
  final double elevation;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;
  final bool isDisabled;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.gradient,
    this.textColor,
    this.fontSize = 16,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.elevation = 2,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 54,
    this.isDisabled = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  bool _innerLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (widget.onPressed == null ||
        widget.isDisabled ||
        widget.isLoading ||
        _innerLoading) {
      return;
    }

    HapticFeedback.lightImpact();
    _animationController.reverse(); // Restore scale on tap activation

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
    final bool disabled =
        widget.isDisabled || widget.onPressed == null || loading;

    final effectiveBackgroundColor =
        widget.backgroundColor ?? AppColors.primary;
    final effectiveTextColor = widget.textColor ?? Colors.white;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: !disabled
              ? (widget.gradient ??
                  LinearGradient(
                    colors: [
                      effectiveBackgroundColor,
                      effectiveBackgroundColor.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ))
              : null,
          color: disabled
              ? effectiveBackgroundColor.withValues(alpha: 0.5)
              : (widget.gradient == null ? effectiveBackgroundColor : null),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: effectiveBackgroundColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : _handlePress,
            onTapDown: disabled ? null : (_) => _animationController.forward(),
            onTapCancel: disabled ? null : () => _animationController.reverse(),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Padding(
              padding: widget.padding,
              child: Center(
                child: loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            widget.icon!,
                            const SizedBox(width: 10),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              color: effectiveTextColor,
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
