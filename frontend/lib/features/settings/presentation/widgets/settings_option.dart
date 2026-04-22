import 'package:flutter/material.dart';

class SettingsOption extends StatelessWidget {
  const SettingsOption({
    super.key,
    required this.listTiles,
    this.isDark = false,
  });

  final List<Widget> listTiles;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10.0),
      child: Column(children: listTiles),
    );
  }
}
