import 'package:flutter/material.dart';

/// A cell with a centered Material 3 checkbox that toggles on tap.
///
/// Always interactive (no separate edit mode). Calls [onChanged] immediately
/// on tap for optimistic update.
class CheckboxCell extends StatelessWidget {
  /// Whether the checkbox is checked.
  final bool value;

  /// Called when the checkbox is toggled. Receives the new value.
  final ValueChanged<bool>? onChanged;

  const CheckboxCell({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Checkbox: ${value ? "checked" : "unchecked"}',
      child: Container(
        height: 36,
        alignment: Alignment.center,
        child: Checkbox(
          value: value,
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged?.call(newValue);
            }
          },
        ),
      ),
    );
  }
}
