import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../models/ticket_model.dart';
import '../widgets/ticket_card.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/stat_grid.dart';
import 'detail_tiket_screen.dart';
import 'list_tiket_screen.dart';
import 'buat_tiket_screen.dart';
import 'profile_screen.dart';
import 'riwayat_screen.dart';
import 'notifikasi_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final int _navIndex = 0;
  final _supabase = Supabase.instance.client;

  List<Ticket> _tickets = [];
  String _userName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final userRes = await _supabase
          .from('users')
          .select('full_name')
          .eq('id', userId)
          .single();

      final ticketRes = await _supabase
          .from('tickets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _userName = userRes['full_name'] ?? '';
          _tickets =
              (ticketRes as List).map((e) => Ticket.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onNavTap(int index) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ListTiketScreen()),
      ).then((_) => _loadData());
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BuatTiketScreen()),
      ).then((_) => _loadData());
    } else if (index == 3) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const RiwayatScreen()));
    } else if (index == 4) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    }
  }

  int get _open => _tickets.where((t) => t.status == 'open').length;
  int get _assigned =>
      _tickets.where((t) => t.assignee != 'Helpdesk IT').length;
  int get _inProgress =>
      _tickets.where((t) => t.status == 'in_progress').length;
  int get _closed => _tickets.where((t) => t.status == 'closed').length;

  @override
  Widget build(BuildContext context) {
    final recent = _tickets.take(2).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, $_userName! 👋',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
            Text('Semangat hari ini!',
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppTheme.danger, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ringkasan Tiket',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8))),
                          const SizedBox(height: 4),
                          Text('${_tickets.length} Total Tiket',
                              style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 16),
                          StatGrid(
                            crossAxisCount: 2,
                            items: [
                              StatItem(
                                  label: 'Open',
                                  count: _open,
                                  icon: Icons.lock_open_rounded,
                                  color: AppTheme.success),
                              StatItem(
                                  label: 'Assigned',
                                  count: _assigned,
                                  icon: Icons.person_pin_circle_rounded,
                                  color: Colors.white),
                              StatItem(
                                  label: 'In Progress',
                                  count: _inProgress,
                                  icon: Icons.autorenew_rounded,
                                  color: Colors.white),
                              StatItem(
                                  label: 'Closed',
                                  count: _closed,
                                  icon: Icons.check_circle_rounded,
                                  color: Colors.white),
                            ],
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
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ListTiketScreen())),
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
                          child: Text('Belum ada tiket',
                              style:
                                  GoogleFonts.inter(color: AppTheme.neutral)),
                        ),
                      )
                    else
                      ...recent.map((t) => TicketCard(
                            ticket: t,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        DetailTiketScreen(ticket: t))),
                          )),
                  ],
                ),
              ),
            ),
      bottomNavigationBar:
          BottomNav(currentIndex: _navIndex, onTap: _onNavTap),
    );
  }
}