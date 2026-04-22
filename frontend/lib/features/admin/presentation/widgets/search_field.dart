import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String hintText;
  final VoidCallback onClear;
  final bool autofocus;
  
  const SearchField({
    Key? key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search...',
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onClear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onChanged: onChanged,
      ),
    );
  }
} 