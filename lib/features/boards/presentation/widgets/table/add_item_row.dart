import 'package:flutter/material.dart';

/// Inline row for adding a new item to a group.
///
/// Shows a "+" icon and a text field. Submits on Enter key or when
/// the field loses focus with non-empty text.
class AddItemRow extends StatefulWidget {
  final ValueChanged<String> onSubmit;

  const AddItemRow({
    super.key,
    required this.onSubmit,
  });

  @override
  State<AddItemRow> createState() => _AddItemRowState();
}

class _AddItemRowState extends State<AddItemRow> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Submit on blur if text is not empty
    if (!_focusNode.hasFocus && _controller.text.trim().isNotEmpty) {
      _submit();
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmit(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(
            Icons.add,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _submit(),
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration.collapsed(
                hintText: 'Add item',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
