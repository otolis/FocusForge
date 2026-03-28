import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../profile/domain/profile_model.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../domain/plannable_item_model.dart';
import '../../domain/schedule_block_model.dart';
import '../providers/plannable_items_provider.dart';
import '../providers/planner_provider.dart';
import '../providers/real_items_bridge_provider.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/plannable_items_panel.dart';
import '../widgets/regenerate_bar.dart';
import '../widgets/shimmer_timeline.dart';
import '../widgets/timeline_widget.dart';

/// The main daily planner screen.
///
/// Orchestrates three visual states:
/// 1. **Loading/shimmer** — while the AI generates a schedule
/// 2. **Error** — friendly message with retry button
/// 3. **Normal** — timeline with blocks, empty slots, and energy zones
///
/// Includes a "Plan My Day" FAB for initial generation, a date picker,
/// an items count indicator, and a [RegenerateBar] for re-generation
/// with optional constraints.
class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  bool _initialLoadDone = false;
  Timer? _saveDebounceTimer;

  String get _userId {
    return ref.read(authStateProvider).user?.id ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone && _userId.isNotEmpty) {
      _initialLoadDone = true;
      final notifier = ref.read(plannableItemsProvider(_userId).notifier);
      ref
          .read(plannerProvider(_userId).notifier)
          .loadCachedSchedule(notifier.selectedDate);
    }
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;
    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final plannerState = ref.watch(plannerProvider(userId));
    final itemsAsync = ref.watch(plannableItemsProvider(userId));
    final profileAsync = ref.watch(profileProvider(userId));
    final selectedDate =
        ref.watch(plannableItemsProvider(userId).notifier).selectedDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Import tasks & habits',
            onPressed: _importRealItems,
          ),
          TextButton.icon(
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(_formatDate(selectedDate)),
            onPressed: () => _pickDate(context, userId, selectedDate),
          ),
        ],
      ),
      body: Column(
        children: [
          // Plannable items panel (visible cards for each item)
          _buildItemsPanel(itemsAsync, userId, plannerState.blocks),

          // Main content area
          Expanded(
            child: _buildBody(
              context,
              plannerState: plannerState,
              itemsAsync: itemsAsync,
              profileAsync: profileAsync,
              userId: userId,
            ),
          ),

          // Regenerate bar (only when blocks exist)
          if (plannerState.blocks.isNotEmpty)
            SafeArea(
              top: false,
              child: RegenerateBar(
                userId: userId,
                onRegenerate: () => _generate(userId),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildFab(plannerState, itemsAsync, userId),
    );
  }

  Widget _buildItemsPanel(
    AsyncValue<List<PlannableItem>> itemsAsync,
    String userId,
    List<ScheduleBlock> scheduledBlocks,
  ) {
    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        // Filter out items that have already been scheduled into time blocks
        final scheduledIds = scheduledBlocks.map((b) => b.itemId).toSet();
        final unscheduledItems =
            items.where((item) => !scheduledIds.contains(item.id)).toList();
        if (unscheduledItems.isEmpty) return const SizedBox.shrink();
        return PlannableItemsPanel(
          items: unscheduledItems,
          onDelete: (itemId) => _deleteItem(userId, itemId),
          onAddItem: () => _showAddItemSheet(userId),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _deleteItem(String userId, String itemId) async {
    await ref
        .read(plannableItemsProvider(userId).notifier)
        .deleteItem(itemId);
  }

  Widget _buildBody(
    BuildContext context, {
    required PlannerState plannerState,
    required AsyncValue<List<PlannableItem>> itemsAsync,
    required AsyncValue<Profile> profileAsync,
    required String userId,
  }) {
    // State 1: Generating (shimmer)
    if (plannerState.isGenerating) {
      return const ShimmerTimeline();
    }

    // State 2: Error
    if (plannerState.error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: context.colorScheme.error.withValues(alpha:0.7),
              ),
              const SizedBox(height: 16),
              Text(
                "Oops, couldn't plan your day right now.\nLet's try again!",
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              // Show actual error details for diagnosis.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colorScheme.errorContainer.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plannerState.error!,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 160,
                child: AppButton(
                  label: 'Retry',
                  onPressed: () => _generate(userId),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // State 3: Empty (no blocks and no items)
    final items = itemsAsync.valueOrNull ?? [];
    if (plannerState.blocks.isEmpty && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 64,
                color: context.colorScheme.primary.withValues(alpha:0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Add some items, then let\nAI plan your day!',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add First Item'),
                onPressed: () => _showAddItemSheet(userId),
              ),
            ],
          ),
        ),
      );
    }

    // State 4: Normal timeline
    final energyPattern = profileAsync.valueOrNull?.energyPattern ??
        const EnergyPattern();

    return TimelineWidget(
      blocks: plannerState.blocks,
      energyPattern: energyPattern,
      onEmptySlotTap: () => _showAddItemSheet(userId),
      onBlockMoved: (itemId, newStartMinute) {
        ref
            .read(plannerProvider(userId).notifier)
            .moveBlock(itemId, newStartMinute);
        _saveDebounceTimer?.cancel();
        _saveDebounceTimer = Timer(const Duration(seconds: 2), () {
          ref.read(plannerProvider(userId).notifier).saveCurrentSchedule(
                ref
                    .read(plannableItemsProvider(userId).notifier)
                    .selectedDate,
              );
        });
      },
      onBlockTap: _navigateToSource,
      onBlockComplete: _toggleBlockCompletion,
    );
  }

  Widget? _buildFab(
    PlannerState plannerState,
    AsyncValue<List<PlannableItem>> itemsAsync,
    String userId,
  ) {
    if (plannerState.isGenerating) return null;

    final items = itemsAsync.valueOrNull ?? [];

    // Show "Plan My Day" FAB when there are items but no blocks
    if (plannerState.blocks.isEmpty && items.isNotEmpty) {
      return FloatingActionButton.extended(
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Plan My Day'),
        onPressed: () => _generate(userId),
      );
    }

    // Show "Regenerate" FAB when blocks exist so user can re-plan easily
    if (plannerState.blocks.isNotEmpty) {
      return FloatingActionButton.extended(
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Regenerate'),
        onPressed: () => _generate(userId),
      );
    }

    return null;
  }

  /// Navigates to the source task or habit detail screen for a planner block.
  ///
  /// Looks up [itemId] in taskListProvider first, then habitListProvider.
  /// Tasks navigate to /tasks/:id, habits navigate to /habits/:id.
  void _navigateToSource(String itemId) {
    final tasks = ref.read(taskListProvider).valueOrNull ?? [];
    final isTask = tasks.any((t) => t.id == itemId);
    if (isTask) {
      context.push('/tasks/$itemId');
      return;
    }

    final habits = ref.read(habitListProvider).valueOrNull ?? [];
    final isHabit = habits.any((h) => h.id == itemId);
    if (isHabit) {
      context.push('/habits/$itemId');
    }
  }

  /// Toggles completion of the underlying task or habit for a planner block.
  ///
  /// For tasks: calls toggleComplete on taskListProvider.
  /// For habits: calls checkIn on habitListProvider.
  Future<void> _toggleBlockCompletion(String itemId) async {
    final tasks = ref.read(taskListProvider).valueOrNull ?? [];
    final isTask = tasks.any((t) => t.id == itemId);
    if (isTask) {
      await ref.read(taskListProvider.notifier).toggleComplete(itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task completion toggled')),
        );
      }
      return;
    }

    final habits = ref.read(habitListProvider).valueOrNull ?? [];
    final isHabit = habits.any((h) => h.id == itemId);
    if (isHabit) {
      await ref.read(habitListProvider.notifier).checkIn(itemId, count: 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit checked in')),
        );
      }
    }
  }

  /// Imports uncompleted tasks and incomplete habits as plannable items.
  /// Idempotent: skips items already imported for the current date.
  Future<void> _importRealItems() async {
    final userId = _userId;
    if (userId.isEmpty) return;

    final realItems = ref.read(realPlannableItemsProvider);
    if (realItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending tasks or habits to import')),
      );
      return;
    }

    // Build set of already-imported source keys for the current date
    final existingItems =
        ref.read(plannableItemsProvider(userId)).valueOrNull ?? [];
    final importedKeys = <String>{};
    for (final item in existingItems) {
      if (item.sourceType != null && item.sourceId != null) {
        importedKeys.add('${item.sourceType}:${item.sourceId}');
      }
    }

    final notifier = ref.read(plannableItemsProvider(userId).notifier);
    int importedCount = 0;

    for (final item in realItems) {
      // Skip already-imported items (idempotent)
      final key = '${item.sourceType}:${item.sourceId}';
      if (importedKeys.contains(key)) continue;

      await notifier.addItem(
        title: item.title,
        durationMinutes: item.durationMinutes,
        energyLevel: item.energyLevel,
        sourceType: item.sourceType,
        sourceId: item.sourceId,
      );
      importedCount++;
    }

    if (mounted) {
      final message = importedCount > 0
          ? 'Imported $importedCount items'
          : 'All items already imported';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _generate(String userId) async {
    final items = ref.read(plannableItemsProvider(userId)).valueOrNull ?? [];
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some items first!')),
      );
      return;
    }

    final profile = ref.read(profileProvider(userId)).valueOrNull;
    final energyPattern = profile?.energyPattern ?? const EnergyPattern();
    final constraints =
        ref.read(plannerProvider(userId)).constraintsText;
    final selectedDate =
        ref.read(plannableItemsProvider(userId).notifier).selectedDate;

    await ref.read(plannerProvider(userId).notifier).generateSchedule(
          items: items,
          energyPattern: energyPattern,
          constraints: constraints,
          planDate: selectedDate,
        );
  }

  void _showAddItemSheet(String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddItemSheet(userId: userId),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    String userId,
    DateTime currentDate,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year, now.month, now.day).add(
        const Duration(days: 30),
      ),
    );
    if (picked != null && picked != currentDate) {
      await ref
          .read(plannableItemsProvider(userId).notifier)
          .setDate(picked);
      await ref
          .read(plannerProvider(userId).notifier)
          .loadCachedSchedule(picked);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == tomorrow) return 'Tomorrow';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
