import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  final _supabase = Supabase.instance.client;

  Future<void> send({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? ticketId,
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'ticket_id': ticketId,
    });
  }

  /// Dipakai di _laporKeAdmin — kirim ke semua admin sekaligus
  Future<void> sendToAllAdmins({
    required String title,
    required String message,
    required String type,
    String? ticketId,
  }) async {
    final admins = await _supabase.from('users').select('id').eq('role', 'admin');
    for (final admin in admins) {
      await send(
        userId: admin['id'],
        title: title,
        message: message,
        type: type,
        ticketId: ticketId,
      );
    }
  }
}