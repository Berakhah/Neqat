import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String assetName;
  final double size;

  const SocialLoginButton({
    required this.onPressed,
    required this.assetName,
    this.size = 40.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset(
              assetName,
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}