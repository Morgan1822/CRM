class TaskModel {
  final String id;
  final String title;
  final String type; // call, email, meeting, todo
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;
  final String? contactId;
  final String? contactName;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.type = 'todo',
    this.description,
    this.dueDate,
    this.isCompleted = false,
    this.contactId,
    this.contactName,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Task',
      type: json['type'] as String? ?? 'todo',
      description: json['description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      contactId: json['contact_id'] as String?,
      contactName: json['contact'] != null
          ? '${json['contact']['first_name'] ?? ''} ${json['contact']['last_name'] ?? ''}'.trim()
          : null,
      assignedTo: json['assigned_to'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'title': title,
      'type': type,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'is_completed': isCompleted,
      'contact_id': contactId,
      'assigned_to': assignedTo,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? type,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    String? contactId,
    String? contactName,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
