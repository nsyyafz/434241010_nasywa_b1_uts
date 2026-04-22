class Ticket {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String category;
  final String date;
  final String assignee;
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
    this.comments = const [],
  });
}

class Comment {
  final String author;
  final String message;
  final String time;
  final bool isHelpdesk;

  Comment({
    required this.author,
    required this.message,
    required this.time,
    required this.isHelpdesk,
  });
}