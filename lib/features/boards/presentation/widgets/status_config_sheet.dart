import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/board_table_column.dart';

/// Preset color hex values for status labels and groups.
const List<String> kPresetColors = [
  '#E2445C',
  '#FDAB3D',
  '#579BFC',
  '#00C875',
  '#FF9800',
  '#9C27B0',
  '#795548',
  '#607D8B',
  '#F44336',
  '#9E9E9E',
];

/// Modal bottom sheet for managing board status labels.
///
/// Displays a list of current status labels with editable name fields
/// and color pickers. Supports adding and removing labels.
class StatusConfigSheet extends StatefulWidget {
  final List<StatusLabelDef> currentLabels;
  final ValueChanged<List<StatusLabelDef>> onSave;

  const StatusConfigSheet({
    super.key,
    required this.currentLabels,
    required this.onSave,
  });

  @override
  State<StatusConfigSheet> createState() => _StatusConfigSheetState();
}

class _StatusConfigSheetState extends State<StatusConfigSheet> {
  late List<_EditableLabel> _labels;

  @override
  void initState() {
    super.initState();
    _labels = widget.currentLabels
        .map((l) => _EditableLabel(
              id: l.id,
              controller: TextEditingController(text: l.name),
              color: l.color,
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final label in _labels) {
      label.controller.dispose();
    }
    super.dispose();
  }

  void _addLabel() {
    setState(() {
      _labels.add(_EditableLabel(
        id: const Uuid().v4(),
        controller: TextEditingController(),
        color: '#9E9E9E',
      ));
    });
  }

  void _removeLabel(int index) {
    setState(() {
      _labels[index].controller.dispose();
      _labels.removeAt(index);
    });
  }

  void _saveAndClose() {
    final labels = _labels
        .map((l) => StatusLabelDef(
              id: l.id,
              name: l.controller.text.trim().isEmpty
                  ? 'Untitled'
                  : l.controller.text.trim(),
              color: l.color,
            ))
        .toList();
    widget.onSave(labels);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage statuses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: _saveAndClose,
                    child: const Text('Done'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Label list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _labels.length + 1, // +1 for add row
                  itemBuilder: (context, index) {
                    if (index == _labels.length) {
                      // "+ Add status" row
                      return GestureDetector(
                        onTap: _addLabel,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 20,
                                  color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                '+ Add status',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final label = _labels[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          // Color circle
                          GestureDetector(
                            onTap: () => _showColorPicker(index),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _parseHex(label.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Name field
                          Expanded(
                            child: TextField(
                              controller: label.controller,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                              decoration: InputDecoration.collapsed(
                                hintText: 'Status name',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Delete button
                          IconButton(
                            onPressed: () => _removeLabel(index),
                            icon: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: colorScheme.error,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showColorPicker(int labelIndex) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kPresetColors.map((hex) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _labels[labelIndex] = _EditableLabel(
                      id: _labels[labelIndex].id,
                      controller: _labels[labelIndex].controller,
                      color: hex,
                    );
                  });
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _parseHex(hex),
                    shape: BoxShape.circle,
                    border: _labels[labelIndex].color == hex
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 2,
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  static Color _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

class _EditableLabel {
  final String id;
  final TextEditingController controller;
  final String color;

  _EditableLabel({
    required this.id,
    required this.controller,
    required this.color,
  });
}
