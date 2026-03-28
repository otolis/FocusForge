import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_constants.dart';

/// A small icon button that calls the `rewrite-title` Supabase Edge Function
/// to polish the text in the given [controller].
///
/// Shows [Icons.auto_awesome] when idle and a compact [CircularProgressIndicator]
/// while the AI request is in flight. Disabled when the controller text is empty
/// or when a request is already loading.
///
/// Usage:
/// ```dart
/// AiRewriteButton(controller: _titleController)
/// ```
class AiRewriteButton extends ConsumerStatefulWidget {
  const AiRewriteButton({
    super.key,
    required this.controller,
    this.onRewritten,
  });

  /// The text editing controller whose value will be rewritten.
  final TextEditingController controller;

  /// Optional callback invoked after the title has been successfully rewritten,
  /// so the parent can rebuild if needed.
  final VoidCallback? onRewritten;

  @override
  ConsumerState<AiRewriteButton> createState() => _AiRewriteButtonState();
}

class _AiRewriteButtonState extends ConsumerState<AiRewriteButton> {
  bool _isLoading = false;

  Future<void> _rewriteTitle() async {
    final rawTitle = widget.controller.text.trim();
    if (rawTitle.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'rewrite-title',
        headers: {
          'Authorization': 'Bearer ${SupabaseConstants.anonKey}',
        },
        body: {'title': rawTitle},
      );

      var data = response.data;

      // The SDK decodes JSON responses automatically, but if the response
      // Content-Type is missing or unexpected, data arrives as a raw String.
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          throw Exception('Unexpected response format from rewrite-title');
        }
      }

      if (data is Map<String, dynamic> && data['rewritten_title'] != null) {
        final rewrittenTitle = data['rewritten_title'] as String;
        widget.controller.text = rewrittenTitle;
        widget.controller.selection = TextSelection.collapsed(
          offset: widget.controller.text.length,
        );
        widget.onRewritten?.call();
      } else if (data is Map<String, dynamic> && data['error'] != null) {
        throw Exception(data['error']);
      } else {
        throw Exception('Unexpected response from rewrite-title');
      }
    } on FunctionException catch (e) {
      if (!mounted) return;
      final details = e.details;
      final errorMsg = details is Map ? details['error'] ?? details : details;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI rewrite failed: $errorMsg')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI rewrite failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: _isLoading
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              icon: Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              tooltip: 'AI Rewrite',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: widget.controller.text.trim().isEmpty
                  ? null
                  : _rewriteTitle,
            ),
    );
  }
}
