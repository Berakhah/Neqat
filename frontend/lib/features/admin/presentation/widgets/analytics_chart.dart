import 'package:flutter/material.dart';

class AnalyticsChart extends StatelessWidget {
  final List<int> data;
  final String label;
  final Color color;

  const AnalyticsChart({
    Key? key,
    required this.data,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _ChartPainter(
                  data: data,
                  color: color,
                  backgroundColor: Theme.of(context).cardColor,
                  textColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<int> data;
  final Color color;
  final Color backgroundColor;
  final Color textColor;

  _ChartPainter({
    required this.data,
    required this.color,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double bottomPadding = 20;
    final double leftPadding = 30;
    final double chartHeight = height - bottomPadding;
    final double chartWidth = width - leftPadding;

    // Create paint for the grid lines
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Create paint for the chart line
    final Paint linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Find the max value for scaling
    final int maxValue = data.reduce((a, b) => a > b ? a : b);
    final double scale = maxValue > 0 ? chartHeight / maxValue : 1;

    // Draw horizontal grid lines and value labels
    final int numGridLines = 5;
    for (int i = 0; i <= numGridLines; i++) {
      final double y = chartHeight - (i * chartHeight / numGridLines);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(width, y),
        gridPaint,
      );

      // Draw value labels
      final int value = (maxValue * i / numGridLines).round();
      final TextSpan span = TextSpan(
        text: value.toString(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final TextPainter tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(5, y - tp.height / 2));
    }

    // Draw vertical grid lines and time labels
    final int numPoints = data.length;
    for (int i = 0; i < numPoints; i += numPoints ~/ 6) {
      final double x = leftPadding + (i * chartWidth / (numPoints - 1));
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, chartHeight),
        gridPaint,
      );

      // Draw time labels
      final TextSpan span = TextSpan(
        text: i.toString(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final TextPainter tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 5));
    }

    // Draw the chart line
    final Path path = Path();
    for (int i = 0; i < data.length; i++) {
      final double x = leftPadding + (i * chartWidth / (data.length - 1));
      final double y = chartHeight - data[i] * scale;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      if (data.length < 20) {
        canvas.drawCircle(
          Offset(x, y),
          4,
          Paint()..color = color,
        );
      }
    }
    canvas.drawPath(path, linePaint);

    // Draw filled area beneath the line
    if (data.isNotEmpty) {
      final Paint fillPaint = Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      final Path fillPath = Path.from(path);
      fillPath.lineTo(leftPadding + chartWidth, chartHeight);
      fillPath.lineTo(leftPadding, chartHeight);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 