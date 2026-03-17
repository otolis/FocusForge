/// Roles for board membership, matching the `board_role` PostgreSQL enum.
enum BoardRole {
  owner,
  editor,
  viewer;

  /// Parse from database string value.
  static BoardRole fromString(String value) {
    return BoardRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => BoardRole.viewer,
    );
  }
}
