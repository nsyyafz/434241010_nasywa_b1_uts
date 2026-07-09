import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';

class CommentRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Comment>> getComments(String ticketId) async {
    final res = await _supabase
        .from('comments')
        .select('*, users(full_name, role)')
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);
    return (res as List).map((e) => Comment.fromJson(e)).toList();
  }

  Future<void> sendComment({
    required String ticketId,
    required String userId,
    required String message,
  }) async {
    await _supabase.from('comments').insert({
      'ticket_id': ticketId,
      'user_id': userId,
      'message': message,
    });
  }
}