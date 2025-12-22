import 'package:flutter/foundation.dart';

/// Service for automatically classifying tasks based on content analysis
class TaskClassificationService {
  // Category keywords mapping
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

  // Priority keywords mapping
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

  // Suggested actions mapping
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

  /// Classifies a task based on title and description
  static Map<String, dynamic> classifyTask({
    required String title,
    String? description,
  }) {
    final combinedText =
        '${title.toLowerCase()} ${description?.toLowerCase() ?? ''}';

    // Detect category
    final category = _detectCategory(combinedText);

    // Detect priority
    final priority = _detectPriority(combinedText);

    // Extract entities
    final entities = _extractEntities(title, description);

    // Generate suggested actions
    final actions = _generateSuggestedActions(category, combinedText);

    return {
      'category': category,
      'priority': priority,
      'extracted_entities': entities,
      'suggested_actions': actions,
    };
  }

  /// Detects the category based on keyword matching
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

  /// Detects priority based on urgency indicators
  static String _detectPriority(String text) {
    // Check for high priority keywords
    for (final keyword in _priorityKeywords['high']!) {
      if (text.contains(keyword.toLowerCase())) {
        return 'high';
      }
    }

    // Check for medium priority keywords
    for (final keyword in _priorityKeywords['medium']!) {
      if (text.contains(keyword.toLowerCase())) {
        return 'medium';
      }
    }

    // Default to low priority
    return 'low';
  }

  /// Extracts entities from text (dates, names, locations)
  static Map<String, dynamic> _extractEntities(
    String title,
    String? description,
  ) {
    final entities = <String, dynamic>{};
    final fullText = '$title ${description ?? ''}';

    // Extract dates and times
    final dates = _extractDates(fullText);
    if (dates.isNotEmpty) {
      entities['dates'] = dates;
    }

    // Extract person names (after keywords like "with", "by", "assign to")
    final names = _extractNames(fullText);
    if (names.isNotEmpty) {
      entities['people'] = names;
    }

    // Extract locations
    final locations = _extractLocations(fullText);
    if (locations.isNotEmpty) {
      entities['locations'] = locations;
    }

    // Extract time mentions
    final times = _extractTimes(fullText);
    if (times.isNotEmpty) {
      entities['times'] = times;
    }

    return entities;
  }

  /// Extracts date mentions from text
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

  /// Extracts person names from text
  static List<String> _extractNames(String text) {
    final names = <String>[];
    final namePatterns = [
      RegExp(r'\bwith\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b'),
      RegExp(r'\bby\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b'),
      RegExp(r'\bassign(?:ed)?\s+to\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b'),
      RegExp(r'\bcontact\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b'),
      RegExp(r'\bmeet\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b'),
    ];

    for (final pattern in namePatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        if (match.groupCount > 0 && match.group(1) != null) {
          names.add(match.group(1)!);
        }
      }
    }

    return names.toSet().toList();
  }

  /// Extracts location mentions from text
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

  /// Extracts time mentions from text
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

  /// Generates suggested actions based on category
  static List<String> _generateSuggestedActions(String category, String text) {
    final baseActions =
        _suggestedActions[category] ?? _suggestedActions['general']!;

    // Filter and prioritize actions based on context
    final relevantActions = <String>[];

    for (final action in baseActions) {
      // Add action if it's highly relevant or if we don't have enough actions yet
      if (relevantActions.length < 4) {
        relevantActions.add(action);
      }
    }

    // Add context-specific actions
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

  /// Validates and enhances classification with user overrides
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

  /// Provides confidence score for classification
  static Map<String, dynamic> classifyWithConfidence({
    required String title,
    String? description,
  }) {
    final classification = classifyTask(title: title, description: description);
    final combinedText =
        '${title.toLowerCase()} ${description?.toLowerCase() ?? ''}';

    // Calculate confidence scores
    final categoryConfidence = _calculateCategoryConfidence(
      combinedText,
      classification['category'],
    );
    final priorityConfidence = _calculatePriorityConfidence(
      combinedText,
      classification['priority'],
    );

    return {
      ...classification,
      'confidence': {
        'category': categoryConfidence,
        'priority': priorityConfidence,
      },
    };
  }

  /// Calculates confidence score for category classification
  static double _calculateCategoryConfidence(String text, String category) {
    if (category == 'general') return 0.5;

    final keywords = _categoryKeywords[category] ?? [];
    int matchCount = 0;

    for (final keyword in keywords) {
      if (text.contains(keyword.toLowerCase())) {
        matchCount++;
      }
    }

    return (matchCount / keywords.length).clamp(0.0, 1.0);
  }

  /// Calculates confidence score for priority classification
  static double _calculatePriorityConfidence(String text, String priority) {
    final keywords = _priorityKeywords[priority] ?? [];

    for (final keyword in keywords) {
      if (text.contains(keyword.toLowerCase())) {
        return 0.9;
      }
    }

    return priority == 'low' ? 0.6 : 0.5;
  }
}
