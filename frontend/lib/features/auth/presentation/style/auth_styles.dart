import 'package:flutter/material.dart';

/// A class containing styles for authentication screens to ensure a consistent,
/// professional appearance across all auth-related screens.
class AuthStyles {
  static InputDecoration getInputDecoration({
    required ThemeData theme,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1), width: 1.0),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
        size: 22,
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
    );
  }

  static BoxDecoration getCardDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20.0,
          spreadRadius: 0.0,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  static TextStyle getHeadingStyle(ThemeData theme) {
    return theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.primaryColor,
      fontSize: 28.0,
    ) ?? const TextStyle();
  }

  static TextStyle getSubheadingStyle(ThemeData theme) {
    return theme.textTheme.bodyMedium?.copyWith(
      color: theme.textTheme.bodySmall?.color,
      fontSize: 16.0,
    ) ?? const TextStyle();
  }

  static Widget buildErrorContainer(String message, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      margin: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildSuccessContainer(String message, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      margin: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildOrDivider(String text, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: theme.dividerColor,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            text,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: theme.dividerColor,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  static Widget buildValidationIndicator({
    required bool isValid,
    required String message,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            size: 16,
            color: isValid ? Colors.green : theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: isValid ? Colors.green : theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 