import 'package:flutter/material.dart';

/// An inline-editable URL cell with display and edit modes.
///
/// In display mode, shows truncated URL text underlined in primary color.
/// If empty, shows an em dash placeholder.
/// In edit mode, shows a borderless [TextField] that saves on Enter or blur.
class LinkCell extends StatelessWidget {
  /// The current URL value.
  final String value;

  /// Whether the cell is in edit mode.
  final bool isEditing;

  /// Called when the cell is tapped (enters edit mode).
  final VoidCallback? onTap;

  /// Called when the value is submitted (Enter or blur).
  final ValueChanged<String>? onChanged;

  const LinkCell({
    super.key,
    required this.value,
    this.isEditing = false,
    this.onTap,
    this.onChanged,
  });

  bool get _hasValue => value.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = _hasValue ? 'Link: $value' : 'Link: not set';

    return Semantics(
      label: semanticLabel,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: isEditing ? _buildEditor(context) : _buildDisplay(context),
      ),
    );
  }

  Widget _buildDisplay(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        height: 36,
        child: Align(
          alignment: Alignment.centerLeft,
          child: _hasValue
              ? Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: cs.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: cs.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )
              : Text(
                  '\u2014',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: cs.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      autofocus: true,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      decoration: const InputDecoration.collapsed(hintText: 'Enter URL'),
      keyboardType: TextInputType.url,
      onSubmitted: onChanged,
    );
  }
}
