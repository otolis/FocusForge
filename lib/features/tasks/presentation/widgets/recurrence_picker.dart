import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/recurrence_model.dart';

/// Configuration object returned by [RecurrencePicker] when recurrence is set.
class RecurrenceConfig {
  final RecurrenceType type;
  final int? intervalDays;
  final List<int>? daysOfWeek;
  final int? dayOfMonth;

  const RecurrenceConfig({
    required this.type,
    this.intervalDays,
    this.daysOfWeek,
    this.dayOfMonth,
  });
}

/// A widget that lets the user configure task recurrence settings.
///
/// Supports daily, weekly (with day selection), monthly (day of month),
/// and custom interval (every N days) recurrence types.
class RecurrencePicker extends StatefulWidget {
  const RecurrencePicker({
    super.key,
    this.initialType,
    this.initialIntervalDays,
    this.initialDaysOfWeek,
    this.initialDayOfMonth,
    required this.onChanged,
  });

  final RecurrenceType? initialType;
  final int? initialIntervalDays;
  final List<int>? initialDaysOfWeek;
  final int? initialDayOfMonth;
  final ValueChanged<RecurrenceConfig?> onChanged;

  @override
  State<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends State<RecurrencePicker> {
  RecurrenceType? _selectedType;
  List<int> _selectedDays = [];
  int _selectedDayOfMonth = 1;
  late TextEditingController _intervalController;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedDays = widget.initialDaysOfWeek?.toList() ?? [];
    _selectedDayOfMonth =
        widget.initialDayOfMonth ?? DateTime.now().day;
    _intervalController = TextEditingController(
      text: (widget.initialIntervalDays ?? 2).toString(),
    );
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  void _emitChange() {
    if (_selectedType == null) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged(RecurrenceConfig(
      type: _selectedType!,
      intervalDays: _selectedType == RecurrenceType.custom
          ? int.tryParse(_intervalController.text)
          : null,
      daysOfWeek:
          _selectedType == RecurrenceType.weekly ? _selectedDays : null,
      dayOfMonth:
          _selectedType == RecurrenceType.monthly ? _selectedDayOfMonth : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repeat', style: context.textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<RecurrenceType?>(
          value: _selectedType,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.repeat),
          ),
          items: const [
            DropdownMenuItem<RecurrenceType?>(
              value: null,
              child: Text('None'),
            ),
            DropdownMenuItem(
              value: RecurrenceType.daily,
              child: Text('Daily'),
            ),
            DropdownMenuItem(
              value: RecurrenceType.weekly,
              child: Text('Weekly'),
            ),
            DropdownMenuItem(
              value: RecurrenceType.monthly,
              child: Text('Monthly'),
            ),
            DropdownMenuItem(
              value: RecurrenceType.custom,
              child: Text('Custom interval'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedType = value;
            });
            _emitChange();
          },
        ),
        if (_selectedType == RecurrenceType.weekly) ...[
          const SizedBox(height: 12),
          _buildWeeklySelector(),
        ],
        if (_selectedType == RecurrenceType.monthly) ...[
          const SizedBox(height: 12),
          _buildMonthlySelector(),
        ],
        if (_selectedType == RecurrenceType.custom) ...[
          const SizedBox(height: 12),
          _buildCustomInterval(),
        ],
      ],
    );
  }

  Widget _buildWeeklySelector() {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: List.generate(7, (index) {
        final isoDay = index + 1; // ISO: 1=Mon, 7=Sun
        final isSelected = _selectedDays.contains(isoDay);
        return FilterChip(
          label: Text(dayLabels[index]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(isoDay);
                _selectedDays.sort();
              } else {
                _selectedDays.remove(isoDay);
              }
            });
            _emitChange();
          },
        );
      }),
    );
  }

  Widget _buildMonthlySelector() {
    return DropdownButtonFormField<int>(
      value: _selectedDayOfMonth,
      decoration: const InputDecoration(
        labelText: 'Day of month',
        prefixIcon: Icon(Icons.calendar_month),
      ),
      items: List.generate(31, (index) {
        final day = index + 1;
        return DropdownMenuItem(
          value: day,
          child: Text(day.toString()),
        );
      }),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedDayOfMonth = value;
          });
          _emitChange();
        }
      },
    );
  }

  Widget _buildCustomInterval() {
    return TextFormField(
      controller: _intervalController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: 'Every N days',
        prefixIcon: Icon(Icons.timelapse),
        hintText: 'e.g. 2',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        final n = int.tryParse(value);
        if (n == null || n <= 0) return 'Must be greater than 0';
        return null;
      },
      onChanged: (_) => _emitChange(),
    );
  }
}
