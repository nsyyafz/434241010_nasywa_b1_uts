import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ticket_model.dart';
import '../../../core/widgets/ticket_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../tiket/detail_tiket_screen.dart';

/// Tab "Riwayat" — satu screen untuk semua role, role-aware di dalam.
/// Ini konten tab (index 3 di MainScreen), BUKAN halaman push:
/// - tidak boleh ada tombol back / leading
/// - tidak boleh ada bottomNavigationBar sendiri
class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key});

  @override
  ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen> {
  String _filter = 'Semua';
  final List<String> _filters = ['Semua', 'Closed', 'Rejected'];

  List<Ticket> _riwayat(List<Ticket> all) =>
      all.where((t) => t.status == 'closed' || t.status == 'rejected').toList();

  List<Ticket> _applyFilter(List<Ticket> riwayat) {
    if (_filter == 'Semua') return riwayat;
    return riwayat.where((t) => t.status == _filter.toLowerCase()).toList();
  }

  String _title(String role) => role == 'helpdesk' ? 'Riwayat Tiket Saya' : 'Riwayat Tiket';

void _openDetail(Ticket ticket) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => DetailTiketScreen(ticket: ticket)),
  ).then((_) {
    ref.invalidate(ticketsProvider);
  });
}

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(currentUserRoleProvider);

    return roleAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Gagal memuat: $e'))),
      data: (role) => _buildScaffold(context, role),
    );
  }

  Widget _buildScaffold(BuildContext context, String role) {
    final ticketsAsync = ref.watch(ticketsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // tab content, bukan halaman push
        title: Text(_title(role)),
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (all) {
          final riwayat = _riwayat(all);
          final filtered = _applyFilter(riwayat);
          final closedCount = riwayat.where((t) => t.status == 'closed').length;
          final rejectedCount = riwayat.where((t) => t.status == 'rejected').length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ticketsProvider),
            child: Column(
              children: [
                // Summary card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryItem('Total Selesai', '$closedCount'),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                        _summaryItem('Ditolak', '$rejectedCount'),
                      ],
                    ),
                  ),
                ),

                // Filter tabs
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filters.length,
                    itemBuilder: (_, i) {
                      final isActive = _filter == _filters[i];
                      return GestureDetector(
                        onTap: () => setState(() => _filter = _filters[i]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.primary : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive ? AppTheme.primary : const Color(0xFFD3D1C7),
                            ),
                          ),
                          child: Center(
                            child: Text(_filters[i],
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isActive ? Colors.white : AppTheme.neutral)),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded, size: 64, color: AppTheme.neutral.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              Text(
                                  role == 'helpdesk'
                                      ? 'Belum ada riwayat tiket ditugaskan'
                                      : 'Belum ada riwayat tiket',
                                  style: GoogleFonts.inter(color: AppTheme.neutral, fontSize: 14)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }
}