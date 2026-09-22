import 'package:flutter/material.dart';

/// A user-defined custom expense category created for a household.
class CustomCategory {
  const CustomCategory({
    required this.id,
    required this.label,
    required this.iconCodePoint,
    required this.colorValue,
    this.subcategories = const [],
  });

  final String id;
  final String label;
  final int iconCodePoint;
  final int colorValue;
  final List<String> subcategories;

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  factory CustomCategory.fromMap(Map<String, dynamic> map) {
    return CustomCategory(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      iconCodePoint: map['iconCodePoint'] as int? ?? Icons.category_rounded.codePoint,
      colorValue: map['colorValue'] as int? ?? 0xFF6366F1,
      subcategories: (map['subcategories'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'subcategories': subcategories,
      };

  CustomCategory copyWith({
    String? id,
    String? label,
    int? iconCodePoint,
    int? colorValue,
    List<String>? subcategories,
  }) =>
      CustomCategory(
        id: id ?? this.id,
        label: label ?? this.label,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        colorValue: colorValue ?? this.colorValue,
        subcategories: subcategories ?? this.subcategories,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomCategory &&
          other.id == id &&
          other.label == label &&
          other.iconCodePoint == iconCodePoint &&
          other.colorValue == colorValue;

  @override
  int get hashCode => Object.hash(id, label, iconCodePoint, colorValue);
}
