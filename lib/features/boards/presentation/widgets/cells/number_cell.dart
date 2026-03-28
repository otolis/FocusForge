import 'package:flutter/material.dart';

/// An inline-editable number cell with display and edit modes.
///
/// In display mode, shows right-aligned number text.
/// In edit mode, shows a borderless [TextField] with numeric keyboard
/// that saves on Enter or blur.
class NumberCell extends StatelessWidget {
  /// The current numeric value. Null or non-numeric displays empty.
  final dynamic value;

  /// Whether the cell is in edit mode.
  final bool isEditing;

  /// Called when the cell is tapped (enters edit mode).
  final VoidCallback? onTap;

  /// Called when the value is submitted (Enter or blur).
  final ValueChanged<String>? onChanged;

  const NumberCell({
    super.key,
    this.value,
    this.isEditing = false,
    this.onTap,
    this.onChanged,
  });

  String get _displayValue {
    if (value == null) return '';
    if (value is num) {
      // Show integers without decimals, doubles with decimals
      if (value is int || (value as num).truncateToDouble() == value) {
        return (value as num).toInt().toString();
      }
      return value.toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Number: $_displayValue',
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerRight,
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
          alignment: Alignment.centerRight,
          child: Text(
            _displayValue,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: _displayValue),
      autofocus: true,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration.collapsed(hintText: ''),
      onSubmitted: onChanged,
    );
  }
}
