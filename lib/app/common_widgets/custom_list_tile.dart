import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final Icon icon;
  final Color? trailingIconColor;

  const CustomListTile({
    super.key,
    required this.title,
    required this.onPressed,
    required this.icon,
    this.trailingIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios,
          color: trailingIconColor ?? Colors.grey),
      onTap: onPressed,
    );
  }
}
