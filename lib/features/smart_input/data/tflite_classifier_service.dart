import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../domain/classification_result.dart';

/// On-device TFLite text classifier for task category prediction.
///
/// Loads a TFLite model from bundled assets and runs inference on task
/// descriptions to suggest categories (work, personal, health, etc.)
/// with confidence scores.
///
/// Usage:
/// ```dart
/// final classifier = TfliteClassifierService();
/// await classifier.loadModel();
/// final result = classifier.classify('buy groceries for the week');
/// print(result.topCategory); // 'shopping'
/// ```
class TfliteClassifierService {
  static const _modelPath = 'assets/ml/task_classifier.tflite';
  static const _vocabPath = 'assets/ml/task_classifier_vocab.txt';
  static const _labelsPath = 'assets/ml/task_classifier_labels.txt';
  static const int _maxSentenceLen = 128;

  Interpreter? _interpreter;
  Map<String, int> _vocab = {};
  List<String> _labels = [];
  bool _isLoaded = false;

  /// Whether the model has been successfully loaded and is ready for inference.
  bool get isLoaded => _isLoaded;

  /// Loads the TFLite model, vocabulary, and labels from bundled assets.
  ///
  /// This is async and should be called early (e.g., at app startup).
  /// If loading fails, the service remains in an unloaded state and
  /// [classify] will return [ClassificationResult.empty].
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);

      // Load vocabulary (word -> index mapping)
      final vocabStr = await rootBundle.loadString(_vocabPath);
      _vocab = {};
      for (final line in vocabStr.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        final parts = trimmed.split(' ');
        if (parts.length == 2) {
          _vocab[parts[0]] = int.parse(parts[1]);
        }
      }

      // Load category labels
      final labelsStr = await rootBundle.loadString(_labelsPath);
      _labels =
          labelsStr.split('\n').where((l) => l.trim().isNotEmpty).toList();

      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      // Model loading failure is non-fatal -- regex parser still works
    }
  }

  /// Tokenizes [text] into a padded list of vocabulary indices.
  ///
  /// Returns a [List<double>] of length [_maxSentenceLen] where each
  /// element is the vocabulary index for the corresponding word.
  /// Unknown words map to index 1 (UNK), and unused positions are
  /// padded with 0 (PAD).
  List<double> tokenize(String text) {
    final tokens = List<double>.filled(_maxSentenceLen, 0); // PAD = 0
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .split(RegExp(r'\s+'));
    for (var i = 0; i < words.length && i < _maxSentenceLen; i++) {
      if (words[i].isEmpty) continue;
      tokens[i] = (_vocab[words[i]] ?? 1).toDouble(); // 1 = UNKNOWN
    }
    return tokens;
  }

  /// Classifies [text] and returns a [ClassificationResult].
  ///
  /// Returns [ClassificationResult.empty] if the model is not loaded
  /// or [text] is empty.
  ClassificationResult classify(String text) {
    if (!_isLoaded || _interpreter == null || text.trim().isEmpty) {
      return ClassificationResult.empty;
    }

    final input = [tokenize(text)];
    final output =
        List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
    _interpreter!.run(input, output);

    final scores = (output[0] as List).cast<double>();
    final predictions = Map.fromIterables(_labels, scores);

    // Find top category
    String topCategory = '';
    double topConfidence = 0.0;
    for (final entry in predictions.entries) {
      if (entry.value > topConfidence) {
        topConfidence = entry.value;
        topCategory = entry.key;
      }
    }

    return ClassificationResult(
      topCategory: topCategory,
      topConfidence: topConfidence,
      allPredictions: predictions,
    );
  }

  /// Releases model resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }

  /// For testing only -- populates vocab and labels without loading a model.
  ///
  /// This allows testing [tokenize] and state behavior without requiring
  /// a real TFLite model file or the tflite_flutter native bindings.
  @visibleForTesting
  void initializeForTesting({
    required Map<String, int> vocab,
    required List<String> labels,
  }) {
    _vocab = vocab;
    _labels = labels;
    // Note: _isLoaded stays false because no interpreter is loaded.
    // tokenize() does not check _isLoaded.
  }
}
