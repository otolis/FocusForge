import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/profile_model.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/plannable_item_model.dart';
import '../providers/plannable_items_provider.dart';
import '../providers/planner_provider.dart';
import '../widgets/add_item_sheet.dart';
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
          TextButton.icon(
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(_formatDate(selectedDate)),
            onPressed: () => _pickDate(context, userId, selectedDate),
          ),
        ],
      ),
      body: Column(
        children: [
          // Items count badge
          _buildItemsCountBar(itemsAsync),

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
            RegenerateBar(
              userId: userId,
              onRegenerate: () => _generate(userId),
            ),
        ],
      ),
      floatingActionButton: _buildFab(plannerState, itemsAsync, userId),
    );
  }

  Widget _buildItemsCountBar(AsyncValue<List<PlannableItem>> itemsAsync) {
    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.checklist_rounded,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                '${items.length} item${items.length == 1 ? '' : 's'} to schedule',
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: context.colorScheme.error.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                "Oops, couldn't plan your day right now.\nLet's try again!",
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge,
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
                color: context.colorScheme.primary.withOpacity(0.5),
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

    // Show small add FAB when blocks exist (so user can add more items)
    if (plannerState.blocks.isNotEmpty) {
      return FloatingActionButton.small(
        onPressed: () => _showAddItemSheet(userId),
        child: const Icon(Icons.add_rounded),
      );
    }

    return null;
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

    await ref.read(plannerProvider(userId).notifier).generateSchedule(
          items: items,
          energyPattern: energyPattern,
          constraints: constraints,
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
