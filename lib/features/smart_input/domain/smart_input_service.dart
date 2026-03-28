import '../data/nlp_parser_service.dart';
import '../data/tflite_classifier.dart';
import 'parsed_task_input.dart';
import 'smart_input_category.dart';

/// Orchestrates the two-tier NLP pipeline: deterministic regex parsing
/// followed by probabilistic TFLite classification.
///
/// The [SmartInputService] merges results from [NlpParserService] (tier 1)
/// and [TfliteClassifierService] (tier 2) into a single [ParsedTaskInput].
///
/// TFLite suggestions only apply when:
/// - The regex parser did NOT already extract that field
/// - The TFLite confidence exceeds 0.4 (40%)
///
/// This ensures deterministic results take precedence over probabilistic
/// ones, and low-confidence ML predictions are not auto-applied.
class SmartInputService {
  final NlpParserService _parser;
  final TfliteClassifierService _classifier;

  SmartInputService({
    required NlpParserService parser,
    required TfliteClassifierService classifier,
  })  : _parser = parser,
        _classifier = classifier;

  /// Parses text using the two-tier pipeline:
  /// 1. Regex + chrono_dart for deterministic extraction (priority, deadline, category keywords)
  /// 2. TFLite model for probabilistic category/priority suggestions (fills gaps only)
  ///
  /// TFLite results only apply when:
  /// - The regex parser did NOT already extract that field
  /// - The TFLite confidence exceeds 0.4 (40%)
  ParsedTaskInput parseInput(String text) {
    if (text.trim().isEmpty) {
      return ParsedTaskInput(rawText: text, extractedTitle: text.trim());
    }

    // Tier 1: Deterministic parsing
    var result = _parser.parse(text);

    // Tier 2: Probabilistic classification (only if model is loaded)
    if (_classifier.isLoaded) {
      final classification = _classifier.classify(text);

      // Only apply TFLite category if regex didn't find one AND confidence > 0.4
      if (result.suggestedCategory == null &&
          classification.isConfident(threshold: 0.4)) {
        final tfliteCategory =
            _mapStringToCategory(classification.topCategory);
        if (tfliteCategory != null) {
          result = result.copyWith(
            suggestedCategory: tfliteCategory,
            categoryConfidence: classification.topConfidence,
          );
        }
      }

      // Only apply TFLite priority if regex didn't find one AND confidence > 0.4
      if (result.suggestedPriority == null &&
          classification.suggestedPriority != null &&
          classification.priorityConfidence >= 0.4) {
        result = result.copyWith(
          suggestedPriority: classification.suggestedPriority,
          priorityConfidence: classification.priorityConfidence,
        );
      }
    }

    return result;
  }

  /// Maps a TFLite label string (e.g., "work") to [SmartInputCategory] enum.
  SmartInputCategory? _mapStringToCategory(String label) {
    final normalized = label.toLowerCase().trim();
    for (final category in SmartInputCategory.values) {
      if (category.name == normalized) return category;
    }
    return null;
  }

  /// Initializes the TFLite model. Call during app startup.
  /// Non-blocking -- regex parsing works without the model.
  Future<void> initialize() async {
    await _classifier.loadModel();
  }

  /// Releases resources held by the classifier.
  void dispose() {
    _classifier.dispose();
  }
}
