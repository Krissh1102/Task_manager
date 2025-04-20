class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final String userId;
  
  Task({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    required this.userId,
  });
  
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      isCompleted: json['is_completed'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'is_completed': isCompleted,
      'user_id': userId,
    };
  }
  
  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}