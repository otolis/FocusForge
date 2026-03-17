import 'package:flutter_test/flutter_test.dart';

import 'package:focusforge/features/smart_input/data/tflite_classifier_service.dart';
import 'package:focusforge/features/smart_input/domain/classification_result.dart';

void main() {
  group('TfliteClassifierService', () {
    late TfliteClassifierService service;

    setUp(() {
      service = TfliteClassifierService();
    });

    group('initial state', () {
      test('isLoaded is false by default', () {
        expect(service.isLoaded, isFalse);
      });

      test('classify returns empty when model is not loaded', () {
        final result = service.classify('buy groceries for the week');
        expect(result.topCategory, isEmpty);
        expect(result.topConfidence, equals(0.0));
        expect(result.allPredictions, isEmpty);
      });

      test('classify returns empty for empty text', () {
        final result = service.classify('');
        expect(result.topCategory, isEmpty);
        expect(result.topConfidence, equals(0.0));
        expect(result.allPredictions, isEmpty);
      });

      test('classify returns empty for whitespace-only text', () {
        final result = service.classify('   ');
        expect(result.topCategory, isEmpty);
        expect(result.topConfidence, equals(0.0));
        expect(result.allPredictions, isEmpty);
      });
    });

    group('tokenization', () {
      setUp(() {
        service.initializeForTesting(
          vocab: {
            '<PAD>': 0,
            '<UNK>': 1,
            'buy': 14,
            'groceries': 49,
            'the': 2,
            'for': 6,
            'week': 178,
            'hello': 50,
            'world': 51,
          },
          labels: ['work', 'personal', 'health', 'shopping'],
        );
      });

      test('tokenizes known words to their vocab indices', () {
        final tokens = service.tokenize('buy groceries');
        expect(tokens[0], equals(14.0)); // 'buy' -> 14
        expect(tokens[1], equals(49.0)); // 'groceries' -> 49
      });

      test('tokenizes unknown words to index 1 (UNK)', () {
        final tokens = service.tokenize('xylophone');
        expect(tokens[0], equals(1.0)); // unknown -> 1
      });

      test('returns padded array of length 128', () {
        final tokens = service.tokenize('buy');
        expect(tokens.length, equals(128));
        // First element is the word, rest should be 0 (PAD)
        expect(tokens[0], equals(14.0)); // 'buy'
        expect(tokens[1], equals(0.0)); // PAD
        expect(tokens[127], equals(0.0)); // PAD
      });

      test('handles empty string input', () {
        final tokens = service.tokenize('');
        expect(tokens.length, equals(128));
        // All should be PAD (0)
        expect(tokens.every((t) => t == 0.0), isTrue);
      });

      test('strips non-alphabetic characters before tokenizing', () {
        final tokens = service.tokenize('buy! groceries... 123');
        expect(tokens[0], equals(14.0)); // 'buy' (! stripped)
        expect(tokens[1], equals(49.0)); // 'groceries' (... stripped)
        // '123' becomes '' after stripping non-alpha, so next meaningful
        // token position depends on split behavior
      });

      test('converts text to lowercase before tokenizing', () {
        final tokens = service.tokenize('BUY GROCERIES');
        expect(tokens[0], equals(14.0)); // 'buy' -> 14
        expect(tokens[1], equals(49.0)); // 'groceries' -> 49
      });

      test('handles text longer than max sentence length', () {
        // Create text with 200 words (more than maxSentenceLen = 128)
        final longText = List.generate(200, (i) => 'buy').join(' ');
        final tokens = service.tokenize(longText);
        expect(tokens.length, equals(128));
        // All 128 positions should have the 'buy' index
        for (var i = 0; i < 128; i++) {
          expect(tokens[i], equals(14.0));
        }
      });
    });

    group('ClassificationResult', () {
      test('empty constant has zero confidence', () {
        expect(ClassificationResult.empty.topConfidence, equals(0.0));
        expect(ClassificationResult.empty.topCategory, isEmpty);
        expect(ClassificationResult.empty.allPredictions, isEmpty);
      });

      test('isConfident returns false below threshold', () {
        const result = ClassificationResult(
          topCategory: 'work',
          topConfidence: 0.3,
          allPredictions: {'work': 0.3, 'personal': 0.2},
        );
        expect(result.isConfident(), isFalse);
      });

      test('isConfident returns true at default threshold', () {
        const result = ClassificationResult(
          topCategory: 'work',
          topConfidence: 0.4,
          allPredictions: {'work': 0.4, 'personal': 0.2},
        );
        expect(result.isConfident(), isTrue);
      });

      test('isConfident returns true above threshold', () {
        const result = ClassificationResult(
          topCategory: 'work',
          topConfidence: 0.85,
          allPredictions: {'work': 0.85, 'personal': 0.1},
        );
        expect(result.isConfident(), isTrue);
      });

      test('isConfident uses custom threshold when provided', () {
        const result = ClassificationResult(
          topCategory: 'work',
          topConfidence: 0.6,
          allPredictions: {'work': 0.6, 'personal': 0.2},
        );
        expect(result.isConfident(threshold: 0.7), isFalse);
        expect(result.isConfident(threshold: 0.5), isTrue);
      });

      test('toString includes category and percentage', () {
        const result = ClassificationResult(
          topCategory: 'shopping',
          topConfidence: 0.85,
          allPredictions: {'shopping': 0.85},
        );
        expect(result.toString(), contains('shopping'));
        expect(result.toString(), contains('85.0%'));
      });

      test('priorityConfidence defaults to zero', () {
        const result = ClassificationResult(
          topCategory: 'work',
          topConfidence: 0.5,
          allPredictions: {'work': 0.5},
        );
        expect(result.priorityConfidence, equals(0.0));
        expect(result.suggestedPriority, isNull);
      });
    });

    group('dispose', () {
      test('sets isLoaded to false after dispose', () {
        // isLoaded starts as false, but dispose should ensure it stays false
        // and not crash when called on an unloaded service
        service.dispose();
        expect(service.isLoaded, isFalse);
      });

      test('classify returns empty after dispose', () {
        service.dispose();
        final result = service.classify('buy groceries');
        expect(result.topCategory, isEmpty);
        expect(result.topConfidence, equals(0.0));
      });
    });
  });
}
