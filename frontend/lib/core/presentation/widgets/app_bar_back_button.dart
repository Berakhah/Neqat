import 'package:flutter/material.dart';

class AppBarBackButton extends StatelessWidget {
  final Color? color;
  final VoidCallback? onPressed;

  const AppBarBackButton({
    Key? key,
    this.color,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      color: color ?? Theme.of(context).appBarTheme.iconTheme?.color,
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }
} 