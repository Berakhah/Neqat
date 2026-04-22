import 'package:flutter/material.dart';

class CustomGoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomGoogleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent, 
        foregroundColor: Colors.black87,
        minimumSize: const Size(60, 60), 
        shape: const CircleBorder(), 
        elevation: 5, 
        padding: const EdgeInsets.all(10), 
        side: BorderSide(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Image.asset(
        'images/google.png',
        fit: BoxFit.contain, 
      ),
    );
  }
}