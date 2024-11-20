import 'package:flutter/material.dart';

class CustomSlider extends StatefulWidget {
  final List<double> values;
  final double min;
  final double max;
  final Function(List<double>) onChanged;

  const CustomSlider({
    super.key,
    required this.values,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<CustomSlider> createState() => _CustomSliderState();
}

class _CustomSliderState extends State<CustomSlider> {
  late List<double> _values;
  static const _thumbSize = 20.0;
  static const _trackHeight = 10.0;

  @override
  void initState() {
    super.initState();
    _values = List.from(widget.values);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) => _handlePanUpdate(details, constraints.maxWidth),
          child: CustomPaint(
            size: Size(constraints.maxWidth, 50),
            painter: _SliderPainter(
              values: _values,
              min: widget.min,
              max: widget.max,
              thumbSize: _thumbSize,
              trackHeight: _trackHeight,
            ),
          ),
        );
      },
    );
  }

  void _handlePanUpdate(DragUpdateDetails details, double width) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    
    // Find which thumb is closer to the touch point
    final double pos = localPosition.dx.clamp(0, width);
    final double percent = pos / width;
    final value = widget.min + (widget.max - widget.min) * percent;
    
    final dist0 = (value - _values[0]).abs();
    final dist1 = (value - _values[1]).abs();
    
    setState(() {
      if (dist0 < dist1) {
        _values[0] = value.clamp(widget.min, _values[1]);
      } else {
        _values[1] = value.clamp(_values[0], widget.max);
      }
    });
    
    widget.onChanged(_values);
  }
}

class _SliderPainter extends CustomPainter {
  final List<double> values;
  final double min;
  final double max;
  final double thumbSize;
  final double trackHeight;

  _SliderPainter({
    required this.values,
    required this.min,
    required this.max,
    required this.thumbSize,
    required this.trackHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF476B6B)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = trackHeight;

    // Draw track
    final trackY = size.height / 2;
    canvas.drawLine(
      Offset(thumbSize / 2, trackY),
      Offset(size.width - thumbSize / 2, trackY),
      paint,
    );

    // Draw range
    paint.color = const Color(0xFF5C8A8A);
    final x1 = _valueToPosition(values[0], size.width);
    final x2 = _valueToPosition(values[1], size.width);
    canvas.drawLine(
      Offset(x1, trackY),
      Offset(x2, trackY),
      paint,
    );

    // Draw thumbs
    paint.color = const Color(0xFFC2D6D6);
    for (final value in values) {
      final x = _valueToPosition(value, size.width);
      canvas.drawCircle(
        Offset(x, trackY),
        thumbSize / 2,
        paint,
      );
      
      // Draw value text
      final textSpan = TextSpan(
        text: value.round().toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Courier',
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, trackY + thumbSize),
      );
    }
  }

  double _valueToPosition(double value, double width) {
    final percent = (value - min) / (max - min);
    return thumbSize / 2 + percent * (width - thumbSize);
  }

  @override
  bool shouldRepaint(_SliderPainter oldDelegate) {
    return values != oldDelegate.values;
  }
}