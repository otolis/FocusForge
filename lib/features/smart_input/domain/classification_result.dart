/// Result of TFLite-based text classification for task categorization.
///
/// Contains the top predicted category, its confidence score, and all
/// category predictions with their respective probabilities.
class ClassificationResult {
  /// Highest confidence category label.
  final String topCategory;

  /// Confidence of top category (0.0-1.0).
  final double topConfidence;

  /// All categories with their prediction scores.
  final Map<String, double> allPredictions;

  /// Optional priority suggestion from priority-specific model head.
  final String? suggestedPriority;

  /// Confidence of priority suggestion (0.0-1.0).
  final double priorityConfidence;

  const ClassificationResult({
    required this.topCategory,
    required this.topConfidence,
    required this.allPredictions,
    this.suggestedPriority,
    this.priorityConfidence = 0.0,
  });

  /// Returns true if the top prediction confidence exceeds the [threshold].
  ///
  /// Default threshold is 0.4 -- below this, the prediction is considered
  /// too uncertain to auto-apply.
  bool isConfident({double threshold = 0.4}) => topConfidence >= threshold;

  /// Empty result used when the model is not loaded or input is empty.
  static const empty = ClassificationResult(
    topCategory: '',
    topConfidence: 0.0,
    allPredictions: {},
  );

  @override
  String toString() =>
      'ClassificationResult($topCategory: ${(topConfidence * 100).toStringAsFixed(1)}%)';
}
