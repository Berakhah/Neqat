import 'package:flutter/material.dart';

class PreferenceSlider extends StatelessWidget {
  // This can accept either the core Tag or the preferences Tag
  final dynamic tag;
  final int preferenceLevel;
  final ValueChanged<int> onChanged;

  const PreferenceSlider({
    super.key,
    required this.tag,
    required this.preferenceLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Extract name and description regardless of tag type
    final String name = tag.name;
    final String? description = tag.description;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description ?? 'No description available',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Rarely', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: preferenceLevel.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _getLabelText(preferenceLevel),
                    onChanged: (double value) {
                      onChanged(value.round());
                    },
                  ),
                ),
                const Text('Often', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLabelText(int value) {
    if (value == 0) return "Never";
    if (value < 3) return "Rarely";
    if (value < 7) return "Sometimes";
    if (value < 10) return "Often";
    return "Very Often";
  }
}
