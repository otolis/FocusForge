import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/task_filter.dart';
import '../../domain/task_model.dart';
import '../providers/category_provider.dart';
import '../providers/task_filter_provider.dart';
import 'priority_badge.dart';

/// A horizontal scrollable bar of filter chips for priority, category, and
/// date range, plus a toggleable search field with debounced input.
class TaskFilterBar extends ConsumerStatefulWidget {
  const TaskFilterBar({super.key});

  @override
  ConsumerState<TaskFilterBar> createState() => _TaskFilterBarState();
}

class _TaskFilterBarState extends ConsumerState<TaskFilterBar> {
  bool _searchActive = false;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final current = ref.read(taskFilterProvider);
      ref.read(taskFilterProvider.notifier).state = current.copyWith(
        searchQuery: value,
        clearSearch: value.isEmpty,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(taskFilterProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search row (expandable)
          if (_searchActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                      setState(() => _searchActive = false);
                    },
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          // Chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Search toggle
                if (!_searchActive)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => setState(() => _searchActive = true),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                // Priority filter chips
                ...Priority.values.map((p) {
                  final isSelected = filter.priority == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(p.name.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(taskFilterProvider.notifier).state =
                            selected
                                ? filter.copyWith(priority: p)
                                : filter.copyWith(clearPriority: true);
                      },
                      selectedColor: PriorityBadge.colorFor(p, context.colorScheme).withValues(alpha: 0.25),
                      checkmarkColor: PriorityBadge.colorFor(p, context.colorScheme),
                    ),
                  );
                }),
                // Category filter chips
                ...categoriesAsync.maybeWhen(
                  data: (categories) => categories.map((cat) {
                    final isSelected = filter.categoryId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        avatar: CircleAvatar(
                          backgroundColor: cat.color,
                          radius: 8,
                        ),
                        onSelected: (selected) {
                          ref.read(taskFilterProvider.notifier).state =
                              selected
                                  ? filter.copyWith(categoryId: cat.id)
                                  : filter.copyWith(clearCategory: true);
                        },
                      ),
                    );
                  }),
                  orElse: () => <Widget>[],
                ),
                // Date range chip
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    filter.dateFrom != null && filter.dateTo != null
                        ? '${_shortDate(filter.dateFrom!)} - ${_shortDate(filter.dateTo!)}'
                        : 'Date range',
                  ),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                      initialDateRange: filter.dateFrom != null &&
                              filter.dateTo != null
                          ? DateTimeRange(
                              start: filter.dateFrom!,
                              end: filter.dateTo!,
                            )
                          : null,
                    );
                    if (range != null) {
                      ref.read(taskFilterProvider.notifier).state =
                          filter.copyWith(
                        dateFrom: range.start,
                        dateTo: range.end,
                      );
                    }
                  },
                ),
                // Clear all filters
                if (!filter.isEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: context.colorScheme.error,
                      size: 20,
                    ),
                    onPressed: () {
                      ref.read(taskFilterProvider.notifier).state =
                          const TaskFilter();
                      _searchController.clear();
                      setState(() => _searchActive = false);
                    },
                    tooltip: 'Clear all filters',
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
