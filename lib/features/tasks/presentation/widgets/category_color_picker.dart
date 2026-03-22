import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/category_model.dart';

/// A grid of 10 preset color circles for selecting a category color.
///
/// The selected color is indicated by a primary-colored border and
/// a white check-mark overlay.
class CategoryColorPicker extends StatelessWidget {
  const CategoryColorPicker({
    super.key,
    required this.selectedIndex,
    required this.onColorSelected,
  });

  /// The index of the currently selected color in [Category.presetColors].
  final int selectedIndex;

  /// Called when the user taps a color circle.
  final ValueChanged<int> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(Category.presetColors.length, (index) {
        final color = Category.presetColors[index];
        final isSelected = index == selectedIndex;
        return GestureDetector(
          onTap: () => onColorSelected(index),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: isSelected
                  ? Border.all(
                      color: context.colorScheme.primary,
                      width: 3,
                    )
                  : Border.all(
                      color: context.colorScheme.outlineVariant,
                      width: 1,
                    ),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : null,
          ),
        );
      }),
    );
  }
}
