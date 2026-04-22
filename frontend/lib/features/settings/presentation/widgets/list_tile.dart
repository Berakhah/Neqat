import 'package:flutter/material.dart';
import 'package:frontend/app/themes.dart';

class ListTiles extends StatelessWidget {
  const ListTiles({
    super.key,
    required this.leadingIcon,
    required this.leadingText,
    required this.trailingWidget,
    // required this.iconBackgroundColor,
    this.isDark = false,
  });

  final IconData leadingIcon;
  final String leadingText;
  final Widget trailingWidget;
  // final Color? iconBackgroundColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                // color: iconBackgroundColor,
              ),
              child: Icon(leadingIcon, size: 23.0),
            ),
            const SizedBox(width: 6.0),
            Text(leadingText, style: getDeliusTextStyle(isDark: isDark)),
          ],
        ),
        SizedBox(width: 50, height: 20, child: trailingWidget),
      ],
    );
  }
}
