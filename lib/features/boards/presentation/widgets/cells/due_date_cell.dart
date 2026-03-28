import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A cell displaying a formatted due date or an em dash placeholder.
///
/// When [dueDate] is set, shows the date formatted as "MMM d" (e.g. "Mar 28").
/// If the date is in the past, the text renders in [ColorScheme.error] color.
/// When no date is set, shows an em dash character.
class DueDateCell extends StatelessWidget {
  /// The due date to display. Null means not set.
  final DateTime? dueDate;

  /// Called when the cell is tapped (opens date picker).
  final VoidCallback? onTap;

  const DueDateCell({
    super.key,
    this.dueDate,
    this.onTap,
  });

  static final _dateFormat = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasDate = dueDate != null;

    final semanticLabel = hasDate
        ? 'Due date: ${_dateFormat.format(dueDate!)}'
        : 'Due date: not set';

    return Semantics(
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          child: hasDate ? _buildDate(cs) : _buildPlaceholder(cs),
        ),
      ),
    );
  }

  Widget _buildDate(ColorScheme cs) {
    final now = DateTime.now();
    final isOverdue = dueDate!.isBefore(DateTime(now.year, now.month, now.day));

    return Text(
      _dateFormat.format(dueDate!),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isOverdue ? cs.error : cs.onSurface,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildPlaceholder(ColorScheme cs) {
    return Text(
      '\u2014',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
