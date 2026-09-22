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

  static final Map<int, IconData> knownIcons = {
    for (final icon in [
      Icons.sports_esports_rounded,
      Icons.fitness_center_rounded,
      Icons.pets_rounded,
      Icons.medical_services_rounded,
      Icons.school_rounded,
      Icons.flight_takeoff_rounded,
      Icons.card_giftcard_rounded,
      Icons.local_cafe_rounded,
      Icons.fastfood_rounded,
      Icons.shopping_bag_rounded,
      Icons.pool_rounded,
      Icons.music_note_rounded,
      Icons.local_gas_station_rounded,
      Icons.home_repair_service_rounded,
      Icons.directions_bike_rounded,
      Icons.savings_rounded,
      Icons.laptop_chromebook_rounded,
      Icons.child_care_rounded,
      Icons.camera_alt_rounded,
      Icons.book_rounded,
      Icons.spa_rounded,
      Icons.local_laundry_service_rounded,
      Icons.celebration_rounded,
      Icons.category_rounded,
      Icons.home_work_rounded,
      Icons.restaurant_rounded,
      Icons.shopping_cart_rounded,
      Icons.bolt_rounded,
      Icons.local_fire_department_rounded,
      Icons.water_drop_rounded,
      Icons.wifi_rounded,
      Icons.cleaning_services_rounded,
      Icons.directions_car_rounded,
      Icons.weekend_rounded,
      Icons.movie_rounded,
    ])
      icon.codePoint: icon,
  };

  IconData get icon => knownIcons[iconCodePoint] ?? Icons.category_rounded;
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
