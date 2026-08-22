import 'package:flutter/material.dart';

enum LineStyle { solid, dotted, none }

class TimelineNode extends StatelessWidget {
  final Widget indicator;
  final LineStyle lineStyle;
  final Color lineColor;
  final Widget content;

  const TimelineNode({
    super.key,
    required this.indicator,
    required this.content,
    this.lineStyle = LineStyle.solid,
    this.lineColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: Indicator and Line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                indicator,
                if (lineStyle != LineStyle.none)
                  Expanded(
                    child: lineStyle == LineStyle.solid
                        ? Container(
                      width: 6,
                      // color: lineColor,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: lineColor,
                    ),
                    )
                        : Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: _DottedLine(color: lineColor),
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right side: The actual card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedLine extends StatelessWidget {
  final Color color;

  const _DottedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    // CustomPaint doesn't need to know its height in advance, solving the IntrinsicHeight crash!
    return CustomPaint(
      painter: _DashedLinePainter(color: color),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const dashWidth = 4.0;
    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0.0;

    // Draw the rounded dots from the top of the container to the bottom
    while (startY < size.height) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, startY, dashWidth, dashHeight),
          const Radius.circular(2),
        ),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}