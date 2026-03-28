import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/board_model.dart';
import 'status_config_sheet.dart' show kPresetColors;

/// Modal bottom sheet for creating or editing a board group.
///
/// In create mode ([existingGroup] is null), generates a new group with
/// a UUID id and next position. In edit mode, preserves the existing
/// group's id and position.
class GroupConfigSheet extends StatefulWidget {
  /// Null for create mode, non-null for edit mode.
  final BoardGroup? existingGroup;

  /// Called with the new or updated group when the user saves.
  final ValueChanged<BoardGroup> onSave;

  const GroupConfigSheet({
    super.key,
    this.existingGroup,
    required this.onSave,
  });

  @override
  State<GroupConfigSheet> createState() => _GroupConfigSheetState();
}

class _GroupConfigSheetState extends State<GroupConfigSheet> {
  late final TextEditingController _nameController;
  late String _selectedColor;

  bool get _isEditMode => widget.existingGroup != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingGroup?.name ?? '',
    );
    _selectedColor = widget.existingGroup?.color ?? '#2196F3';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final group = _isEditMode
        ? widget.existingGroup!.copyWith(
            name: name,
            color: _selectedColor,
          )
        : BoardGroup(
            id: const Uuid().v4(),
            name: name,
            color: _selectedColor,
            position: 0, // Caller should set actual position
          );

    widget.onSave(group);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            _isEditMode ? 'Edit group' : 'Add group',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Group name
          AppTextField(
            label: 'Group name',
            controller: _nameController,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),

          // Color picker
          Text(
            'Color',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kPresetColors.map((hex) {
              final isSelected = _selectedColor == hex;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _parseHex(hex),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: colorScheme.onSurface,
                            width: 2,
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // CTA button
          FilledButton(
            onPressed: _save,
            child: Text(_isEditMode ? 'Update Group' : 'Add group'),
          ),
        ],
      ),
    );
  }

  static Color _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
