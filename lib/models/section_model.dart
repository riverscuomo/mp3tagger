// models/section_model.dart

import 'package:flutter/material.dart'; // models/section_model.dart

enum ScaleValue {
  off(0),
  neutral(1),
  on(2);

  final int value;
  const ScaleValue(this.value);

  static ScaleValue fromInt(int value) {
    return ScaleValue.values.firstWhere((e) => e.value == value);
  }
}

class ScaleItem {
  String label;
  ScaleValue value;
  Color troughColor;

  ScaleItem({
    required this.label,
    required this.value,
    required this.troughColor,
  });

  void updateValue(ScaleValue newValue) {
    value = newValue;
    troughColor = _getColorForValue(newValue);
  }
  void updateLabel(String newLabel) {
    label = newLabel;
  }
  static Color _getColorForValue(ScaleValue value) {
    switch (value) {
      case ScaleValue.on:
        return Colors.green;
      case ScaleValue.neutral:
        return const Color(0xFF424242); // grey29
      case ScaleValue.off:
        return Colors.deepOrange[700]!; // coral3
    }
  }

  factory ScaleItem.fromJson(Map<String, dynamic> json) {
    final value = ScaleValue.fromInt(json['value'] as int);
    return ScaleItem(
      label: json['label'] as String,
      value: value,
      troughColor: _getColorForValue(value),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value.value,
    };
  }
}

class SectionModel {
  String label;
  List<ScaleItem> scales;
  bool noBlanks;
  ScaleValue groupControl;

  SectionModel({
    required this.label,
    required this.scales,
    this.noBlanks = false,
    required this.groupControl,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      label: json['label'] as String,
      scales: (json['scales'] as List)
          .map((scale) => ScaleItem.fromJson({
                'label': scale[0] as String,
                'value': scale[1] as int,
              }))
          .toList(),
      noBlanks: json['no_blanks'] ?? false,
      groupControl: ScaleValue.fromInt(json['group_control'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'scales':
          scales.map((scale) => [scale.label, scale.value.value]).toList(),
      'no_blanks': noBlanks,
      'group_control': groupControl.value,
    };
  }

  void updateAllScales(ScaleValue value) {
    for (var scale in scales) {
      scale.updateValue(value);
    }
  }

  String getFilter({bool controlTogglePressed = false}) {
    List<String> positiveFilters = [];
    List<String> negativeFilters = [];

    if (controlTogglePressed) {
      updateAllScales(groupControl);
    }

    for (var scale in scales) {
      if (scale.label.toLowerCase().contains('*')) continue;

      switch (scale.value) {
        case ScaleValue.off:
          negativeFilters.add(scale.label.trim());
          break;
        case ScaleValue.on:
          positiveFilters.add(scale.label.trim());
          break;
        case ScaleValue.neutral:
          break;
      }
    }

    String filter = '';
    if (positiveFilters.isNotEmpty) {
      // Group the positive filters and ensure proper parentheses
      filter += noBlanks
          ? '($label MATCHES ${positiveFilters.join('|')}) AND '
          : '((($label MATCHES ${positiveFilters.join('|')}) OR ($label ABSENT))) AND ';
    }

    if (negativeFilters.isNotEmpty) {
      // Group negative filters properly
      filter += '(NOT $label MATCHES ${negativeFilters.join('|')}) AND ';
    }

    return filter;
  }
  
  void addScale(ScaleItem scale) {
    scales.add(scale);
  }

  void removeScale(ScaleItem scale) {
    scales.remove(scale);
  }

  void updateLabel(String newLabel) {
    label = newLabel;
  }

}
