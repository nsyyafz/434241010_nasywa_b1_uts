class Ticket {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String category;
  final String date;
  final String assignee;
  final String? userId;
  final List<Comment> comments;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.date,
    required this.assignee,
    this.userId,
    this.comments = const [],
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'medium',
      category: json['category'] ?? '',
      date: json['created_at'] != null
          ? json['created_at'].toString().substring(0, 10)
          : '',
      assignee: json['assigned_to']?.toString() ?? 'Helpdesk IT',
      userId: json['user_id']?.toString(),
      comments: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'category': category,
      'user_id': userId,
    };
  }
}

class Comment {
  final String id;
  final String author;
  final String message;
  final String time;
  final bool isHelpdesk;
  final String? userId;

  Comment({
    this.id = '',
    required this.author,
    required this.message,
    required this.time,
    required this.isHelpdesk,
    this.userId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      author: json['users']?['full_name'] ?? 'User',
      message: json['message'] ?? '',
      time: json['created_at'] != null
          ? json['created_at'].toString().substring(11, 16)
          : '',
      isHelpdesk: json['users']?['role'] == 'helpdesk' ||
          json['users']?['role'] == 'admin',
      userId: json['user_id']?.toString(),
    );
  }
}