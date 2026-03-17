import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/parsed_task_input.dart';
import '../providers/smart_input_provider.dart';
import '../widgets/smart_input_field.dart';

/// Standalone demo screen for testing the smart input feature.
///
/// Shows the [SmartInputField] and a debug panel displaying all parsed
/// fields. This screen is for development/demo purposes. Phase 8
/// integrates smart input into the actual task creation flow.
class SmartInputDemoScreen extends ConsumerStatefulWidget {
  const SmartInputDemoScreen({super.key});

  @override
  ConsumerState<SmartInputDemoScreen> createState() =>
      _SmartInputDemoScreenState();
}

class _SmartInputDemoScreenState extends ConsumerState<SmartInputDemoScreen> {
  ParsedTaskInput? _lastParsed;

  @override
  void initState() {
    super.initState();
    // Initialize TFLite model when this screen loads
    ref.read(smartInputInitProvider);
  }

  @override
  Widget build(BuildContext context) {
    final initState = ref.watch(smartInputInitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Task Input'),
        actions: [
          // Show model loading status
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: initState.when(
              data: (_) =>
                  const Icon(Icons.check_circle, color: Colors.green),
              loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Tooltip(
                message: 'ML model not loaded - regex parsing still works',
                child: Icon(Icons.warning_amber, color: Colors.orange),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type a task naturally:',
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SmartInputField(
              onParsed: (parsed) {
                setState(() => _lastParsed = parsed);
              },
              hintText: 'e.g., "Buy groceries tomorrow high priority"',
            ),
            const SizedBox(height: 24),
            if (_lastParsed != null) ...[
              Text(
                'Debug: Parsed Result',
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(),
              _debugRow('Raw Text', _lastParsed!.rawText),
              _debugRow('Extracted Title', _lastParsed!.extractedTitle),
              _debugRow(
                'Deadline',
                _lastParsed!.suggestedDeadline?.toIso8601String() ?? 'none',
              ),
              _debugRow(
                'Priority',
                _lastParsed!.suggestedPriority ?? 'none',
              ),
              _debugRow(
                'Category',
                _lastParsed!.suggestedCategory?.displayName ?? 'none',
              ),
              _debugRow(
                'Category Confidence',
                '${(_lastParsed!.categoryConfidence * 100).toStringAsFixed(1)}%',
              ),
              _debugRow(
                'Priority Confidence',
                '${(_lastParsed!.priorityConfidence * 100).toStringAsFixed(1)}%',
              ),
            ],
            const Spacer(),
            Text(
              'Try: "urgent fix server crash", "study for exam next Friday", '
              '"buy milk tomorrow"',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _debugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: context.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
