import 'package:flutter_test/flutter_test.dart';
import 'package:focusforge/features/boards/domain/board_table_column.dart';
import 'package:focusforge/features/boards/domain/board_model.dart';

void main() {
  // ───────────────────────────────────────────────────
  // ColumnType
  // ───────────────────────────────────────────────────
  group('ColumnType', () {
    test('fromString parses all 9 types correctly', () {
      expect(ColumnType.fromString('status'), ColumnType.status);
      expect(ColumnType.fromString('priority'), ColumnType.priority);
      expect(ColumnType.fromString('person'), ColumnType.person);
      expect(ColumnType.fromString('timeline'), ColumnType.timeline);
      expect(ColumnType.fromString('due_date'), ColumnType.dueDate);
      expect(ColumnType.fromString('text'), ColumnType.text);
      expect(ColumnType.fromString('number'), ColumnType.number);
      expect(ColumnType.fromString('checkbox'), ColumnType.checkbox);
      expect(ColumnType.fromString('link'), ColumnType.link);
    });

    test('fromString returns text for unknown type', () {
      expect(ColumnType.fromString('unknown'), ColumnType.text);
      expect(ColumnType.fromString(''), ColumnType.text);
    });
  });

  // ───────────────────────────────────────────────────
  // TableColumnDef
  // ───────────────────────────────────────────────────
  group('TableColumnDef', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 'col_1',
        'type': 'status',
        'name': 'Status',
        'width': 150.0,
        'position': 1000,
      };

      final col = TableColumnDef.fromJson(json);
      expect(col.id, 'col_1');
      expect(col.type, ColumnType.status);
      expect(col.name, 'Status');
      expect(col.width, 150.0);
      expect(col.position, 1000);

      final output = col.toJson();
      expect(output['id'], 'col_1');
      expect(output['type'], 'status');
      expect(output['name'], 'Status');
      expect(output['width'], 150.0);
      expect(output['position'], 1000);
    });

    test('fromJson handles integer width as double', () {
      final json = {
        'id': 'col_2',
        'type': 'text',
        'name': 'Notes',
        'width': 200,
        'position': 2000,
      };
      final col = TableColumnDef.fromJson(json);
      expect(col.width, 200.0);
    });
  });

  // ───────────────────────────────────────────────────
  // StatusLabelDef
  // ───────────────────────────────────────────────────
  group('StatusLabelDef', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 'default_working',
        'name': 'Working on it',
        'color': '#FF9800',
      };

      final label = StatusLabelDef.fromJson(json);
      expect(label.id, 'default_working');
      expect(label.name, 'Working on it');
      expect(label.color, '#FF9800');

      final output = label.toJson();
      expect(output['id'], 'default_working');
      expect(output['name'], 'Working on it');
      expect(output['color'], '#FF9800');
    });
  });

  // ───────────────────────────────────────────────────
  // BoardGroup
  // ───────────────────────────────────────────────────
  group('BoardGroup', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 'g1',
        'name': 'Sprint 1',
        'color': '#2196F3',
        'position': 1000,
      };

      final group = BoardGroup.fromJson(json);
      expect(group.id, 'g1');
      expect(group.name, 'Sprint 1');
      expect(group.color, '#2196F3');
      expect(group.position, 1000);

      final output = group.toJson();
      expect(output['id'], 'g1');
      expect(output['name'], 'Sprint 1');
      expect(output['color'], '#2196F3');
      expect(output['position'], 1000);
    });

    test('copyWith supports name, color, position', () {
      final group = BoardGroup(
        id: 'g1',
        name: 'Sprint 1',
        color: '#2196F3',
        position: 1000,
      );

      final updated = group.copyWith(name: 'Sprint 2', color: '#FF0000');
      expect(updated.id, 'g1');
      expect(updated.name, 'Sprint 2');
      expect(updated.color, '#FF0000');
      expect(updated.position, 1000);
    });
  });

  // ───────────────────────────────────────────────────
  // BoardMetadata
  // ───────────────────────────────────────────────────
  group('BoardMetadata', () {
    test('fromJson with null returns defaults', () {
      final metadata = BoardMetadata.fromJson(null);
      expect(metadata.columnDefs.length, 6);
      expect(metadata.statusLabels.length, 4);
      expect(metadata.groups.length, 1);
      expect(metadata.groups.first.id, 'default_group');
    });

    test('fromJson with empty map returns defaults', () {
      final metadata = BoardMetadata.fromJson({});
      expect(metadata.columnDefs.length, 6);
      expect(metadata.statusLabels.length, 4);
      expect(metadata.groups.length, 1);
    });

    test('fromJson parses column_defs, status_labels, groups', () {
      final json = {
        'column_defs': [
          {
            'id': 'col_status',
            'type': 'status',
            'name': 'Status',
            'width': 150,
            'position': 1000
          },
        ],
        'status_labels': [
          {'id': 'sl_1', 'name': 'Done', 'color': '#4CAF50'},
        ],
        'groups': [
          {
            'id': 'g1',
            'name': 'Sprint 1',
            'color': '#2196F3',
            'position': 1000
          },
        ],
      };

      final metadata = BoardMetadata.fromJson(json);
      expect(metadata.columnDefs.length, 1);
      expect(metadata.columnDefs.first.id, 'col_status');
      expect(metadata.statusLabels.length, 1);
      expect(metadata.statusLabels.first.name, 'Done');
      expect(metadata.groups.length, 1);
      expect(metadata.groups.first.name, 'Sprint 1');
    });

    test('toJson roundtrips correctly', () {
      final metadata = BoardMetadata.fromJson(null);
      final json = metadata.toJson();

      final restored = BoardMetadata.fromJson(json);
      expect(restored.columnDefs.length, metadata.columnDefs.length);
      expect(restored.statusLabels.length, metadata.statusLabels.length);
      expect(restored.groups.length, metadata.groups.length);
    });
  });

  // ───────────────────────────────────────────────────
  // BoardCard (extended fields)
  // ───────────────────────────────────────────────────
  group('BoardCard (extended fields)', () {
    final baseCardJson = {
      'id': 'card-1',
      'board_id': 'board-1',
      'column_id': 'col-1',
      'title': 'Test Card',
      'description': null,
      'assignee_id': null,
      'priority': 3,
      'due_date': null,
      'position': 1000,
      'created_by': 'user-1',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };

    test('fromJson with new fields parses correctly', () {
      final json = {
        ...baseCardJson,
        'start_date': '2026-02-01T00:00:00Z',
        'status_label': 'Working on it',
        'status_color': '#FF9800',
        'group_id': 'g1',
        'custom_fields': {'notes': 'hello'},
      };

      final card = BoardCard.fromJson(json);
      expect(card.startDate, DateTime.parse('2026-02-01T00:00:00Z'));
      expect(card.statusLabel, 'Working on it');
      expect(card.statusColor, '#FF9800');
      expect(card.groupId, 'g1');
      expect(card.customFields, {'notes': 'hello'});
    });

    test('fromJson without new fields (legacy data) still works', () {
      final card = BoardCard.fromJson(baseCardJson);
      expect(card.startDate, isNull);
      expect(card.statusLabel, isNull);
      expect(card.statusColor, isNull);
      expect(card.groupId, isNull);
      expect(card.customFields, isEmpty);
    });

    test('copyWith supports new fields', () {
      final card = BoardCard.fromJson(baseCardJson);
      final updated = card.copyWith(
        statusLabel: 'Done',
        statusColor: '#4CAF50',
        groupId: 'g2',
      );

      expect(updated.statusLabel, 'Done');
      expect(updated.statusColor, '#4CAF50');
      expect(updated.groupId, 'g2');
      expect(updated.title, 'Test Card');
    });

    test('toJson includes new fields', () {
      final json = {
        ...baseCardJson,
        'start_date': '2026-02-01T00:00:00Z',
        'status_label': 'Working on it',
        'status_color': '#FF9800',
        'group_id': 'g1',
        'custom_fields': {'notes': 'hello'},
      };

      final card = BoardCard.fromJson(json);
      final output = card.toJson();
      expect(output['status_label'], 'Working on it');
      expect(output['status_color'], '#FF9800');
      expect(output['group_id'], 'g1');
      expect(output['custom_fields'], {'notes': 'hello'});
      expect(output.containsKey('start_date'), isTrue);
    });
  });

  // ───────────────────────────────────────────────────
  // Board (metadata)
  // ───────────────────────────────────────────────────
  group('Board (metadata)', () {
    test('fromJson with metadata JSONB parses correctly', () {
      final json = {
        'id': 'board-1',
        'name': 'Test Board',
        'created_by': 'user-1',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'metadata': {
          'column_defs': [
            {
              'id': 'col_status',
              'type': 'status',
              'name': 'Status',
              'width': 150,
              'position': 1000
            },
          ],
          'status_labels': [
            {'id': 'sl_1', 'name': 'Done', 'color': '#4CAF50'},
          ],
          'groups': [
            {
              'id': 'g1',
              'name': 'Group 1',
              'color': '#2196F3',
              'position': 1000
            },
          ],
        },
      };

      final board = Board.fromJson(json);
      expect(board.metadata.columnDefs.length, 1);
      expect(board.metadata.statusLabels.length, 1);
      expect(board.metadata.groups.length, 1);
    });

    test('fromJson without metadata field returns empty defaults', () {
      final json = {
        'id': 'board-1',
        'name': 'Test Board',
        'created_by': 'user-1',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      final board = Board.fromJson(json);
      expect(board.metadata.columnDefs.length, 6);
      expect(board.metadata.statusLabels.length, 4);
      expect(board.metadata.groups.length, 1);
    });

    test('copyWith supports metadata', () {
      final json = {
        'id': 'board-1',
        'name': 'Test Board',
        'created_by': 'user-1',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      final board = Board.fromJson(json);
      final newMetadata = BoardMetadata(
        columnDefs: [],
        statusLabels: [],
        groups: [],
      );
      final updated = board.copyWith(metadata: newMetadata);
      expect(updated.metadata.columnDefs, isEmpty);
      expect(updated.name, 'Test Board');
    });

    test('toJson includes metadata', () {
      final json = {
        'id': 'board-1',
        'name': 'Test Board',
        'created_by': 'user-1',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      final board = Board.fromJson(json);
      final output = board.toJson();
      expect(output.containsKey('metadata'), isTrue);
      expect(output['metadata'], isA<Map<String, dynamic>>());
    });
  });
}
