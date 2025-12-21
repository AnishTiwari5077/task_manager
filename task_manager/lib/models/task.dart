class Task {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String priority;
  final String status;
  final String? assignedTo;
  final DateTime? dueDate;
  final Map<String, dynamic>? extractedEntities;
  final List<String>? suggestedActions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.dueDate,
    this.extractedEntities,
    this.suggestedActions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      assignedTo: json['assigned_to'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      extractedEntities: json['extracted_entities'] as Map<String, dynamic>?,
      suggestedActions: json['suggested_actions'] != null
          ? List<String>.from(json['suggested_actions'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'assigned_to': assignedTo,
      'due_date': dueDate?.toIso8601String(),
      'extracted_entities': extractedEntities,
      'suggested_actions': suggestedActions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? priority,
    String? status,
    String? assignedTo,
    DateTime? dueDate,
    Map<String, dynamic>? extractedEntities,
    List<String>? suggestedActions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      extractedEntities: extractedEntities ?? this.extractedEntities,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Classification {
  final String category;
  final String priority;
  final Map<String, dynamic> extractedEntities;
  final List<String> suggestedActions;

  Classification({
    required this.category,
    required this.priority,
    required this.extractedEntities,
    required this.suggestedActions,
  });

  factory Classification.fromJson(Map<String, dynamic> json) {
    return Classification(
      category: json['category'] as String,
      priority: json['priority'] as String,
      extractedEntities: json['extracted_entities'] as Map<String, dynamic>,
      suggestedActions: List<String>.from(json['suggested_actions'] as List),
    );
  }
}
