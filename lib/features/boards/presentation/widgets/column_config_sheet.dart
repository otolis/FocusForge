import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/board_table_column.dart';

/// Modal bottom sheet for adding or editing a table column definition.
///
/// In create mode ([existingColumn] is null), generates a new column with
/// a UUID id and default width. In edit mode, preserves the existing
/// column's id and position.
class ColumnConfigSheet extends StatefulWidget {
  /// Null for create mode, non-null for edit mode.
  final TableColumnDef? existingColumn;

  /// Called with the new or updated column when the user saves.
  final ValueChanged<TableColumnDef> onSave;

  const ColumnConfigSheet({
    super.key,
    this.existingColumn,
    required this.onSave,
  });

  @override
  State<ColumnConfigSheet> createState() => _ColumnConfigSheetState();
}

class _ColumnConfigSheetState extends State<ColumnConfigSheet> {
  late final TextEditingController _nameController;
  late ColumnType _selectedType;

  bool get _isEditMode => widget.existingColumn != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingColumn?.name ?? '',
    );
    _selectedType = widget.existingColumn?.type ?? ColumnType.text;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final column = _isEditMode
        ? widget.existingColumn!.copyWith(name: name)
        : TableColumnDef(
            id: const Uuid().v4(),
            type: _selectedType,
            name: name,
            width: 150,
            position: 0, // Caller should set actual position
          );

    widget.onSave(column);
    Navigator.of(context).pop();
  }

  /// Display name for each column type.
  String _typeDisplayName(ColumnType type) {
    return switch (type) {
      ColumnType.status => 'Status',
      ColumnType.priority => 'Priority',
      ColumnType.person => 'Person',
      ColumnType.timeline => 'Timeline',
      ColumnType.dueDate => 'Due Date',
      ColumnType.text => 'Text',
      ColumnType.number => 'Number',
      ColumnType.checkbox => 'Checkbox',
      ColumnType.link => 'Link',
    };
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
            _isEditMode ? 'Edit column' : 'Add column',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Column name
          AppTextField(
            label: 'Column name',
            controller: _nameController,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),

          // Column type dropdown
          DropdownButtonFormField<ColumnType>(
            initialValue: _selectedType,
            decoration: const InputDecoration(labelText: 'Column type'),
            items: ColumnType.values
                .map((t) => DropdownMenuItem<ColumnType>(
                      value: t,
                      child: Text(_typeDisplayName(t)),
                    ))
                .toList(),
            onChanged: _isEditMode
                ? null // Don't allow type change in edit mode
                : (v) {
                    if (v != null) setState(() => _selectedType = v);
                  },
          ),
          const SizedBox(height: 24),

          // CTA button
          FilledButton(
            onPressed: _save,
            child: Text(_isEditMode ? 'Update Column' : 'Add Column'),
          ),
        ],
      ),
    );
  }
}
