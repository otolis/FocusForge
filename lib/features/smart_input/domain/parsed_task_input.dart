import 'smart_input_category.dart';

/// Represents the structured output of parsing a natural language task input.
///
/// The NLP parser processes raw text and extracts structured fields:
/// - [extractedTitle]: The cleaned task title with parsed tokens removed
/// - [suggestedDeadline]: A date/time extracted from natural language references
/// - [suggestedPriority]: Priority level (P1-P4) from keyword matching
/// - [suggestedCategory]: Category from keyword matching or TFLite classification
/// - [categoryConfidence]: Confidence score (0.0-1.0) for the category suggestion
/// - [priorityConfidence]: Confidence score (0.0-1.0) for the priority suggestion
///
/// All suggested fields are optional -- the parser may not find matches for
/// every field in the input text.
class ParsedTaskInput {
  /// The original unmodified input text.
  final String rawText;

  /// The cleaned task title with priority and date tokens stripped.
  final String extractedTitle;

  /// A deadline date extracted from natural language date references.
  /// Examples: "tomorrow", "next Friday", "by March 30".
  final DateTime? suggestedDeadline;

  /// Priority level extracted from keywords.
  /// Values: 'P1' (urgent), 'P2' (high), 'P3' (medium), 'P4' (low).
  final String? suggestedPriority;

  /// Category suggested by keyword matching or TFLite classification.
  final SmartInputCategory? suggestedCategory;

  /// Confidence score (0.0-1.0) for the category suggestion.
  final double categoryConfidence;

  /// Confidence score (0.0-1.0) for the priority suggestion.
  final double priorityConfidence;

  const ParsedTaskInput({
    required this.rawText,
    required this.extractedTitle,
    this.suggestedDeadline,
    this.suggestedPriority,
    this.suggestedCategory,
    this.categoryConfidence = 0.0,
    this.priorityConfidence = 0.0,
  });

  /// Returns a new [ParsedTaskInput] with the given fields replaced.
  ///
  /// Fields not specified retain their current values.
  ParsedTaskInput copyWith({
    String? rawText,
    String? extractedTitle,
    DateTime? suggestedDeadline,
    String? suggestedPriority,
    SmartInputCategory? suggestedCategory,
    double? categoryConfidence,
    double? priorityConfidence,
  }) {
    return ParsedTaskInput(
      rawText: rawText ?? this.rawText,
      extractedTitle: extractedTitle ?? this.extractedTitle,
      suggestedDeadline: suggestedDeadline ?? this.suggestedDeadline,
      suggestedPriority: suggestedPriority ?? this.suggestedPriority,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      categoryConfidence: categoryConfidence ?? this.categoryConfidence,
      priorityConfidence: priorityConfidence ?? this.priorityConfidence,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParsedTaskInput &&
        other.rawText == rawText &&
        other.extractedTitle == extractedTitle &&
        other.suggestedDeadline == suggestedDeadline &&
        other.suggestedPriority == suggestedPriority &&
        other.suggestedCategory == suggestedCategory &&
        other.categoryConfidence == categoryConfidence &&
        other.priorityConfidence == priorityConfidence;
  }

  @override
  int get hashCode => Object.hash(
        rawText,
        extractedTitle,
        suggestedDeadline,
        suggestedPriority,
        suggestedCategory,
        categoryConfidence,
        priorityConfidence,
      );

  @override
  String toString() =>
      'ParsedTaskInput(title: $extractedTitle, priority: $suggestedPriority, '
      'deadline: $suggestedDeadline, category: $suggestedCategory)';
}
