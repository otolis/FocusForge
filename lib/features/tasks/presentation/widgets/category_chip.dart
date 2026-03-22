import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/category_model.dart';

/// A small chip displaying a category name with its associated color.
///
/// Returns [SizedBox.shrink] when [category] is null so it can be used
/// unconditionally in row layouts.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category});

  final Category? category;

  @override
  Widget build(BuildContext context) {
    if (category == null) return const SizedBox.shrink();

    final cat = category!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: ShapeDecoration(
        color: cat.color.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        cat.name,
        style: context.textTheme.labelSmall?.copyWith(
          color: cat.color,
        ),
      ),
    );
  }
}
