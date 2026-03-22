import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/habit_frequency.dart';
import '../../domain/habit_model.dart';
import '../providers/habit_provider.dart';

/// A form screen for creating or editing habits.
///
/// When [habitId] is null, the screen operates in create mode.
/// When [habitId] is provided, it loads the existing habit data
/// and operates in edit mode with save and delete options.
///
/// Supports:
/// - Name (required, min 2 chars) and description fields
/// - Frequency selection (daily, weekly, custom)
/// - Day-of-week picker for weekly/custom frequencies
/// - Target count stepper (1-100)
/// - Icon selector with common habit icons
class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({super.key, this.habitId});

  /// When non-null, the screen is in edit mode for this habit.
  final String? habitId;

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  HabitFrequency _frequency = HabitFrequency.daily;
  int _targetCount = 1;
  List<int> _selectedDays = [];
  String? _icon;
  bool _isLoading = false;
  Habit? _existingHabit;

  bool get _isEditMode => widget.habitId != null;

  /// Common icons for habits with their string identifiers.
  static const _iconOptions = <MapEntry<String, IconData>>[
    MapEntry('fitness_center', Icons.fitness_center),
    MapEntry('menu_book', Icons.menu_book),
    MapEntry('water_drop', Icons.water_drop),
    MapEntry('self_improvement', Icons.self_improvement),
    MapEntry('directions_run', Icons.directions_run),
    MapEntry('code', Icons.code),
    MapEntry('music_note', Icons.music_note),
    MapEntry('brush', Icons.brush),
  ];

  /// Day labels for the day-of-week picker.
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadExistingHabit();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Loads the existing habit data for edit mode.
  Future<void> _loadExistingHabit() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(habitRepositoryProvider);
      final habit = await repository.getHabit(widget.habitId!);
      _existingHabit = habit;
      _nameController.text = habit.name;
      _descriptionController.text = habit.description ?? '';
      setState(() {
        _frequency = habit.frequency;
        _targetCount = habit.targetCount;
        _selectedDays = habit.customDays ?? [];
        _icon = habit.icon;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load habit: $e')),
        );
        context.pop();
      }
    }
  }

  /// Saves the habit (create or update).
  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final habit = Habit(
        id: _existingHabit?.id ?? '',
        userId: userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        frequency: _frequency,
        targetCount: _targetCount,
        customDays: (_frequency == HabitFrequency.weekly ||
                _frequency == HabitFrequency.custom)
            ? _selectedDays
            : null,
        icon: _icon,
        createdAt: _existingHabit?.createdAt ?? now,
        updatedAt: now,
      );

      final notifier = ref.read(habitListProvider.notifier);
      if (_isEditMode) {
        await notifier.updateHabit(habit);
      } else {
        await notifier.createHabit(habit);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save habit: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Shows a confirmation dialog then deletes the habit.
  Future<void> _deleteHabit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: const Text(
          'This will permanently delete this habit and all its check-in history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref
            .read(habitListProvider.notifier)
            .deleteHabit(widget.habitId!);
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete habit: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Habit' : 'New Habit'),
      ),
      body: _isLoading && _isEditMode && _existingHabit == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Habit name
                    AppTextField(
                      label: 'Habit Name',
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Habit name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    AppTextField(
                      label: 'Description (optional)',
                      controller: _descriptionController,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),

                    // Frequency dropdown
                    DropdownButtonFormField<HabitFrequency>(
                      value: _frequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: HabitFrequency.daily,
                          child: Text('Daily'),
                        ),
                        DropdownMenuItem(
                          value: HabitFrequency.weekly,
                          child: Text('Weekly'),
                        ),
                        DropdownMenuItem(
                          value: HabitFrequency.custom,
                          child: Text('Custom'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _frequency = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Day picker for weekly/custom
                    if (_frequency == HabitFrequency.weekly ||
                        _frequency == HabitFrequency.custom) ...[
                      Text(
                        'Select days',
                        style: context.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: List.generate(7, (index) {
                          // 1 = Monday, 7 = Sunday (DateTime convention)
                          final dayNumber = index + 1;
                          final isSelected =
                              _selectedDays.contains(dayNumber);
                          return FilterChip(
                            label: Text(_dayLabels[index]),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDays.add(dayNumber);
                                } else {
                                  _selectedDays.remove(dayNumber);
                                }
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Target count stepper
                    Row(
                      children: [
                        Text(
                          'Target per day',
                          style: context.textTheme.labelLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _targetCount > 1
                              ? () =>
                                  setState(() => _targetCount--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$_targetCount',
                          style: context.textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: _targetCount < 100
                              ? () =>
                                  setState(() => _targetCount++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Icon selector
                    Text(
                      'Icon',
                      style: context.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _iconOptions.map((entry) {
                        final isSelected = _icon == entry.key;
                        return ChoiceChip(
                          label: Icon(
                            entry.value,
                            size: 20,
                            color: isSelected
                                ? context.colorScheme.onSecondaryContainer
                                : context.colorScheme.onSurfaceVariant,
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _icon = selected ? entry.key : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    AppButton(
                      label: _isEditMode ? 'Save Changes' : 'Create Habit',
                      isLoading: _isLoading,
                      onPressed: _saveHabit,
                    ),

                    // Delete button (edit mode only)
                    if (_isEditMode) ...[
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Delete Habit',
                        isDestructive: true,
                        isOutlined: true,
                        onPressed: _deleteHabit,
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
