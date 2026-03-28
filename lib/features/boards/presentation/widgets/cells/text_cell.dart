import 'package:flutter/material.dart';

/// An inline-editable text cell with display and edit modes.
///
/// In display mode, shows truncated text with ellipsis overflow.
/// In edit mode, shows a borderless [TextField] that saves on Enter or blur.
/// The name column variant uses a larger font size (14px vs 13px).
class TextCell extends StatelessWidget {
  /// The current text value.
  final String value;

  /// Whether the cell is in edit mode.
  final bool isEditing;

  /// Whether this is the name (first) column. Uses 14px font if true.
  final bool isNameColumn;

  /// Called when the cell is tapped (enters edit mode).
  final VoidCallback? onTap;

  /// Called when the value is submitted (Enter or blur).
  final ValueChanged<String>? onChanged;

  const TextCell({
    super.key,
    required this.value,
    this.isEditing = false,
    this.isNameColumn = false,
    this.onTap,
    this.onChanged,
  });

  double get _fontSize => isNameColumn ? 14.0 : 13.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${isNameColumn ? "Name" : "Text"}: $value',
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: isEditing ? _buildEditor(context) : _buildDisplay(context),
      ),
    );
  }

  Widget _buildDisplay(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        height: 36,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      autofocus: true,
      style: TextStyle(
        fontSize: _fontSize,
        fontWeight: FontWeight.w400,
      ),
      decoration: const InputDecoration.collapsed(hintText: ''),
      onSubmitted: onChanged,
      onTapOutside: (_) {
        // Save on focus loss is handled by the parent via FocusNode
      },
    );
  }
}
