import 'board_model.dart';

/// Column type for table-view columns in Monday.com-style boards.
///
/// Covers all 9 supported column types. Each type controls how the
/// cell renders and what editor appears on tap.
enum ColumnType {
  status,
  priority,
  person,
  timeline,
  dueDate,
  text,
  number,
  checkbox,
  link;

  /// Serialization name used in JSON / database.
  String get serialName {
    switch (this) {
      case ColumnType.dueDate:
        return 'due_date';
      default:
        return name;
    }
  }

  /// Parse a column type from its database string value.
  ///
  /// Returns [ColumnType.text] for unknown values (safe fallback).
  static ColumnType fromString(String value) {
    // Handle snake_case from DB
    if (value == 'due_date') return ColumnType.dueDate;
    return ColumnType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ColumnType.text,
    );
  }
}

/// Definition of a single table-view column.
///
/// Stored inside [BoardMetadata.columnDefs]. The [position] field uses
/// gap-based ordering (1000, 2000, ...) for reorder-friendly inserts.
class TableColumnDef {
  final String id;
  final ColumnType type;
  final String name;
  final double width;
  final int position;

  const TableColumnDef({
    required this.id,
    required this.type,
    required this.name,
    this.width = 150,
    required this.position,
  });

  factory TableColumnDef.fromJson(Map<String, dynamic> json) {
    return TableColumnDef(
      id: json['id'] as String,
      type: ColumnType.fromString(json['type'] as String),
      name: json['name'] as String,
      width: (json['width'] as num).toDouble(),
      position: json['position'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.serialName,
        'name': name,
        'width': width,
        'position': position,
      };

  TableColumnDef copyWith({
    String? name,
    double? width,
    int? position,
  }) {
    return TableColumnDef(
      id: id,
      type: type,
      name: name ?? this.name,
      width: width ?? this.width,
      position: position ?? this.position,
    );
  }
}

/// A custom status label with a color, defined per board.
///
/// Stored inside [BoardMetadata.statusLabels].
class StatusLabelDef {
  final String id;
  final String name;
  final String color;

  const StatusLabelDef({
    required this.id,
    required this.name,
    required this.color,
  });

  factory StatusLabelDef.fromJson(Map<String, dynamic> json) {
    return StatusLabelDef(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
      };
}

/// Aggregate metadata stored as JSONB on the `boards` table.
///
/// Contains the table-view column definitions, custom status labels,
/// and group definitions. Provides sensible defaults when the metadata
/// field is null or empty (backward compatible with pre-table-view boards).
class BoardMetadata {
  final List<TableColumnDef> columnDefs;
  final List<StatusLabelDef> statusLabels;
  final List<BoardGroup> groups;

  const BoardMetadata({
    required this.columnDefs,
    required this.statusLabels,
    required this.groups,
  });

  /// Parse from JSONB map. Returns defaults when [json] is null or empty.
  factory BoardMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return BoardMetadata._defaults();
    }

    final colDefs = json['column_defs'] as List<dynamic>?;
    final labels = json['status_labels'] as List<dynamic>?;
    final grps = json['groups'] as List<dynamic>?;

    return BoardMetadata(
      columnDefs: colDefs != null && colDefs.isNotEmpty
          ? colDefs
              .map((e) =>
                  TableColumnDef.fromJson(e as Map<String, dynamic>))
              .toList()
          : _defaultColumnDefs,
      statusLabels: labels != null && labels.isNotEmpty
          ? labels
              .map((e) =>
                  StatusLabelDef.fromJson(e as Map<String, dynamic>))
              .toList()
          : _defaultStatusLabels,
      groups: grps != null && grps.isNotEmpty
          ? grps
              .map((e) =>
                  BoardGroup.fromJson(e as Map<String, dynamic>))
              .toList()
          : _defaultGroups,
    );
  }

  Map<String, dynamic> toJson() => {
        'column_defs': columnDefs.map((c) => c.toJson()).toList(),
        'status_labels': statusLabels.map((s) => s.toJson()).toList(),
        'groups': groups.map((g) => g.toJson()).toList(),
      };

  // ─── Defaults ────────────────────────────────────

  factory BoardMetadata._defaults() => BoardMetadata(
        columnDefs: _defaultColumnDefs,
        statusLabels: _defaultStatusLabels,
        groups: _defaultGroups,
      );

  static final List<TableColumnDef> _defaultColumnDefs = const [
    TableColumnDef(
        id: 'col_status',
        type: ColumnType.status,
        name: 'Status',
        width: 150,
        position: 1000),
    TableColumnDef(
        id: 'col_priority',
        type: ColumnType.priority,
        name: 'Priority',
        width: 120,
        position: 2000),
    TableColumnDef(
        id: 'col_person',
        type: ColumnType.person,
        name: 'Person',
        width: 100,
        position: 3000),
    TableColumnDef(
        id: 'col_timeline',
        type: ColumnType.timeline,
        name: 'Timeline',
        width: 200,
        position: 4000),
    TableColumnDef(
        id: 'col_due',
        type: ColumnType.dueDate,
        name: 'Due Date',
        width: 120,
        position: 5000),
    TableColumnDef(
        id: 'col_desc',
        type: ColumnType.text,
        name: 'Description',
        width: 200,
        position: 6000),
  ];

  static final List<StatusLabelDef> _defaultStatusLabels = const [
    StatusLabelDef(
        id: 'default_working', name: 'Working on it', color: '#FF9800'),
    StatusLabelDef(id: 'default_done', name: 'Done', color: '#4CAF50'),
    StatusLabelDef(id: 'default_stuck', name: 'Stuck', color: '#F44336'),
    StatusLabelDef(
        id: 'default_not_started', name: 'Not Started', color: '#9E9E9E'),
  ];

  static final List<BoardGroup> _defaultGroups = const [
    BoardGroup(
        id: 'default_group',
        name: 'Group 1',
        color: '#2196F3',
        position: 1000),
  ];
}
