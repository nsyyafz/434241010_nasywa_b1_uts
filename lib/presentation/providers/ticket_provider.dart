import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../data/models/ticket_model.dart';
import 'auth_provider.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository();
});

/// Daftar tiket sesuai role yang lagi login:
/// - admin    -> semua tiket
/// - helpdesk -> tiket yang di-assign ke dia
/// - user     -> tiket yang dia buat sendiri
///
/// Ganti nama dari `userTicketsProvider` lama karena sekarang gak cuma
/// buat "user" doang, tapi role-aware buat ketiga role.
final ticketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final role = await ref.watch(currentUserRoleProvider.future);
  final repo = ref.watch(ticketRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser!.id;

  switch (role) {
    case 'admin':
      return repo.getAllTickets();
    case 'helpdesk':
      return repo.getAssignedTickets(userId);
    default:
      return repo.getUserTickets(userId);
  }
});

/// Stats (total/in_progress/closed) dihitung dari data ticketsProvider
/// yang SAMA -> gak nembak query baru ke Supabase.
final ticketStatsProvider = FutureProvider<TicketStats>((ref) async {
  final tickets = await ref.watch(ticketsProvider.future);
  return TicketStats(
    total: tickets.length,
    inProgress: tickets.where((t) => t.status == 'in_progress').length,
    closed: tickets.where((t) => t.status == 'closed').length,
  );
});

class TicketStats {
  final int total;
  final int inProgress;
  final int closed;

  const TicketStats({
    required this.total,
    required this.inProgress,
    required this.closed,
  });
}