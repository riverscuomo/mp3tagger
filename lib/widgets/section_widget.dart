import 'package:flutter/material.dart';
import '../models/section_model.dart';
import '../constants.dart';

class ThreeStateToggle extends StatelessWidget {
  final ScaleValue value;
  final String label;
  final Function(ScaleValue) onChanged;
  final bool isControl;

  const ThreeStateToggle({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.isControl = false,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isControl && label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(label, style: paramTextStyle),
            ),
         SliderTheme(
        data: SliderThemeData(
          trackHeight: 4,
          activeTrackColor: activeTrackColor,
          inactiveTrackColor: inactiveTrackColor,
          thumbColor: Colors.white,
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
        ],
      ),
    );
  }
}

class SectionWidget extends StatefulWidget {
  final SectionModel section;
  final VoidCallback onChanged;

  const SectionWidget({
    super.key,
    required this.section,
    required this.onChanged,
  });

  @override
  State<SectionWidget> createState() => _SectionWidgetState();
}

class _SectionWidgetState extends State<SectionWidget> {
  static const double sectionWidth = 125.0;  // Fixed width for the section

  @override
  Widget build(BuildContext context) {
    return Container(
      width: sectionWidth,  // Fixed width container
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlToggle(),
          const SizedBox(height: 8),
          Text(widget.section.label, style: headerTextStyle),
          _buildNoBlanksCheckbox(),
          const Divider(height: 16, color: middleColor),
          ...widget.section.scales.map(_buildScale).skip(1), // Skip control toggle
        ],
      ),
    );
  }

  Widget _buildControlToggle() {
    var controlScale = widget.section.scales[0];
    return ThreeStateToggle(
      value: controlScale.value,
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
      width: sectionWidth - 32,  // Account for parent padding
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