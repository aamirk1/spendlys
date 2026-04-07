import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final Widget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.backgroundColor = Colors.blue,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      bottom: bottom as PreferredSizeWidget?,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    double bottomHeight = 0;
    if (bottom is PreferredSizeWidget) {
      bottomHeight = (bottom as PreferredSizeWidget).preferredSize.height;
    } else if (bottom != null) {
      bottomHeight = 48.0; // Fallback for legacy behavior
    }
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}
