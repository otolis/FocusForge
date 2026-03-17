import 'package:chrono_dart/chrono_dart.dart' show Chrono;

import '../domain/parsed_task_input.dart';
import '../domain/smart_input_category.dart';

/// Service that parses natural language task text into structured fields.
///
/// Processing pipeline (in order):
/// 1. Extract priority keywords (deterministic regex)
/// 2. Extract date/time references (chrono_dart)
/// 3. Extract category keywords (deterministic keyword matching)
/// 4. Clean remaining text into a task title
///
/// Priority and date tokens are stripped from the title.
/// Category keywords are NOT stripped (they carry task meaning).
class NlpParserService {
  /// Regex patterns for priority keyword extraction, ordered P1 -> P4.
  ///
  /// Uses word boundary anchors to avoid false positives on common words.
  /// Multi-word patterns (e.g., "high priority") are preferred over single
  /// words to reduce ambiguity.
  static final _priorityPatterns = {
    'P1': RegExp(
      r'\b(urgent|critical|asap|p1|priority\s*1|highest\s*priority|!!!)\b',
      caseSensitive: false,
    ),
    'P2': RegExp(
      r'\b(high\s*priority|important|p2|priority\s*2)\b',
      caseSensitive: false,
    ),
    'P3': RegExp(
      r'\b(medium\s*priority|normal|p3|priority\s*3)\b',
      caseSensitive: false,
    ),
    'P4': RegExp(
      r'\b(low\s*priority|whenever|no\s*rush|p4|priority\s*4)\b',
      caseSensitive: false,
    ),
  };

  /// Pattern for standalone "high" and "low" at sentence boundaries.
  ///
  /// These single-word patterns are checked separately with stricter
  /// position constraints to avoid false positives like "high school".
  static final _highAlone = RegExp(
    r'(?:^|\s)high(?:\s*$|\s+(?:prio))',
    caseSensitive: false,
  );
  static final _lowAlone = RegExp(
    r'(?:^|\s)low(?:\s*$|\s+(?:prio))',
    caseSensitive: false,
  );

  /// Parses [rawText] and returns a [ParsedTaskInput] with extracted fields.
  ///
  /// Empty or whitespace-only input returns a [ParsedTaskInput] with empty
  /// [rawText] (trimmed) and [extractedTitle].
  ParsedTaskInput parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return ParsedTaskInput(
        rawText: rawText,
        extractedTitle: rawText.trim(),
      );
    }

    var workingText = rawText.trim();

    // 1. Priority extraction (deterministic)
    final priority = _extractPriority(workingText);
    if (priority != null) {
      workingText = _stripPriorityTokens(workingText);
    }

    // 2. Date extraction via chrono_dart
    DateTime? deadline;
    try {
      final dateResults = Chrono.parse(workingText);
      if (dateResults.isNotEmpty) {
        deadline = dateResults.first.date();
        workingText = _stripDateTokens(workingText, dateResults);
      }
    } catch (_) {
      // chrono_dart may throw on unusual input -- degrade gracefully
    }

    // 3. Category keyword extraction (do NOT strip from title)
    final category = _extractCategory(workingText);

    // 4. Clean up title
    final title = _cleanTitle(workingText);

    return ParsedTaskInput(
      rawText: rawText,
      extractedTitle: title.isNotEmpty ? title : rawText.trim(),
      suggestedDeadline: deadline,
      suggestedPriority: priority,
      suggestedCategory: category,
    );
  }

  /// Extracts a priority level (P1-P4) from [text] using regex matching.
  ///
  /// Returns the first matching priority level, checked in order from
  /// P1 (highest) to P4 (lowest). Returns null if no priority keywords found.
  String? _extractPriority(String text) {
    for (final entry in _priorityPatterns.entries) {
      if (entry.value.hasMatch(text)) return entry.key;
    }

    // Check standalone "high" / "low" with stricter matching
    if (_highAlone.hasMatch(text)) return 'P2';
    if (_lowAlone.hasMatch(text)) return 'P4';

    return null;
  }

  /// Strips all priority keyword tokens from [text].
  ///
  /// Removes matches for all priority levels and cleans up resulting
  /// extra whitespace and leading/trailing punctuation.
  String _stripPriorityTokens(String text) {
    var result = text;
    for (final pattern in _priorityPatterns.values) {
      result = result.replaceAll(pattern, '').trim();
    }
    // Also strip standalone high/low
    result = result.replaceAll(_highAlone, ' ').trim();
    result = result.replaceAll(_lowAlone, ' ').trim();
    return result.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  /// Strips date tokens identified by chrono_dart from [text].
  ///
  /// Removes matched text spans in reverse order to preserve character
  /// indices for earlier matches. Also strips common prepositions left
  /// behind (e.g., "by" before a date).
  String _stripDateTokens(String text, List<dynamic> dateResults) {
    var cleaned = text;
    // Remove in reverse order to preserve indices
    for (final result in dateResults.reversed) {
      final int startIndex = result.index as int;
      final String matchText = result.text as String;
      final int endIndex = startIndex + matchText.length;

      // Also remove preceding prepositions like "by", "on", "before"
      var actualStart = startIndex;
      if (actualStart > 0) {
        final prefix = cleaned.substring(0, actualStart).trimRight();
        final prepositions = ['by', 'on', 'before', 'until', 'due'];
        for (final prep in prepositions) {
          if (prefix.toLowerCase().endsWith(prep)) {
            actualStart = prefix.length - prep.length;
            break;
          }
        }
      }

      cleaned = cleaned.replaceRange(actualStart, endIndex, '');
    }
    return cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  /// Extracts the best-matching category from [text] using keyword matching.
  ///
  /// Counts keyword matches for each category and returns the category
  /// with the highest score. Returns null if no keywords match.
  SmartInputCategory? _extractCategory(String text) {
    final lowerText = text.toLowerCase();
    SmartInputCategory? bestMatch;
    int bestScore = 0;

    for (final entry in SmartInputCategory.categoryKeywords.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          score++;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestMatch = entry.key;
      }
    }

    return bestMatch;
  }

  /// Cleans up the remaining title text after token extraction.
  ///
  /// Removes leading/trailing punctuation, colons, dashes, and
  /// extra whitespace.
  String _cleanTitle(String text) {
    return text
        .replaceAll(RegExp(r'^[\s:,\-]+'), '')
        .replaceAll(RegExp(r'[\s:,\-]+$'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}
