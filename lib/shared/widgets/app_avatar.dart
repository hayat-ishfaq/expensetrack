import 'dart:convert';
import 'package:flutter/material.dart';

class AvatarPreset {
  const AvatarPreset({
    required this.id,
    required this.emoji,
    required this.label,
    required this.gradientColors,
  });

  final String id;
  final String emoji;
  final String label;
  final List<Color> gradientColors;
}

abstract final class AppAvatars {
  static const List<AvatarPreset> presets = [
    AvatarPreset(
      id: 'avatar:techie',
      emoji: '👨‍💻',
      label: 'Techie',
      gradientColors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    ),
    AvatarPreset(
      id: 'avatar:chef',
      emoji: '👩‍🍳',
      label: 'Chef',
      gradientColors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    ),
    AvatarPreset(
      id: 'avatar:artist',
      emoji: '🎨',
      label: 'Artist',
      gradientColors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    ),
    AvatarPreset(
      id: 'avatar:coffee',
      emoji: '☕',
      label: 'Coffee',
      gradientColors: [Color(0xFF78350F), Color(0xFFD97706)],
    ),
    AvatarPreset(
      id: 'avatar:music',
      emoji: '🎧',
      label: 'Music',
      gradientColors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
    ),
    AvatarPreset(
      id: 'avatar:nature',
      emoji: '🌿',
      label: 'Nature',
      gradientColors: [Color(0xFF059669), Color(0xFF10B981)],
    ),
    AvatarPreset(
      id: 'avatar:cat',
      emoji: '🐱',
      label: 'Cat',
      gradientColors: [Color(0xFFF97316), Color(0xFFFBBF24)],
    ),
    AvatarPreset(
      id: 'avatar:dog',
      emoji: '🐶',
      label: 'Dog',
      gradientColors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
    ),
    AvatarPreset(
      id: 'avatar:lion',
      emoji: '🦁',
      label: 'Lion',
      gradientColors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    ),
    AvatarPreset(
      id: 'avatar:rocket',
      emoji: '🚀',
      label: 'Rocket',
      gradientColors: [Color(0xFF1E3A8A), Color(0xFF7C3AED)],
    ),
    AvatarPreset(
      id: 'avatar:electric',
      emoji: '⚡',
      label: 'Electric',
      gradientColors: [Color(0xFFEAB308), Color(0xFFF97316)],
    ),
    AvatarPreset(
      id: 'avatar:zen',
      emoji: '🧘',
      label: 'Zen',
      gradientColors: [Color(0xFF047857), Color(0xFF34D399)],
    ),
    AvatarPreset(
      id: 'avatar:gamer',
      emoji: '🎮',
      label: 'Gamer',
      gradientColors: [Color(0xFF7E22CE), Color(0xFF3B82F6)],
    ),
    AvatarPreset(
      id: 'avatar:reader',
      emoji: '📚',
      label: 'Reader',
      gradientColors: [Color(0xFFBE185D), Color(0xFFF43F5E)],
    ),
    AvatarPreset(
      id: 'avatar:star',
      emoji: '🌟',
      label: 'Star',
      gradientColors: [Color(0xFFCA8A04), Color(0xFFFBBF24)],
    ),
    AvatarPreset(
      id: 'avatar:home',
      emoji: '🏠',
      label: 'Homebody',
      gradientColors: [Color(0xFF334155), Color(0xFF0D9488)],
    ),
  ];

  static AvatarPreset? findPreset(String? id) {
    if (id == null) return null;
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 44,
    this.borderWidth = 0,
    this.borderColor,
    this.onTap,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preset = AppAvatars.findPreset(photoUrl);

    Widget child;

    if (preset != null) {
      child = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: preset.gradientColors,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          preset.emoji,
          style: TextStyle(
            fontSize: size * 0.52,
            height: 1,
          ),
        ),
      );
    } else if (photoUrl != null &&
        photoUrl!.isNotEmpty &&
        photoUrl!.startsWith('data:image')) {
      final commaIndex = photoUrl!.indexOf(',');
      final base64String =
          commaIndex != -1 ? photoUrl!.substring(commaIndex + 1) : photoUrl!;
      try {
        final bytes = base64Decode(base64String);
        child = ClipOval(
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallback(scheme),
          ),
        );
      } catch (_) {
        child = _buildFallback(scheme);
      }
    } else if (photoUrl != null &&
        photoUrl!.isNotEmpty &&
        photoUrl!.startsWith('http')) {
      child = ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(scheme),
        ),
      );
    } else {
      child = _buildFallback(scheme);
    }

    if (borderWidth > 0 && borderColor != null) {
      child = Container(
        width: size + (borderWidth * 2),
        height: size + (borderWidth * 2),
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: child,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }

    return child;
  }

  Widget _buildFallback(ColorScheme scheme) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    // Deterministic gradient hue based on name
    final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
    final hue1 = (hash * 37) % 360;
    final hue2 = (hue1 + 45) % 360;
    final color1 = HSLColor.fromAHSL(1.0, hue1.toDouble(), 0.65, 0.45).toColor();
    final color2 = HSLColor.fromAHSL(1.0, hue2.toDouble(), 0.70, 0.35).toColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.44,
          height: 1,
        ),
      ),
    );
  }
}
