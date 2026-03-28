import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/nlp_parser_service.dart';
import '../../data/tflite_classifier.dart';
import '../../domain/parsed_task_input.dart';
import '../../domain/smart_input_service.dart';

/// Provides the NLP parser service (singleton).
///
/// Stateless service -- no dispose needed.
final nlpParserProvider = Provider<NlpParserService>(
  (ref) => NlpParserService(),
);

/// Provides the TFLite classifier service (singleton, disposed on ref dispose).
///
/// The classifier holds native TFLite resources that must be released.
final tfliteClassifierProvider = Provider<TfliteClassifierService>(
  (ref) {
    final service = TfliteClassifierService();
    ref.onDispose(() => service.dispose());
    return service;
  },
);

/// Provides the combined [SmartInputService] (singleton).
///
/// Orchestrates [NlpParserService] + [TfliteClassifierService] into
/// a single [parseInput] call.
final smartInputServiceProvider = Provider<SmartInputService>(
  (ref) {
    final parser = ref.read(nlpParserProvider);
    final classifier = ref.read(tfliteClassifierProvider);
    final service = SmartInputService(parser: parser, classifier: classifier);
    ref.onDispose(() => service.dispose());
    return service;
  },
);

/// Initializes the TFLite model. Call once during app startup or feature entry.
///
/// On web, TFLite is not supported (FFI bindings unavailable). The provider
/// returns immediately, and the smart input pipeline falls back to regex-only
/// parsing which works without TFLite.
///
/// This is a [FutureProvider] so the UI can show a loading indicator while
/// the model loads. The model loading is non-blocking -- regex parsing
/// works immediately even before this completes.
final smartInputInitProvider = FutureProvider<void>((ref) async {
  if (kIsWeb) return; // TFLite not supported on web; regex parser still works
  final service = ref.read(smartInputServiceProvider);
  await service.initialize();
});

/// Reactive provider that parses input text.
///
/// Use with `ref.watch(smartInputProvider('user text here'))`.
/// Returns a [ParsedTaskInput] with extracted fields.
///
/// This is synchronous because both [NlpParserService.parse] and
/// [TfliteClassifierService.classify] are synchronous. The only async
/// operation is model loading, handled by [smartInputInitProvider].
final smartInputProvider = Provider.family<ParsedTaskInput, String>(
  (ref, inputText) {
    final service = ref.read(smartInputServiceProvider);
    return service.parseInput(inputText);
  },
);
