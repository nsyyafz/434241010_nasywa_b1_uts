import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../models/ticket_model.dart';
import '../widgets/ticket_card.dart';
import '../widgets/bottom_nav.dart';
import 'detail_tiket_screen.dart';
import 'buat_tiket_screen.dart';
import 'profile_screen.dart';
import 'list_tiket_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _supabase = Supabase.instance.client;
  String _filter = 'Semua';
  final List<String> _filters = ['Semua', 'Closed', 'Rejected'];
  final List<String> _filterValues = ['semua', 'closed', 'rejected'];

  List<Ticket> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final res = await _supabase
          .from('tickets')
          .select()
          .eq('user_id', userId)
          .inFilter('status', ['closed', 'rejected'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _tickets = (res as List).map((e) => Ticket.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Ticket> get _filtered {
    if (_filter == 'Semua') return _tickets;
    final filterVal = _filter.toLowerCase();
    return _tickets.where((t) => t.status == filterVal).toList();
  }

  int get _closedCount => _tickets.where((t) => t.status == 'closed').length;
  int get _rejectedCount => _tickets.where((t) => t.status == 'rejected').length;

  // ===== FIX: Home selalu balik ke root (Dashboard), Tiket buka ListTiketScreen =====
  void _onNavTap(int index) {
    if (index == 3) return; // sudah di Riwayat

    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ListTiketScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BuatTiketScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Riwayat Tiket'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRiwayat,
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
                          _summaryItem('Total Selesai', '$_closedCount'),
                          Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3)),
                          _summaryItem('Ditolak', '$_rejectedCount'),
                        ],
                      ),
                    ),
                  ),

                  // Filter tabs
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: _filters.length,
                      itemBuilder: (_, i) {
                        final isActive = _filter == _filters[i];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _filter = _filters[i]),
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
                              child: Text(_filters[i],
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

                  // List
                  Expanded(
                    child: _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded,
                                    size: 64,
                                    color: AppTheme.neutral.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                Text('Belum ada riwayat tiket',
                                    style: GoogleFonts.inter(
                                        color: AppTheme.neutral, fontSize: 14)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => TicketCard(
                              ticket: _filtered[i],
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => DetailTiketScreen(
                                          ticket: _filtered[i]))),
                            ),
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNav(currentIndex: 3, onTap: _onNavTap),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }
}