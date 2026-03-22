import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../smart_input/domain/parsed_task_input.dart';
import '../../../smart_input/presentation/widgets/smart_input_field.dart';
import '../../domain/plannable_item_model.dart';
import '../providers/plannable_items_provider.dart';

/// Bottom sheet for adding a new plannable item.
///
/// Contains a title text field, duration picker (6 chip options),
/// and energy level selector (3 chip options). On submit, calls
/// [PlannableItemsNotifier.addItem] and closes the sheet.
class AddItemSheet extends ConsumerStatefulWidget {
  /// The current user's ID, used to key the provider.
  final String userId;

  const AddItemSheet({super.key, required this.userId});

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  final _titleController = TextEditingController();
  int _selectedDuration = 30;
  EnergyLevel _selectedEnergy = EnergyLevel.medium;

  static const _durationOptions = [15, 30, 45, 60, 90, 120];
  static const _durationLabels = ['15m', '30m', '45m', '1h', '1.5h', '2h'];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Add Item',
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Title input with NLP parsing
            SmartInputField(
              controller: _titleController,
              hintText: 'e.g., "Review slides 45min high energy"',
              onParsed: _onSmartInputParsed,
            ),
            const SizedBox(height: 20),

            // Duration picker
            Text(
              'Duration',
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: List.generate(_durationOptions.length, (i) {
                final duration = _durationOptions[i];
                return ChoiceChip(
                  label: Text(_durationLabels[i]),
                  selected: _selectedDuration == duration,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedDuration = duration);
                  },
                );
              }),
            ),
            const SizedBox(height: 20),

            // Energy level selector
            Text(
              'Energy Level',
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  avatar: _selectedEnergy == EnergyLevel.high
                      ? null
                      : const Icon(Icons.local_fire_department_rounded,
                          size: 16),
                  label: const Text('High'),
                  selected: _selectedEnergy == EnergyLevel.high,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedEnergy = EnergyLevel.high);
                    }
                  },
                ),
                ChoiceChip(
                  avatar: _selectedEnergy == EnergyLevel.medium
                      ? null
                      : const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('Medium'),
                  selected: _selectedEnergy == EnergyLevel.medium,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedEnergy = EnergyLevel.medium);
                    }
                  },
                ),
                ChoiceChip(
                  avatar: _selectedEnergy == EnergyLevel.low
                      ? null
                      : const Icon(Icons.coffee_rounded, size: 16),
                  label: const Text('Low'),
                  selected: _selectedEnergy == EnergyLevel.low,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedEnergy = EnergyLevel.low);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit button
            AppButton(
              label: 'Add Item',
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
          ],
      ),
    );
  }

  /// Handles parsed NLP result from SmartInputField, auto-selecting energy level.
  void _onSmartInputParsed(ParsedTaskInput parsed) {
    if (!mounted) return;
    setState(() {
      if (parsed.suggestedPriority != null) {
        _selectedEnergy = _mapPriorityToEnergy(parsed.suggestedPriority!);
      }
    });
  }

  /// Maps NLP-parsed priority (P1-P4) to planner energy level.
  /// P1/P2 = high energy (deep focus), P3 = medium, P4 = low.
  EnergyLevel _mapPriorityToEnergy(String priority) {
    switch (priority) {
      case 'P1':
      case 'P2':
        return EnergyLevel.high;
      case 'P3':
        return EnergyLevel.medium;
      case 'P4':
      default:
        return EnergyLevel.low;
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    await ref
        .read(plannableItemsProvider(widget.userId).notifier)
        .addItem(
          title: title,
          durationMinutes: _selectedDuration,
          energyLevel: _selectedEnergy,
        );

    if (mounted) Navigator.pop(context);
  }
}
