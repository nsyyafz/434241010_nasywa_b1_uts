import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ticket_model.dart';
import '../../../core/widgets/ticket_card.dart';
import '../../../core/widgets/stat_grid.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/notification_provider.dart';
import '../notifikasi/notifikasi_screen.dart';
import '../tiket/detail_tiket_screen.dart';

/// Tab "Home". Gak punya bottomNavigationBar/FAB lagi
/// (ditangani MainScreen via IndexedStack + tab "Buat").
/// "Lihat Semua" / tap kartu tiket pindah TAB (index 1), bukan Navigator.push,
/// karena List Tiket udah jadi tab tersendiri.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

void _openDetail(BuildContext context, WidgetRef ref, Ticket ticket) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => DetailTiketScreen(ticket: ticket)),
  ).then((_) {
    ref.invalidate(ticketsProvider);
    ref.invalidate(unreadNotifCountProvider);
  });
}

  String _subtitle(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'helpdesk':
        return 'Helpdesk Support';
      default:
        return 'Semangat hari ini!';
    }
  }

  String _summaryLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Ringkasan Semua Tiket';
      case 'helpdesk':
        return 'Tiket Ditugaskan ke Saya';
      default:
        return 'Ringkasan Tiket';
    }
  }

  int _statCrossAxisCount(String role) => role == 'helpdesk' ? 3 : 2;

  List<StatItem> _statItems(String role, List<Ticket> tickets) {
    final open = tickets.where((t) => t.status == 'open').length;
    final inProgress =
        tickets.where((t) => t.status == 'in_progress').length;
    final closed = tickets.where((t) => t.status == 'closed').length;

    if (role == 'helpdesk') {
      return [
        StatItem(
            label: 'Open',
            count: open,
            icon: Icons.lock_open_rounded,
            color: AppTheme.success),
        StatItem(
            label: 'In Progress',
            count: inProgress,
            icon: Icons.autorenew_rounded,
            color: Colors.white),
        StatItem(
            label: 'Closed',
            count: closed,
            icon: Icons.check_circle_rounded,
            color: Colors.white),
      ];
    }

    // admin & user sama-sama punya "Assigned"; admin tambah "Rejected"
    final assigned =
        tickets.where((t) => t.assignee != 'Helpdesk IT').length;
    final items = [
      StatItem(
          label: 'Open',
          count: open,
          icon: Icons.lock_open_rounded,
          color: AppTheme.success),
      StatItem(
          label: 'Assigned',
          count: assigned,
          icon: Icons.person_pin_circle_rounded,
          color: Colors.white),
      StatItem(
          label: 'In Progress',
          count: inProgress,
          icon: Icons.autorenew_rounded,
          color: Colors.white),
      StatItem(
          label: 'Closed',
          count: closed,
          icon: Icons.check_circle_rounded,
          color: Colors.white),
    ];

    if (role == 'admin') {
      final rejected = tickets.where((t) => t.status == 'rejected').length;
      items.add(StatItem(
          label: 'Rejected',
          count: rejected,
          icon: Icons.cancel_rounded,
          color: const Color(0xFFFF8A8A)));
    }

    return items;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Gagal memuat: $e'))),
      data: (profile) => _buildScaffold(context, ref, profile),
    );
  }

  Widget _buildScaffold(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    final role = profile.role;
    final ticketsAsync = ref.watch(ticketsProvider);
    final unreadAsync = ref.watch(unreadNotifCountProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, ${profile.fullName}! 👋',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
            Text(_subtitle(role),
                style:
                    GoogleFonts.inter(fontSize: 12, color: AppTheme.neutral)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppTheme.primary),
               onPressed: () => _push(context, const NotifikasiScreen()),
              ),
              unreadAsync.maybeWhen(
                data: (count) => count > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                              color: AppTheme.danger, shape: BoxShape.circle),
                          child: Center(
                            child: Text('$count',
                                style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat tiket: $e')),
        data: (tickets) {
          final recent = tickets.take(3).toList();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ticketsProvider);
              ref.invalidate(unreadNotifCountProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_summaryLabel(role),
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8))),
                        const SizedBox(height: 4),
                        Text('${tickets.length} Total Tiket',
                            style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 16),
                        StatGrid(
                          crossAxisCount: _statCrossAxisCount(role),
                          items: _statItems(role, tickets),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tiket Terbaru',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      GestureDetector(
                        onTap: () =>
                            ref.read(mainNavIndexProvider.notifier).state = 1,
                        child: Text('Lihat Semua',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (recent.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.inbox_outlined,
                                size: 48, color: AppTheme.neutral),
                            const SizedBox(height: 12),
                            Text(
                                role == 'helpdesk'
                                    ? 'Belum ada tiket ditugaskan'
                                    : 'Belum ada tiket',
                                style: GoogleFonts.inter(
                                    color: AppTheme.neutral)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...recent.map((t) => TicketCard(
                          ticket: t,
                          onTap: () => _openDetail(context, ref, t),
                        )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}