import 'package:flutter/material.dart';

class LocationMapChart extends StatelessWidget {
  final Map<String, int> locationData;
  
  const LocationMapChart({
    super.key,
    required this.locationData,
  });

  @override
  Widget build(BuildContext context) {
    if (locationData.isEmpty) {
      return const Center(
        child: Text('No location data available'),
      );
    }

    // Sort data by value (highest first)
    final sortedData = locationData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Calculate total users for percentage
    final int totalUsers = locationData.values.fold(0, (sum, count) => sum + count);
    
    // Find max value for scaling
    final int maxValue = sortedData.first.value;
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: List.generate(sortedData.length, (index) {
                  final entry = sortedData[index];
                  final location = entry.key;
                  final count = entry.value;
                  final double percentage = totalUsers > 0 
                      ? (count / totalUsers) * 100 
                      : 0;
                  
                  // Scale bar width based on percentage
                  final double barWidth = percentage * 2; // Max width would be 200
                  
                  // Generate a color based on the entry index (first items are darker)
                  final color = HSLColor.fromAHSL(
                    1.0,
                    220, // blue hue
                    0.8, 
                    0.5 - (index * 0.3 / sortedData.length), // darken as index increases
                  ).toColor();
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                height: 24,
                                width: (barWidth / 100) * MediaQuery.of(context).size.width * 0.6,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            '${count.toString()} (${percentage.toStringAsFixed(1)}%)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'User Distribution by Location',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
} 