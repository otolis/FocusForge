import 'board_role.dart';

/// A collaborative Kanban board.
///
/// Stored in the `public.boards` Supabase table. Created via the
/// `create_board_with_defaults` RPC which atomically inserts the board,
/// owner membership, and 3 default columns.
class Board {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Board({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Produces JSON for insert/update. Excludes `id` and timestamps
  /// (server-managed).
  Map<String, dynamic> toJson() => {
        'name': name,
        'created_by': createdBy,
      };

  Board copyWith({String? name}) {
    return Board(
      id: id,
      name: name ?? this.name,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// A Kanban column within a board.
///
/// Stored in the `public.board_columns` table. Ordered by `position`
/// using a gap strategy (1000, 2000, 3000...) to allow insertions
/// without reordering all items.
class BoardColumn {
  final String id;
  final String boardId;
  final String name;
  final int position;
  final DateTime createdAt;

  const BoardColumn({
    required this.id,
    required this.boardId,
    required this.name,
    required this.position,
    required this.createdAt,
  });

  factory BoardColumn.fromJson(Map<String, dynamic> json) {
    return BoardColumn(
      id: json['id'] as String,
      boardId: json['board_id'] as String,
      name: json['name'] as String,
      position: json['position'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'board_id': boardId,
        'name': name,
        'position': position,
      };

  BoardColumn copyWith({String? name, int? position}) {
    return BoardColumn(
      id: id,
      boardId: boardId,
      name: name ?? this.name,
      position: position ?? this.position,
      createdAt: createdAt,
    );
  }
}

/// A card (task item) within a Kanban column.
///
/// Stored in the `public.board_cards` table. Cards belong to a board
/// and a column, and are ordered by `position` within their column.
class BoardCard {
  final String id;
  final String boardId;
  final String columnId;
  final String title;
  final String? description;
  final String? assigneeId;
  final int priority;
  final DateTime? dueDate;
  final int position;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BoardCard({
    required this.id,
    required this.boardId,
    required this.columnId,
    required this.title,
    this.description,
    this.assigneeId,
    this.priority = 3,
    this.dueDate,
    required this.position,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BoardCard.fromJson(Map<String, dynamic> json) {
    return BoardCard(
      id: json['id'] as String,
      boardId: json['board_id'] as String,
      columnId: json['column_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      assigneeId: json['assignee_id'] as String?,
      priority: json['priority'] as int? ?? 3,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      position: json['position'] as int,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Produces JSON for insert/update. Excludes `id` and `created_at`
  /// (server-managed).
  Map<String, dynamic> toJson() => {
        'board_id': boardId,
        'column_id': columnId,
        'title': title,
        'description': description,
        'assignee_id': assigneeId,
        'priority': priority,
        'due_date': dueDate?.toIso8601String(),
        'position': position,
        'created_by': createdBy,
        'updated_at': DateTime.now().toIso8601String(),
      };

  BoardCard copyWith({
    String? columnId,
    String? title,
    String? description,
    String? assigneeId,
    int? priority,
    DateTime? dueDate,
    int? position,
  }) {
    return BoardCard(
      id: id,
      boardId: boardId,
      columnId: columnId ?? this.columnId,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      position: position ?? this.position,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// A member of a board with a specific role.
///
/// Stored in the `public.board_members` junction table. The `displayName`
/// and `avatarUrl` fields are populated from a separate `profiles` query
/// and are not stored in the `board_members` table itself.
class BoardMember {
  final String id;
  final String boardId;
  final String userId;
  final BoardRole role;
  final DateTime invitedAt;

  /// Populated via join with profiles table (not stored in board_members).
  final String? displayName;

  /// Populated via join with profiles table (not stored in board_members).
  final String? avatarUrl;

  const BoardMember({
    required this.id,
    required this.boardId,
    required this.userId,
    required this.role,
    required this.invitedAt,
    this.displayName,
    this.avatarUrl,
  });

  factory BoardMember.fromJson(Map<String, dynamic> json) {
    // Handle optional profile data (merged by BoardMemberRepository)
    final profileData = json['profiles'] as Map<String, dynamic>?;

    return BoardMember(
      id: json['id'] as String,
      boardId: json['board_id'] as String,
      userId: json['user_id'] as String,
      role: BoardRole.fromString(json['role'] as String),
      invitedAt: json['invited_at'] != null
          ? DateTime.parse(json['invited_at'] as String)
          : DateTime.now(),
      displayName: profileData?['display_name'] as String?,
      avatarUrl: profileData?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'board_id': boardId,
        'user_id': userId,
        'role': role.name,
      };

  BoardMember copyWith({BoardRole? role}) {
    return BoardMember(
      id: id,
      boardId: boardId,
      userId: userId,
      role: role ?? this.role,
      invitedAt: invitedAt,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }
}
