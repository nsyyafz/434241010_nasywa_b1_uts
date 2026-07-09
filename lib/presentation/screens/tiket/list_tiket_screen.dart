import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ticket_model.dart';
import '../../../core/widgets/ticket_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/notification_provider.dart';
import '../notifikasi/notifikasi_screen.dart';
import '../tiket/detail_tiket_screen.dart';

/// Tab "Tiket". Gak punya bottomNavigationBar lagi — ditangani MainScreen.
class ListTiketScreen extends ConsumerStatefulWidget {
  const ListTiketScreen({super.key});

  @override
  ConsumerState<ListTiketScreen> createState() => _ListTiketScreenState();
}

class _ListTiketScreenState extends ConsumerState<ListTiketScreen> {
  String _filter = 'Semua';

  List<String> _filters(String role) => role == 'helpdesk'
      ? ['Semua', 'open', 'in_progress', 'closed']
      : ['Semua', 'open', 'in_progress', 'closed', 'rejected'];

  List<String> _filterLabels(String role) => role == 'helpdesk'
      ? ['Semua', 'Open', 'In Progress', 'Closed']
      : ['Semua', 'Open', 'In Progress', 'Closed', 'Rejected'];

  List<Ticket> _applyFilter(List<Ticket> tickets) => _filter == 'Semua'
      ? tickets
      : tickets.where((t) => t.status == _filter).toList();

void _openDetail(Ticket ticket) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => DetailTiketScreen(ticket: ticket)),
  ).then((_) {
    ref.invalidate(ticketsProvider);
    ref.invalidate(unreadNotifCountProvider);
  });
}

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  String _title(String role) {
    switch (role) {
      case 'admin':
        return 'Semua Tiket';
      case 'helpdesk':
        return 'Tiket Saya';
      default:
        return 'Daftar Tiket';
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(currentUserRoleProvider);

    return roleAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Gagal memuat: $e')),
      ),
      data: (role) => _buildScaffold(context, role),
    );
  }

  Widget _buildScaffold(BuildContext context, String role) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final unreadAsync = ref.watch(unreadNotifCountProvider);
    final filters = _filters(role);
    final filterLabels = _filterLabels(role);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_title(role)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppTheme.primary),
                onPressed: () => _push(const NotifikasiScreen()),
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
          if (role != 'helpdesk')
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppTheme.primary),
              onPressed: () {},
            ),
        ],
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat tiket: $e')),
        data: (tickets) {
          final filtered = _applyFilter(tickets);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ticketsProvider);
              ref.invalidate(unreadNotifCountProvider);
            },
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filterLabels.length,
                    itemBuilder: (_, i) {
                      final isActive = _filter == filters[i];
                      return GestureDetector(
                        onTap: () => setState(() => _filter = filters[i]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.primary
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.primary
                                  : const Color(0xFFD3D1C7),
                            ),
                          ),
                          child: Center(
                            child: Text(filterLabels[i],
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isActive
                                        ? Colors.white
                                        : AppTheme.neutral)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text('Tidak ada tiket',
                              style: GoogleFonts.inter(color: AppTheme.neutral)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => TicketCard(
                            ticket: filtered[i],
                            onTap: () => _openDetail(filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}