import 'package:flutter/material.dart';

import '../../../domain/board_table_column.dart';

/// Column header row for the table view.
///
/// Renders scrollable column headers with resize handles on the right edge
/// and drag-to-reorder support via [LongPressDraggable]/[DragTarget].
/// A "+" button at the end allows adding new columns.
class TableHeaderRow extends StatefulWidget {
  /// Column definitions excluding the sticky name column.
  final List<TableColumnDef> columns;

  /// Called during column resize drag with the column index and delta.
  final void Function(int columnIndex, double delta) onResize;

  /// Called when a column resize drag ends.
  final VoidCallback onResizeEnd;

  /// Called when the add-column button is tapped.
  final VoidCallback onAddColumn;

  /// Called when a column header is dragged to a new position.
  final void Function(int oldIndex, int newIndex) onReorder;

  const TableHeaderRow({
    super.key,
    required this.columns,
    required this.onResize,
    required this.onResizeEnd,
    required this.onAddColumn,
    required this.onReorder,
  });

  @override
  State<TableHeaderRow> createState() => _TableHeaderRowState();
}

class _TableHeaderRowState extends State<TableHeaderRow> {
  /// Index of the column currently being hovered over during a drag.
  int? _dropTargetIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column headers
          for (int i = 0; i < widget.columns.length; i++)
            _buildHeaderCell(i, colorScheme),

          // "+" add column button
          SizedBox(
            width: 48,
            height: 40,
            child: IconButton(
              onPressed: widget.onAddColumn,
              icon: const Icon(Icons.add, size: 20),
              tooltip: 'Add column',
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(int index, ColorScheme colorScheme) {
    final column = widget.columns[index];
    final isDropTarget = _dropTargetIndex == index;

    final innerContent = Container(
      width: column.width,
      height: 40,
      decoration: BoxDecoration(
        border: isDropTarget
            ? Border(
                left: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              )
            : null,
      ),
      child: Stack(
        children: [
          // Column name text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                column.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),

          // Resize handle on the right edge
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                widget.onResize(index, details.delta.dx);
              },
              onHorizontalDragEnd: (_) {
                widget.onResizeEnd();
              },
              child: const MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: SizedBox(
                  width: 6,
                  child: ColoredBox(color: Colors.transparent),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Wrap in DragTarget for accepting column reorder drops
    final headerContent = DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        if (details.data != index) {
          setState(() => _dropTargetIndex = index);
          return true;
        }
        return false;
      },
      onLeave: (_) {
        setState(() {
          if (_dropTargetIndex == index) _dropTargetIndex = null;
        });
      },
      onAcceptWithDetails: (details) {
        setState(() => _dropTargetIndex = null);
        widget.onReorder(details.data, index);
      },
      builder: (context, candidateData, rejectedData) {
        return innerContent;
      },
    );

    // Wrap in LongPressDraggable for initiating column reorder
    return LongPressDraggable<int>(
      data: index,
      axis: Axis.horizontal,
      feedback: Material(
        elevation: 4,
        child: Container(
          width: column.width,
          height: 40,
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.9),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            column.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: SizedBox(
          width: column.width,
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                column.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
      child: headerContent,
    );
  }
}
