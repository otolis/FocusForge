import 'package:flutter/material.dart';

class Category {
  final String id;
  final String userId;
  final String name;
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    this.colorIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<Color> presetColors = [
    Color(0xFFEF5350), // Red
    Color(0xFFEC407A), // Pink
    Color(0xFFAB47BC), // Purple
    Color(0xFF5C6BC0), // Indigo
    Color(0xFF42A5F5), // Blue
    Color(0xFF26A69A), // Teal
    Color(0xFF66BB6A), // Green
    Color(0xFFFFCA28), // Amber
    Color(0xFFFFA726), // Orange
    Color(0xFF8D6E63), // Brown
  ];

  Color get color => presetColors[colorIndex.clamp(0, 9)];

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      colorIndex: json['color_index'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'color_index': colorIndex,
        'updated_at': DateTime.now().toIso8601String(),
      };

  Category copyWith({String? name, int? colorIndex}) {
    return Category(
      id: id,
      userId: userId,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
