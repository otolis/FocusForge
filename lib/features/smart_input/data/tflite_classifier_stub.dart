import '../domain/classification_result.dart';

/// Web stub for TfliteClassifierService.
///
/// On web, dart:ffi is unavailable so tflite_flutter cannot be used.
/// This stub provides the same API but always returns empty results.
/// The regex-based NLP parser continues to work on all platforms.
class TfliteClassifierService {
  bool get isLoaded => false;

  Future<void> loadModel() async {
    // No-op on web -- TFLite not supported
  }

  List<double> tokenize(String text) {
    return List<double>.filled(128, 0);
  }

  ClassificationResult classify(String text) {
    return ClassificationResult.empty;
  }

  void dispose() {
    // No-op on web
  }
}
