class TaskModel {
  const TaskModel({
    required this.id,
    required this.name,
    this.description,
    this.status = 'open',
    this.priority = 'medium',
    this.scheduledAt,
    this.isOverdue = false,
    this.category,
    this.entity,
    this.assignment,
    this.completedAt,
    this.cancelledAt,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String status;
  final String priority;
  final DateTime? scheduledAt;
  final bool isOverdue;

  final TaskCategory? category;
  final TaskEntity? entity;
  final TaskAssignment? assignment;

  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled task',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'open',
      priority: json['priority']?.toString() ?? 'medium',
      scheduledAt: _parseDate(json['scheduled_at']),
      isOverdue: json['is_overdue'] == true,
      category: json['category'] is Map<String, dynamic>
          ? TaskCategory.fromJson(
              json['category'] as Map<String, dynamic>,
            )
          : null,
      entity: json['entity'] is Map<String, dynamic>
          ? TaskEntity.fromJson(
              json['entity'] as Map<String, dynamic>,
            )
          : null,
      assignment: json['assignment'] is Map<String, dynamic>
          ? TaskAssignment.fromJson(
              json['assignment'] as Map<String, dynamic>,
            )
          : null,
      completedAt: _parseDate(json['completed_at']),
      cancelledAt: _parseDate(json['cancelled_at']),
      comment: json['comment']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }
}

class TaskCategory {
  const TaskCategory({
    required this.id,
    required this.name,
    this.type,
    this.slug,
    this.description,
    this.icon,
    this.color,
  });

  final String id;
  final String name;
  final String? type;
  final String? slug;
  final String? description;
  final String? icon;
  final String? color;

  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    return TaskCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
    );
  }
}

class TaskEntity {
  const TaskEntity({
    this.type,
    this.id,
    this.name,
  });

  final String? type;
  final String? id;
  final String? name;

  factory TaskEntity.fromJson(Map<String, dynamic> json) {
    return TaskEntity(
      type: json['type']?.toString(),
      id: json['id']?.toString(),
      name: json['name']?.toString(),
    );
  }
}

class TaskAssignment {
  const TaskAssignment({
    this.assignedTo,
    this.assignedBy,
    this.assignedAt,
  });

  final TaskUser? assignedTo;
  final TaskUser? assignedBy;
  final DateTime? assignedAt;

  factory TaskAssignment.fromJson(Map<String, dynamic> json) {
    return TaskAssignment(
      assignedTo: json['assigned_to'] is Map<String, dynamic>
          ? TaskUser.fromJson(
              json['assigned_to'] as Map<String, dynamic>,
            )
          : null,
      assignedBy: json['assigned_by'] is Map<String, dynamic>
          ? TaskUser.fromJson(
              json['assigned_by'] as Map<String, dynamic>,
            )
          : null,
      assignedAt: TaskModel._parseDate(json['assigned_at']),
    );
  }
}

class TaskUser {
  const TaskUser({
    this.id,
    this.name,
  });

  final String? id;
  final String? name;

  factory TaskUser.fromJson(Map<String, dynamic> json) {
    return TaskUser(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
    );
  }
}