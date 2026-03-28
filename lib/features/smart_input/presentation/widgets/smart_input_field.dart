import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/parsed_task_input.dart';
import '../providers/smart_input_provider.dart';
import 'suggestion_chips.dart';

/// A TextField that parses natural language task input with 300ms debounce.
///
/// Displays suggestion chips below the field showing extracted deadline,
/// priority, and category. Each chip is tappable for editing.
///
/// The debounce prevents excessive re-parsing while the user is actively
/// typing. Parsed results are emitted via [onParsed] after the 300ms
/// quiet period.
class SmartInputField extends ConsumerStatefulWidget {
  final ValueChanged<ParsedTaskInput>? onParsed;
  final String? hintText;
  final TextEditingController? controller;

  const SmartInputField({
    super.key,
    this.onParsed,
    this.hintText,
    this.controller,
  });

  @override
  ConsumerState<SmartInputField> createState() => _SmartInputFieldState();
}

class _SmartInputFieldState extends ConsumerState<SmartInputField> {
  late TextEditingController _controller;
  Timer? _debounceTimer;
  String _currentInput = '';

  /// Tracks the last parsed result that was sent to [onParsed].
  /// Only notify the parent when the result actually changes, preventing
  /// an infinite rebuild loop (build -> onParsed -> parent setState ->
  /// child rebuild -> onParsed -> ...).
  ParsedTaskInput? _lastNotifiedParsed;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _currentInput = text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read parsed result reactively
    final parsed = _currentInput.isNotEmpty
        ? ref.watch(smartInputProvider(_currentInput))
        : const ParsedTaskInput(rawText: '', extractedTitle: '');

    // Notify parent of parsed result only when it changes.
    // Without this guard, every build schedules a postFrameCallback that
    // calls onParsed, which triggers parent setState, which rebuilds this
    // widget, which schedules another callback — creating an infinite loop.
    if (_currentInput.isNotEmpty && parsed != _lastNotifiedParsed) {
      _lastNotifiedParsed = parsed;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onParsed?.call(parsed);
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onTextChanged,
          decoration: InputDecoration(
            hintText: widget.hintText ??
                'e.g., "Buy groceries tomorrow high priority"',
            prefixIcon: const Icon(Icons.auto_awesome),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor:
                context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          textInputAction: TextInputAction.done,
          maxLines: 1,
        ),
        SuggestionChips(
          parsed: parsed,
          onEditDeadline: (date) {
            // Placeholder: Phase 8 will wire date picker
          },
          onEditPriority: (priority) {
            // Placeholder: Phase 8 will wire priority selector
          },
          onEditCategory: (category) {
            // Placeholder: Phase 8 will wire category picker
          },
        ),
        if (_currentInput.isNotEmpty && parsed.extractedTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Title: ${parsed.extractedTitle}',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
