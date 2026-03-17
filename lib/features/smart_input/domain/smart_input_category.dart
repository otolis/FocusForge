/// Generic task categories for smart input classification.
///
/// These categories represent common productivity groupings used by the
/// NLP parser and TFLite classifier to suggest a category for new tasks.
/// Phase 8 maps these to user-created categories at integration time.
enum SmartInputCategory {
  work,
  personal,
  health,
  shopping,
  finance,
  education,
  errands,
  social;

  /// Returns the category name with the first letter capitalized.
  String get displayName => name[0].toUpperCase() + name.substring(1);

  /// Maps each category to a list of keywords for deterministic matching.
  ///
  /// The NLP parser checks input text against these keywords to suggest
  /// a category. Keywords are matched case-insensitively.
  static const Map<SmartInputCategory, List<String>> categoryKeywords = {
    work: [
      'work',
      'meeting',
      'presentation',
      'report',
      'project',
      'deadline',
      'office',
      'client',
      'email',
      'conference',
    ],
    personal: [
      'personal',
      'home',
      'family',
      'friend',
      'birthday',
      'gift',
      'party',
      'vacation',
      'travel',
    ],
    health: [
      'health',
      'doctor',
      'gym',
      'exercise',
      'workout',
      'medicine',
      'appointment',
      'dentist',
      'run',
      'yoga',
      'diet',
    ],
    shopping: [
      'buy',
      'shop',
      'groceries',
      'store',
      'order',
      'purchase',
      'market',
      'pick up',
      'amazon',
    ],
    finance: [
      'pay',
      'bill',
      'bank',
      'tax',
      'invoice',
      'budget',
      'transfer',
      'insurance',
      'rent',
      'mortgage',
    ],
    education: [
      'study',
      'learn',
      'course',
      'class',
      'homework',
      'exam',
      'read',
      'tutorial',
      'lecture',
      'research',
    ],
    errands: [
      'errand',
      'fix',
      'repair',
      'clean',
      'laundry',
      'wash',
      'mow',
      'organize',
      'return',
      'drop off',
      'pick up',
    ],
    social: [
      'call',
      'text',
      'dinner',
      'lunch',
      'coffee',
      'meet',
      'hangout',
      'invite',
      'catch up',
    ],
  };
}
