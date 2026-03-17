# Phase 3: Smart Task Input - Research

**Researched:** 2026-03-18
**Domain:** Natural Language Parsing + On-Device ML Text Classification (Flutter/Dart)
**Confidence:** MEDIUM

## Summary

Phase 3 adds intelligent task creation assistance through two distinct capabilities: (1) a regex/heuristic-based natural language parser that extracts deadline, priority, and category from free-form text input, and (2) an on-device TFLite model that suggests category and priority classifications for new tasks. These are built as standalone services within a `smart_input` feature module, independent of Phase 2's task CRUD. Phase 8 later wires these services into the task creation flow.

The NLP parsing layer is best built with a combination of Dart's built-in `RegExp` for priority/category keyword extraction and the `chrono_dart` package for natural language date parsing (handling "tomorrow", "next Friday", "in 3 days", etc.). The TFLite classification layer uses `tflite_flutter` (v0.12.1) for on-device inference with a custom-trained average word embedding model. Because no pre-trained task-category TFLite model exists, a small training dataset must be created and a model trained using TensorFlow Lite Model Maker (Python script, run once, output `.tflite` file shipped as an asset).

**Primary recommendation:** Build a two-tier parsing pipeline -- regex+chrono_dart for deterministic extraction (HIGH accuracy), TFLite for probabilistic category/priority suggestions (MEDIUM accuracy). Present all results as editable suggestions the user can accept or override.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| TASK-02 | User can input tasks with natural language text that auto-parses deadline, priority, and category via regex+NLP heuristics | Regex patterns for priority keywords, chrono_dart for date/time extraction, keyword matching for categories. Parser service returns structured `ParsedTaskInput` with extracted fields. |
| TASK-06 | Tasks are auto-classified by on-device TFLite model for category and priority suggestions | `tflite_flutter` v0.12.1 for inference, custom average word embedding model trained via TF Lite Model Maker, vocabulary-based tokenization. Classifier service returns category and priority probabilities. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| tflite_flutter | ^0.12.1 | On-device TFLite model inference | Official TensorFlow-managed Flutter plugin, uses dart:ffi for low-latency C API bindings, supports Android/iOS/desktop |
| chrono_dart | ^2.0.2 | Natural language date/time parsing | Port of the battle-tested chrono.js library, handles "tomorrow", "next week", "in 3 days", relative dates, ISO dates |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_riverpod | ^3.3.1 | State management for parser/classifier services | Already in project -- use for exposing parsing results as providers |
| path_provider | (check latest) | Access app directory for model file storage | Only if model needs to be downloaded rather than bundled as asset |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| chrono_dart | Hand-rolled regex for dates | chrono_dart handles edge cases (relative dates, ranges, time zones) that custom regex would miss; significantly less code |
| tflite_flutter | google_mlkit (ML Kit) | ML Kit has no text classification API for Flutter; only vision/NLP entity extraction |
| tflite_flutter | Server-side classification via Groq | Adds latency, requires internet, costs API calls; on-device is instant and free |
| Average word embedding model | MobileBERT model | MobileBERT is 25MB+ vs ~1MB for avg word vec; overkill for simple category classification |

**Installation:**
```bash
flutter pub add tflite_flutter chrono_dart
```

**Version verification:**
- tflite_flutter: v0.12.1 published 2025-10-28 (verified via pub.dev)
- chrono_dart: v2.0.2 published 2024-08-13 (verified via pub.dev)

## Architecture Patterns

### Recommended Project Structure
```
lib/features/smart_input/
  data/
    nlp_parser_service.dart        # Regex + chrono_dart parsing logic
    tflite_classifier_service.dart  # TFLite model loading + inference
  domain/
    parsed_task_input.dart          # Model: extracted fields from NL text
    classification_result.dart      # Model: category/priority probabilities
    smart_input_service.dart        # Orchestrator combining parser + classifier
  presentation/
    providers/
      smart_input_provider.dart     # Riverpod providers for parsing state
    widgets/
      smart_input_field.dart        # TextField with real-time parsing feedback
      suggestion_chips.dart         # Editable suggestion chips for extracted fields
    screens/
      smart_input_demo_screen.dart  # Standalone screen to test/demo the feature
assets/
  ml/
    task_classifier.tflite          # Trained TFLite model (~1MB)
    task_classifier_vocab.txt       # Vocabulary dictionary for tokenization
    task_classifier_labels.txt      # Category label mapping
tools/
  train_classifier/
    train_model.py                  # Python script to train the TFLite model
    training_data.csv               # Labeled task text dataset
    requirements.txt                # Python dependencies (tflite-model-maker)
```

### Pattern 1: Two-Tier Parsing Pipeline
**What:** Separate deterministic parsing (regex/chrono) from probabilistic classification (TFLite). Run both in parallel on the same input text. Merge results into a single `ParsedTaskInput`.
**When to use:** Always -- this is the core architecture.
**Example:**
```dart
// domain/parsed_task_input.dart
class ParsedTaskInput {
  final String rawText;
  final String extractedTitle;       // Text with parsed tokens removed
  final DateTime? suggestedDeadline; // From chrono_dart
  final String? suggestedPriority;   // From regex ("high", "low", etc.)
  final String? suggestedCategory;   // From TFLite or keyword match
  final double categoryConfidence;   // 0.0-1.0 from TFLite
  final double priorityConfidence;   // 0.0-1.0 from TFLite

  const ParsedTaskInput({
    required this.rawText,
    required this.extractedTitle,
    this.suggestedDeadline,
    this.suggestedPriority,
    this.suggestedCategory,
    this.categoryConfidence = 0.0,
    this.priorityConfidence = 0.0,
  });
}
```

### Pattern 2: Regex Priority Extraction
**What:** Use RegExp to match priority keywords in task text, then strip them from the title.
**When to use:** Before TFLite classification -- deterministic extraction takes precedence.
**Example:**
```dart
// data/nlp_parser_service.dart
class NlpParserService {
  static final _priorityPatterns = {
    'P1': RegExp(
      r'\b(urgent|critical|asap|p1|priority\s*1|highest\s*priority|!!!)\b',
      caseSensitive: false,
    ),
    'P2': RegExp(
      r'\b(high\s*priority|important|p2|priority\s*2|high)\b',
      caseSensitive: false,
    ),
    'P3': RegExp(
      r'\b(medium\s*priority|normal|p3|priority\s*3|medium)\b',
      caseSensitive: false,
    ),
    'P4': RegExp(
      r'\b(low\s*priority|whenever|no\s*rush|p4|priority\s*4|low)\b',
      caseSensitive: false,
    ),
  };

  String? extractPriority(String text) {
    for (final entry in _priorityPatterns.entries) {
      if (entry.value.hasMatch(text)) return entry.key;
    }
    return null;
  }

  String stripPriorityTokens(String text) {
    var result = text;
    for (final pattern in _priorityPatterns.values) {
      result = result.replaceAll(pattern, '').trim();
    }
    return result.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }
}
```

### Pattern 3: chrono_dart Date Extraction
**What:** Use chrono_dart to find and extract date/time references from natural language.
**When to use:** After priority extraction, on the remaining text.
**Example:**
```dart
import 'package:chrono_dart/chrono_dart.dart' show Chrono;

DateTime? extractDeadline(String text) {
  final results = Chrono.parse(text);
  if (results.isEmpty) return null;
  return results.first.date();
}

String stripDateTokens(String text) {
  final results = Chrono.parse(text);
  if (results.isEmpty) return text;
  // Remove the matched date text from the input
  var cleaned = text;
  for (final result in results.reversed) {
    cleaned = cleaned.replaceRange(
      result.index,
      result.index + result.text.length,
      '',
    );
  }
  return cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}
```

### Pattern 4: TFLite Classifier Service
**What:** Load a TFLite model on app start, run inference on task text to suggest category and priority.
**When to use:** After regex parsing, to provide ML-based suggestions for fields regex did not extract.
**Example:**
```dart
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteClassifierService {
  static const _modelFile = 'assets/ml/task_classifier.tflite';
  static const _vocabFile = 'assets/ml/task_classifier_vocab.txt';
  static const _labelsFile = 'assets/ml/task_classifier_labels.txt';
  static const int _maxSentenceLen = 128;

  late Interpreter _interpreter;
  late Map<String, int> _vocab;
  late List<String> _labels;
  bool _isLoaded = false;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(_modelFile);
    final vocabStr = await rootBundle.loadString(_vocabFile);
    _vocab = {};
    for (final line in vocabStr.split('\n')) {
      final parts = line.trim().split(' ');
      if (parts.length == 2) _vocab[parts[0]] = int.parse(parts[1]);
    }
    final labelsStr = await rootBundle.loadString(_labelsFile);
    _labels = labelsStr.split('\n').where((l) => l.trim().isNotEmpty).toList();
    _isLoaded = true;
  }

  List<double> _tokenize(String text) {
    final tokens = List<double>.filled(_maxSentenceLen, 0); // PAD = 0
    final words = text.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), '').split(' ');
    for (var i = 0; i < words.length && i < _maxSentenceLen; i++) {
      tokens[i] = (_vocab[words[i]] ?? 1).toDouble(); // 1 = UNKNOWN
    }
    return tokens;
  }

  Map<String, double> classify(String text) {
    if (!_isLoaded) return {};
    final input = [_tokenize(text)];
    final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
    _interpreter.run(input, output);
    return Map.fromIterables(_labels, (output[0] as List).cast<double>());
  }

  void dispose() {
    if (_isLoaded) _interpreter.close();
  }
}
```

### Anti-Patterns to Avoid
- **Running TFLite on the main isolate for large models:** Keep inference fast (<50ms) by using the lightweight average word embedding model. If latency becomes an issue, move to a background isolate.
- **Parsing on every keystroke:** Debounce the parsing to ~300ms after the user stops typing. Do NOT parse on every character.
- **Treating ML suggestions as ground truth:** Always present TFLite results as suggestions with confidence scores. Low-confidence results (<0.4) should not be auto-applied.
- **Blocking task creation on model loading:** Model loading is async. If the model is not yet loaded, the regex parser still works. TFLite suggestions appear when ready.
- **Coupling smart input directly to task CRUD:** Phase 3 is a standalone feature. Do NOT import from `features/tasks/`. Phase 8 handles integration.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Natural language date parsing | Custom regex for "tomorrow", "next week", relative dates | chrono_dart | Handles 20+ date formats, relative dates, ranges, time zones. Custom regex would be fragile and miss edge cases like "2 weeks from now" or "this Friday at 3pm" |
| TFLite model loading + inference | Platform channel bridge to native TFLite | tflite_flutter | Direct dart:ffi binding to C API, no platform-specific code needed, GPU delegate support |
| Text tokenization for ML | Custom byte-pair encoding or subword tokenizer | Simple word-level vocab lookup | Average word embedding models use simple word-to-index mapping. No need for BPE/sentencepiece for this use case |
| Model training pipeline | Custom PyTorch/Keras training loop | TF Lite Model Maker | One-liner training from CSV, automatic export to .tflite with embedded vocab/labels metadata |

**Key insight:** The NLP parsing is deceptively simple -- "just regex" -- but natural language dates have enormous variation. chrono_dart handles the long tail of formats. The TFLite pipeline has a fixed pattern (load vocab, tokenize, run interpreter, read output) that tflite_flutter handles cleanly.

## Common Pitfalls

### Pitfall 1: Forgetting aaptOptions for TFLite on Android
**What goes wrong:** The TFLite model file gets compressed by AAPT during build, causing model loading to fail at runtime with cryptic errors.
**Why it happens:** Android's build system compresses assets by default. TFLite requires uncompressed model files for memory-mapped loading.
**How to avoid:** Add to `android/app/build.gradle`:
```groovy
android {
    aaptOptions {
        noCompress 'tflite'
    }
}
```
**Warning signs:** "Failed to load model" or "Invalid flatbuffer" errors at runtime.

### Pitfall 2: Model/Vocab Version Mismatch
**What goes wrong:** The vocabulary file does not match the trained model, causing garbage classification results.
**Why it happens:** The model and vocab are trained together by Model Maker. If you update one without the other, the token-to-index mapping is wrong.
**How to avoid:** Always update `task_classifier.tflite`, `task_classifier_vocab.txt`, and `task_classifier_labels.txt` together as a set. Version them as a group.
**Warning signs:** Classification confidence scores are always uniformly distributed (~0.1 for each category).

### Pitfall 3: Regex Priority Extraction Conflicts with Common Words
**What goes wrong:** Words like "high" in "high school homework" get matched as priority keywords, incorrectly classifying the task as high priority.
**Why it happens:** Naive keyword matching without context.
**How to avoid:** Use word boundary anchors (`\b`) in regex patterns. Prefer multi-word patterns ("high priority") over single words ("high") where possible. For single-word patterns like "urgent", they are less ambiguous. Consider only matching single priority words when they appear at the start/end of the sentence or after prepositions.
**Warning signs:** Users report incorrect priority assignments on normal sentences.

### Pitfall 4: chrono_dart Parsing Ambiguous Dates
**What goes wrong:** "Buy groceries Friday" on a Saturday could mean "last Friday" or "next Friday".
**Why it happens:** chrono_dart defaults to future dates for ambiguous references, but edge cases exist.
**How to avoid:** Always use `Chrono.parse()` with `referenceDate: DateTime.now()` to anchor relative dates. Display the parsed date explicitly so users can verify and correct.
**Warning signs:** Dates that are unexpectedly in the past.

### Pitfall 5: TFLite Model Not Loading on First Run
**What goes wrong:** The classifier returns empty results because the model is still loading asynchronously when the user starts typing.
**Why it happens:** `Interpreter.fromAsset()` is async and takes 100-500ms on first load.
**How to avoid:** Initialize the classifier eagerly (in the provider's initialization or app startup). Show regex-only results immediately, then update with TFLite suggestions when ready. Use a `_isLoaded` flag.
**Warning signs:** First task always has no category suggestion, but subsequent ones work fine.

### Pitfall 6: Training Data Too Small or Biased
**What goes wrong:** The TFLite model only recognizes exact phrases from training data and fails on novel inputs.
**Why it happens:** Average word embedding models need ~200+ examples per category to generalize. With <50 examples, the model memorizes rather than learns patterns.
**How to avoid:** Create at least 200 examples per category (can be synthetic/generated). Balance categories evenly. Include varied phrasing for each category.
**Warning signs:** High accuracy on training data but poor accuracy on real user input.

## Code Examples

### Complete NLP Parser Service
```dart
// Source: Custom implementation following chrono_dart API + Dart RegExp
import 'package:chrono_dart/chrono_dart.dart' show Chrono;

class NlpParserService {
  /// Parses natural language task text into structured components.
  ///
  /// Processing order:
  /// 1. Extract priority keywords (deterministic)
  /// 2. Extract date/time references (chrono_dart)
  /// 3. Extract category keywords (deterministic)
  /// 4. Remaining text becomes the task title
  ParsedTaskInput parse(String rawText) {
    var workingText = rawText.trim();

    // 1. Priority extraction
    final priority = _extractPriority(workingText);
    if (priority != null) {
      workingText = _stripPriorityTokens(workingText);
    }

    // 2. Date extraction via chrono_dart
    final dateResults = Chrono.parse(workingText);
    DateTime? deadline;
    if (dateResults.isNotEmpty) {
      deadline = dateResults.first.date();
      workingText = _stripDateTokens(workingText, dateResults);
    }

    // 3. Category keyword extraction
    final category = _extractCategory(workingText);
    if (category != null) {
      workingText = _stripCategoryTokens(workingText);
    }

    // 4. Clean up remaining title
    final title = _cleanTitle(workingText);

    return ParsedTaskInput(
      rawText: rawText,
      extractedTitle: title.isNotEmpty ? title : rawText,
      suggestedDeadline: deadline,
      suggestedPriority: priority,
      suggestedCategory: category,
    );
  }

  // ... private methods as shown in Architecture Patterns above
}
```

### Riverpod Provider for Smart Input
```dart
// Source: Following project's established Riverpod patterns
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nlpParserProvider = Provider<NlpParserService>(
  (ref) => NlpParserService(),
);

final tfliteClassifierProvider = Provider<TfliteClassifierService>(
  (ref) {
    final service = TfliteClassifierService();
    ref.onDispose(() => service.dispose());
    return service;
  },
);

/// Combines regex parsing + TFLite classification for a given input.
final smartInputProvider = FutureProvider.family<ParsedTaskInput, String>(
  (ref, inputText) async {
    if (inputText.trim().isEmpty) {
      return ParsedTaskInput(rawText: '', extractedTitle: '');
    }

    final parser = ref.read(nlpParserProvider);
    final classifier = ref.read(tfliteClassifierProvider);

    // Regex parsing is synchronous
    var result = parser.parse(inputText);

    // TFLite classification (may not be loaded yet)
    final predictions = classifier.classify(inputText);
    if (predictions.isNotEmpty) {
      // Find highest-confidence category
      final topCategory = predictions.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      if (topCategory.value > 0.4 && result.suggestedCategory == null) {
        result = result.copyWith(
          suggestedCategory: topCategory.key,
          categoryConfidence: topCategory.value,
        );
      }
    }

    return result;
  },
);
```

### Smart Input Widget (Suggestion Chips)
```dart
// Source: Following Material 3 Chip API + project theme patterns
Widget buildSuggestionChips(ParsedTaskInput parsed) {
  return Wrap(
    spacing: 8,
    children: [
      if (parsed.suggestedDeadline != null)
        ActionChip(
          avatar: const Icon(Icons.calendar_today, size: 16),
          label: Text(DateFormat.yMMMd().format(parsed.suggestedDeadline!)),
          onPressed: () => _editDeadline(parsed.suggestedDeadline!),
        ),
      if (parsed.suggestedPriority != null)
        ActionChip(
          avatar: const Icon(Icons.flag, size: 16),
          label: Text(parsed.suggestedPriority!),
          onPressed: () => _editPriority(parsed.suggestedPriority!),
        ),
      if (parsed.suggestedCategory != null)
        ActionChip(
          avatar: const Icon(Icons.label, size: 16),
          label: Text(parsed.suggestedCategory!),
          onPressed: () => _editCategory(parsed.suggestedCategory!),
        ),
    ],
  );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| tflite_flutter_helper for preprocessing | Direct preprocessing in Dart (helper is deprecated) | 2023 | Must handle tokenization manually -- simple for word-level models |
| tflite (old plugin, platform channels) | tflite_flutter (dart:ffi, official TF-managed) | 2023-08 | 2-3x faster inference, no platform-specific code needed |
| TF Lite Model Maker (Python) | MediaPipe Model Maker (successor) | 2024 | TF Lite Model Maker still works but MediaPipe is the official successor. Either works for training. |
| google_mlkit text classification | N/A -- ML Kit has no text classification | -- | Must use tflite_flutter for on-device text classification |

**Deprecated/outdated:**
- `tflite_flutter_helper` (am15h): Deprecated, not Dart 3 compatible. Do NOT use.
- `tflite` (old plugin): Uses platform channels, slower than tflite_flutter. Superseded.
- `flutter-mediapipe` text plugin: Still in early development, NOT production-ready as of 2026-03. Do NOT depend on it.

## Open Questions

1. **Training data sourcing for TFLite model**
   - What we know: No pre-trained task-category model exists. Must train custom model with TF Lite Model Maker using a CSV of labeled task descriptions.
   - What's unclear: Exact categories to train on. Must align with whatever categories Phase 2 establishes, OR use generic productivity categories (Work, Personal, Health, Shopping, Finance, Education, Errands, Social).
   - Recommendation: Ship with a pre-defined set of 6-8 generic categories. The training script and CSV should be included in the repo under `tools/train_classifier/` so categories can be retrained. Since Phase 2 uses fully user-created categories, the TFLite model suggests from a fixed set and Phase 8 maps these to user categories.

2. **Model size vs accuracy tradeoff**
   - What we know: Average word embedding models are ~1MB and fast. MobileBERT models are ~25MB and more accurate.
   - What's unclear: Whether avg word embedding accuracy is "good enough" for task categorization.
   - Recommendation: Start with average word embedding (small, fast). If accuracy is poor, upgrade to MobileBERT later. For a portfolio project, demonstrating the ML pipeline matters more than perfect accuracy.

3. **chrono_dart maintenance status**
   - What we know: Last published 2024-08-13 (19 months ago). Port of chrono.js which is actively maintained.
   - What's unclear: Whether it works with Dart 3.7 / Flutter 3.29.
   - Recommendation: Test compatibility early. If chrono_dart has issues, fall back to a subset of custom regex patterns for common date formats ("tomorrow", "next [day]", "MM/DD" patterns). The regex fallback is straightforward for the most common cases.

4. **Phase 3 / Phase 2 category alignment**
   - What we know: Phase 2's category system is fully user-created (no defaults). Phase 3's TFLite model needs fixed training categories.
   - What's unclear: How user-created categories map to TFLite predictions at integration time (Phase 8).
   - Recommendation: Phase 3 defines a `SmartInputCategory` enum with generic categories. Phase 8's integration layer maps TFLite category predictions to the user's actual categories via fuzzy string matching or a configurable mapping.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test + mockito (already in project) |
| Config file | None needed -- flutter_test is built-in |
| Quick run command | `flutter test test/unit/smart_input/` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TASK-02 | NLP parser extracts deadline from "Buy groceries tomorrow" | unit | `flutter test test/unit/smart_input/nlp_parser_service_test.dart -x` | Wave 0 |
| TASK-02 | NLP parser extracts priority from "urgent: fix server" | unit | `flutter test test/unit/smart_input/nlp_parser_service_test.dart -x` | Wave 0 |
| TASK-02 | NLP parser extracts category from text with category keywords | unit | `flutter test test/unit/smart_input/nlp_parser_service_test.dart -x` | Wave 0 |
| TASK-02 | Parser strips extracted tokens and returns clean title | unit | `flutter test test/unit/smart_input/nlp_parser_service_test.dart -x` | Wave 0 |
| TASK-06 | TFLite classifier loads model and vocab from assets | unit | `flutter test test/unit/smart_input/tflite_classifier_service_test.dart -x` | Wave 0 |
| TASK-06 | TFLite classifier returns category predictions with confidence | unit | `flutter test test/unit/smart_input/tflite_classifier_service_test.dart -x` | Wave 0 |
| TASK-02/06 | Suggestion chips display parsed deadline, priority, category | widget | `flutter test test/widget/smart_input/suggestion_chips_test.dart -x` | Wave 0 |
| TASK-02/06 | User can tap suggestion chip to edit the value | widget | `flutter test test/widget/smart_input/smart_input_field_test.dart -x` | Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/unit/smart_input/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/unit/smart_input/nlp_parser_service_test.dart` -- covers TASK-02 parsing logic
- [ ] `test/unit/smart_input/tflite_classifier_service_test.dart` -- covers TASK-06 classification (needs mock interpreter)
- [ ] `test/widget/smart_input/suggestion_chips_test.dart` -- covers suggestion UI
- [ ] `test/widget/smart_input/smart_input_field_test.dart` -- covers input field with parsing feedback
- [ ] TFLite model asset files (`task_classifier.tflite`, vocab, labels) -- needed for classifier tests
- [ ] Mock/stub for `Interpreter` class from tflite_flutter -- for unit testing without actual model

## Sources

### Primary (HIGH confidence)
- [pub.dev/packages/tflite_flutter](https://pub.dev/packages/tflite_flutter) - Version 0.12.1, platform support, API surface
- [pub.dev/packages/chrono_dart](https://pub.dev/packages/chrono_dart) - Version 2.0.2, date parsing API, supported formats
- [GitHub am15h/tflite_flutter_plugin - classifier.dart](https://github.com/am15h/tflite_flutter_plugin/blob/master/example/lib/classifier.dart) - Reference implementation for text classification with tflite_flutter
- [Google AI Edge - Text Classification with Model Maker](https://ai.google.dev/edge/litert/libraries/modify/text_classification) - Official training guide

### Secondary (MEDIUM confidence)
- [Google Developers Codelab - Classify texts Flutter](https://developers.google.com/codelabs/classify-texts-flutter-tensorflow-serving) - Flutter + TFLite tokenization workflow
- [GitHub g-30/chrono_dart](https://github.com/g-30/chrono_dart) - chrono_dart feature set, limitations, example usage
- [Google Developers Blog - TFLite Flutter Plugin Official](https://blog.tensorflow.org/2023/08/the-tensorflow-lite-plugin-for-flutter-officially-available.html) - Official migration to TensorFlow org

### Tertiary (LOW confidence)
- [flutter-mediapipe status](https://github.com/google/flutter-mediapipe) - Confirmed NOT production-ready for text classification in Flutter as of 2026-03
- [pub.dev/packages/nlp](https://pub.dev/packages/nlp) - v0.0.0, too immature for production use
- [pub.dev/packages/tflite_text_classification](https://pub.dev/packages/tflite_text_classification) - v0.0.2, last published 2023-05, too stale

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - tflite_flutter is well-established and officially maintained; chrono_dart has not been updated in 19 months but is a port of a mature JS library. Need to verify chrono_dart compatibility with current Dart SDK.
- Architecture: HIGH - Pattern is well-documented by Google's codelabs and the tflite_flutter example app. Regex parsing is straightforward Dart.
- Pitfalls: HIGH - Well-known issues documented across multiple sources (aaptOptions, vocab mismatch, model loading timing).
- TFLite training: MEDIUM - TF Lite Model Maker workflow is documented but may require Python environment setup. No pre-trained task category model exists.

**Research date:** 2026-03-18
**Valid until:** 2026-04-17 (30 days -- stable domain, packages not rapidly changing)
