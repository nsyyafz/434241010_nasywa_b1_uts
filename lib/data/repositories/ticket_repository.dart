import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';

class TicketRepository {
  final _supabase = Supabase.instance.client;

  /// Dipakai di dashboard_screen & list_tiket_screen (role: user)
  Future<List<Ticket>> getUserTickets(String userId) async {
    final res = await _supabase
        .from('tickets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => Ticket.fromJson(e)).toList();
  }

  /// Dipakai di dashboard/list helpdesk — tiket yang di-assign ke dia
  Future<List<Ticket>> getAssignedTickets(String helpdeskId) async {
    final res = await _supabase
        .from('tickets')
        .select()
        .eq('assigned_to', helpdeskId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => Ticket.fromJson(e)).toList();
  }

  /// Dipakai di dashboard/list admin — semua tiket
  Future<List<Ticket>> getAllTickets() async {
    final res = await _supabase
        .from('tickets')
        .select()
        .order('created_at', ascending: false);
    return (res as List).map((e) => Ticket.fromJson(e)).toList();
  }

  /// Dipakai di buat_tiket_screen
  Future<void> createTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
    required String userId,
  }) async {
    await _supabase.from('tickets').insert({
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': 'open',
      'user_id': userId,
    });
  }

  /// Dipakai di detail_tiket_admin_screen (assign ke helpdesk)
  Future<void> assignTicket({
    required String ticketId,
    required String helpdeskId,
  }) async {
    await _supabase.from('tickets').update({
      'assigned_to': helpdeskId,
      'status': 'in_progress',
    }).eq('id', ticketId);
  }

  /// Dipakai di detail_tiket_helpdesk_screen (finish)
  Future<void> updateStatus({
    required String ticketId,
    required String status,
  }) async {
    await _supabase.from('tickets').update({'status': status}).eq('id', ticketId);
  }

  /// Dipakai di detail_tiket_admin_screen (delete)
  /// Menghapus comments & notifications terkait dulu (karena ada FK)
  Future<void> deleteTicket(String ticketId) async {
    await _supabase.from('comments').delete().eq('ticket_id', ticketId);
    await _supabase.from('notifications').delete().eq('ticket_id', ticketId);
    await _supabase.from('tickets').delete().eq('id', ticketId);
  }
}