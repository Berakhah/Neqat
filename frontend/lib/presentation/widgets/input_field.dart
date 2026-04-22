import 'package:flutter/material.dart';

class CustomInputField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? errorText;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;

  const CustomInputField({
    super.key, 
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.errorText,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
    this.onEditingComplete,
  });

  @override
  _CustomInputFieldState createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextField(
      controller: widget.controller,
      obscureText: widget.obscureText ? _obscureText : false,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      onEditingComplete: widget.onEditingComplete,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        errorText: widget.errorText,
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        ),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}