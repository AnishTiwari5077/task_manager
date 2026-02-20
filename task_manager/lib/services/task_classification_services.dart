class TaskClassificationService {
  static const Map<String, List<String>> _categoryKeywords = {
    'scheduling': [
      'meeting',
      'schedule',
      'call',
      'appointment',
      'deadline',
      'calendar',
      'attend',
      'conference',
      'session',
      'presentation',
      'discuss',
      'sync',
      'standup',
      'review',
      'interview',
    ],
    'finance': [
      'payment',
      'invoice',
      'bill',
      'budget',
      'cost',
      'expense',
      'salary',
      'payroll',
      'reimbursement',
      'purchase',
      'order',
      'quote',
      'estimate',
      'receipt',
      'tax',
      'accounting',
    ],
    'technical': [
      'bug',
      'fix',
      'error',
      'install',
      'repair',
      'maintain',
      'update',
      'deploy',
      'configure',
      'debug',
      'test',
      'develop',
      'code',
      'server',
      'database',
      'api',
      'system',
      'software',
      'hardware',
    ],
    'safety': [
      'safety',
      'hazard',
      'inspection',
      'compliance',
      'ppe',
      'risk',
      'emergency',
      'incident',
      'accident',
      'security',
      'protocol',
      'regulation',
      'audit',
      'training',
      'drill',
    ],
  };

  static const Map<String, List<String>> _priorityKeywords = {
    'high': [
      'urgent',
      'asap',
      'immediately',
      'today',
      'critical',
      'emergency',
      'now',
      'priority',
      'important',
      'crucial',
      'vital',
      'pressing',
    ],
    'medium': [
      'soon',
      'this week',
      'important',
      'needed',
      'necessary',
      'required',
      'tomorrow',
    ],
  };

  static const Map<String, List<String>> _suggestedActions = {
    'scheduling': [
      'Block calendar',
      'Send invite',
      'Prepare agenda',
      'Set reminder',
      'Book meeting room',
      'Notify attendees',
    ],
    'finance': [
      'Check budget',
      'Get approval',
      'Generate invoice',
      'Update records',
      'Process payment',
      'Review expenses',
    ],
    'technical': [
      'Diagnose issue',
      'Check resources',
      'Assign technician',
      'Document fix',
      'Test solution',
      'Deploy update',
    ],
    'safety': [
      'Conduct inspection',
      'File report',
      'Notify supervisor',
      'Update checklist',
      'Schedule training',
      'Review protocols',
    ],
    'general': [
      'Review details',
      'Gather information',
      'Create plan',
      'Follow up',
      'Document progress',
    ],
  };

  /// Words that should never be treated as person names
  static const Set<String> _stopWords = {
    // Articles & pronouns
    'the', 'a', 'an', 'me', 'us', 'him', 'her', 'them', 'they',
    'this', 'that', 'these', 'those', 'my', 'our', 'your', 'its',
    'his', 'their', 'we', 'you', 'it', 'he', 'she',
    // Common task words that follow trigger keywords
    'meeting', 'call', 'review', 'budget', 'report', 'team',
    'today', 'tomorrow', 'monday', 'tuesday', 'wednesday',
    'thursday', 'friday', 'saturday', 'sunday', 'week', 'month',
    'all', 'everyone', 'anybody', 'someone', 'anyone',
    'manager', 'client', 'customer', 'vendor', 'supplier',
    'department', 'office', 'company', 'staff', 'hr',
    // Prepositions / conjunctions that can follow trigger words
    'and', 'or', 'but', 'for', 'on', 'at', 'in', 'of',
  };

  /// Classifies a task based on title and description
  static Map<String, dynamic> classifyTask({
    required String title,
    String? description,
  }) {
    final combinedText =
        '${title.toLowerCase()} ${description?.toLowerCase() ?? ''}';

    final category = _detectCategory(combinedText);
    final priority = _detectPriority(combinedText);

    // Pass original-case text so name extraction can work properly
    final entities = _extractEntities(title, description);
    final actions = _generateSuggestedActions(category, combinedText);

    return {
      'category': category,
      'priority': priority,
      'extracted_entities': entities,
      'suggested_actions': actions,
    };
  }

  static String _detectCategory(String text) {
    int maxScore = 0;
    String detectedCategory = 'general';

    _categoryKeywords.forEach((category, keywords) {
      int score = 0;
      for (final keyword in keywords) {
        if (text.contains(keyword.toLowerCase())) {
          score++;
        }
      }

      if (score > maxScore) {
        maxScore = score;
        detectedCategory = category;
      }
    });

    return detectedCategory;
  }

  static String _detectPriority(String text) {
    for (final keyword in _priorityKeywords['high']!) {
      if (text.contains(keyword.toLowerCase())) {
        return 'high';
      }
    }

    for (final keyword in _priorityKeywords['medium']!) {
      if (text.contains(keyword.toLowerCase())) {
        return 'medium';
      }
    }

    return 'low';
  }

  static Map<String, dynamic> _extractEntities(
    String title,
    String? description,
  ) {
    final entities = <String, dynamic>{};
    final fullText = '$title ${description ?? ''}';

    final dates = _extractDates(fullText);
    if (dates.isNotEmpty) {
      entities['dates'] = dates;
    }

    // FIX: Pass original-case text for name extraction
    final names = _extractNames(fullText);
    if (names.isNotEmpty) {
      entities['people'] = names;
    }

    final locations = _extractLocations(fullText);
    if (locations.isNotEmpty) {
      entities['locations'] = locations;
    }

    final times = _extractTimes(fullText);
    if (times.isNotEmpty) {
      entities['times'] = times;
    }

    return entities;
  }

  static List<String> _extractDates(String text) {
    final dates = <String>[];
    final datePatterns = [
      RegExp(r'\b(today|tomorrow|yesterday)\b', caseSensitive: false),
      RegExp(
        r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
        caseSensitive: false,
      ),
      RegExp(r'\b(this|next|last)\s+(week|month|year)\b', caseSensitive: false),
      RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'),
      RegExp(
        r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,2}\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in datePatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        dates.add(match.group(0)!);
      }
    }

    return dates;
  }

  /// FIX: Extracts person names with case-insensitive matching + stop word filtering
  static List<String> _extractNames(String text) {
    final names = <String>[];

    // FIX: All patterns are now case-insensitive so "with john" and "with John" both match
    final namePatterns = [
      RegExp(r'\bwith\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\b', caseSensitive: false),
      RegExp(r'\bby\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\b', caseSensitive: false),
      RegExp(
        r'\bassign(?:ed)?\s+to\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\bcontact\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\bmeet(?:ing)?\s+with\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\b',
        caseSensitive: false,
      ),
      RegExp(r'\bfor\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\b', caseSensitive: false),
      RegExp(
        r'\bnotify\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\bsend\s+(?:to\s+)?([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\binform\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\b',
        caseSensitive: false,
      ),
      RegExp(r'\bcall\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\b', caseSensitive: false),
    ];

    for (final pattern in namePatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        if (match.groupCount > 0 && match.group(1) != null) {
          final rawName = match.group(1)!.trim();

          // FIX: Skip stop words and overly short strings
          if (_isValidName(rawName)) {
            // FIX: Capitalize properly before storing
            names.add(_capitalizeName(rawName));
          }
        }
      }
    }

    return names.toSet().toList();
  }

  /// Returns true if the extracted string looks like an actual name
  static bool _isValidName(String name) {
    if (name.length < 2) return false;

    final lowerName = name.toLowerCase();

    // Reject if the entire string is a stop word
    if (_stopWords.contains(lowerName)) return false;

    // Reject if the first word is a stop word (e.g. "with the team" → "the team")
    final firstWord = lowerName.split(' ').first;
    if (_stopWords.contains(firstWord)) return false;

    // Reject purely numeric strings
    if (RegExp(r'^\d+$').hasMatch(name)) return false;

    return true;
  }

  /// Capitalizes each word of a name: "john doe" → "John Doe"
  static String _capitalizeName(String name) {
    return name
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static List<String> _extractLocations(String text) {
    final locations = <String>[];
    final locationPatterns = [
      RegExp(r'\bat\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\b'),
      RegExp(
        r'\bin\s+(room\s+\w+|office\s+\w+|building\s+\w+)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(conference\s+room|meeting\s+room|boardroom)\s+\w+\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in locationPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        locations.add(match.group(0)!);
      }
    }

    return locations.toSet().toList();
  }

  static List<String> _extractTimes(String text) {
    final times = <String>[];
    final timePatterns = [
      RegExp(r'\b\d{1,2}:\d{2}\s*(?:am|pm)?\b', caseSensitive: false),
      RegExp(r'\b\d{1,2}\s*(?:am|pm)\b', caseSensitive: false),
      RegExp(r'\b(morning|afternoon|evening|night)\b', caseSensitive: false),
    ];

    for (final pattern in timePatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        times.add(match.group(0)!);
      }
    }

    return times.toSet().toList();
  }

  static List<String> _generateSuggestedActions(String category, String text) {
    final baseActions =
        _suggestedActions[category] ?? _suggestedActions['general']!;

    final relevantActions = <String>[];

    for (final action in baseActions) {
      if (relevantActions.length < 4) {
        relevantActions.add(action);
      }
    }

    if (text.contains('budget') && !relevantActions.contains('Check budget')) {
      relevantActions.insert(0, 'Check budget');
    }
    if (text.contains('team') && !relevantActions.contains('Notify team')) {
      relevantActions.add('Notify team');
    }
    if (text.contains('email') && !relevantActions.contains('Send email')) {
      relevantActions.add('Send email');
    }

    return relevantActions.take(5).toList();
  }

  static Map<String, dynamic> mergeClassification({
    required Map<String, dynamic> autoClassification,
    String? userCategory,
    String? userPriority,
  }) {
    return {
      'category': userCategory ?? autoClassification['category'],
      'priority': userPriority ?? autoClassification['priority'],
      'extracted_entities': autoClassification['extracted_entities'],
      'suggested_actions': autoClassification['suggested_actions'],
    };
  }
}
