import 'package:flutter/material.dart';
import '../models/section_model.dart';
import '../constants.dart';
class ThreeStateToggle extends StatelessWidget {
  final ScaleValue value;
  final String label;
  final Function(ScaleValue) onChanged;
  final bool isControl;

  const ThreeStateToggle({
    Key? key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.isControl = false,
  }) : super(key: key);

  Color get trackColor {
    switch (value) {
      case ScaleValue.on:
        return Colors.green;
      case ScaleValue.neutral:
        return middleColor;
      case ScaleValue.off:
        return Colors.deepOrange[700]!;
    }
  }

  Color get activeTrackColor {
    switch (value) {
      case ScaleValue.on:
        return trackColor; // Green
      case ScaleValue.neutral:
        return middleColor;
      case ScaleValue.off:
        return middleColor;
    }
  }

  Color get inactiveTrackColor {
    switch (value) {
      case ScaleValue.on:
        return middleColor;
      case ScaleValue.neutral:
        return middleColor;
      case ScaleValue.off:
        return trackColor; // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: scaleWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isControl && label.isNotEmpty)
            Text(
              label,
              style: paramTextStyle.copyWith(height: 1.0),
              textAlign: TextAlign.center,
            ),
          // Reduce vertical spacing between label and slider
          const SizedBox(height: 2), // Adjust height as needed
          // Use Transform to adjust slider position
          Transform.translate(
            offset: const Offset(0, -8), // Move slider up by 8 pixels
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: activeTrackColor,
                inactiveTrackColor: inactiveTrackColor,
                thumbColor: Colors.white,
                thumbShape:  SquareThumbShape(thumbSize: 14.0),
              ),
              child: Slider(
                value: value.value.toDouble(),
                min: 0,
                max: 2,
                divisions: 2,
                onChanged: (double newValue) {
                  onChanged(ScaleValue.fromInt(newValue.toInt()));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class SquareThumbShape extends SliderComponentShape {
  final double thumbSize;

  SquareThumbShape({this.thumbSize = 12.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbSize, thumbSize);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Paint paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.blue
      ..style = PaintingStyle.fill;

    final Rect thumbRect = Rect.fromCenter(
      center: center,
      width: thumbSize,
      height: thumbSize,
    );

    context.canvas.drawRect(thumbRect, paint);
  }
}


class SectionWidget extends StatefulWidget {
  final SectionModel section;
  final VoidCallback onChanged;

  const SectionWidget({
    Key? key,
    required this.section,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<SectionWidget> createState() => _SectionWidgetState();
}

class _SectionWidgetState extends State<SectionWidget> {
  static const double sectionWidth = 125.0; // Fixed width for the section

  @override
  Widget build(BuildContext context) {
    return Container(
      width: sectionWidth, // Fixed width container
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlToggle(),
          const SizedBox(height: 8),
          Text(widget.section.label, style: headerTextStyle),
          _buildNoBlanksCheckbox(),
          const Divider(height: 16, color: middleColor),
          ...widget.section.scales.map(_buildScale), // Include all scales
        ],
      ),
    );
  }

  Widget _buildControlToggle() {
    return ThreeStateToggle(
      value: widget.section.groupControl,
      label: '*',
      isControl: true,
      onChanged: (newValue) {
        setState(() {
          widget.section.groupControl = newValue;
          widget.section.updateAllScales(newValue);
        });
        widget.onChanged();
      },
    );
  }

  Widget _buildScale(ScaleItem scale) {
    return ThreeStateToggle(
      value: scale.value,
      label: scale.label,
      onChanged: (newValue) {
        setState(() {
          scale.updateValue(newValue);
        });
        widget.onChanged();
      },
    );
  }

  Widget _buildNoBlanksCheckbox() {
    return SizedBox(
      width: sectionWidth - 32, // Account for parent padding
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: widget.section.noBlanks,
              onChanged: (value) {
                setState(() {
                  widget.section.noBlanks = value ?? false;
                });
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          const Text('No Blanks', style: paramTextStyle),
        ],
      ),
    );
  }
}
