import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/ticket_model.dart';
import '../../widgets/ticket_card.dart';
import '../../widgets/stat_grid.dart';
import 'bottom_nav_admin.dart';
import 'list_tiket_admin_screen.dart';
import 'detail_tiket_admin_screen.dart';
import 'profile_admin_screen.dart';
import 'notifikasi_admin_screen.dart';
import 'buat_tiket_admin_screen.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  final _supabase = Supabase.instance.client;
  final int _navIndex = 0;

  List<Ticket> _tickets = [];
  String _userName = '';
  String _role = '';
  bool _loading = true;
  int _unreadNotif = 0;

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
          .select('full_name, role')
          .eq('id', userId)
          .single();

      final role = userRes['role'] ?? 'admin';
      List ticketRes;

      if (role == 'admin') {
        ticketRes = await _supabase
            .from('tickets')
            .select()
            .order('created_at', ascending: false);
      } else {
        ticketRes = await _supabase
            .from('tickets')
            .select()
            .eq('assigned_to', userId)
            .order('created_at', ascending: false);
      }

      final notifRes = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);

      if (mounted) {
        setState(() {
          _userName = userRes['full_name'] ?? '';
          _role = role;
          _tickets = ticketRes.map((e) => Ticket.fromJson(e)).toList();
          _unreadNotif = (notifRes as List).length;
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
      Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ListTiketAdminScreen()))
          .then((_) => _loadData());
    } else if (index == 2) {
      Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileAdminScreen()))
          .then((_) => _loadData());
    }
  }

  int get _open => _tickets.where((t) => t.status == 'open').length;
  int get _assigned =>
      _tickets.where((t) => t.assignee != 'Helpdesk IT').length;
  int get _inProgress => _tickets.where((t) => t.status == 'in_progress').length;
  int get _closed => _tickets.where((t) => t.status == 'closed').length;
  int get _rejected => _tickets.where((t) => t.status == 'rejected').length;

  @override
  Widget build(BuildContext context) {
    final recent = _tickets.take(3).toList();

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
            Text(_role == 'admin' ? 'Administrator' : 'Helpdesk',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.neutral)),
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
                  MaterialPageRoute(
                      builder: (_) => const NotifikasiAdminScreen()),
                ).then((_) => _loadData()),
              ),
              if (_unreadNotif > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: AppTheme.danger, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$_unreadNotif',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
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
                          Text('Ringkasan Semua Tiket',
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
                              StatItem(
                                  label: 'Rejected',
                                  count: _rejected,
                                  icon: Icons.cancel_rounded,
                                  color: const Color(0xFFFF8A8A)),
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
                                  builder: (_) =>
                                      const ListTiketAdminScreen())),
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
                              style: GoogleFonts.inter(
                                  color: AppTheme.neutral)),
                        ),
                      )
                    else
                      ...recent.map((t) => TicketCard(
                            ticket: t,
                            onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            DetailTiketAdminScreen(ticket: t)))
                                .then((_) => _loadData()),
                          )),
                  ],
                ),
              ),
            ),
      bottomNavigationBar:
          BottomNavAdmin(currentIndex: _navIndex, onTap: _onNavTap),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BuatTiketAdminScreen()))
            .then((_) => _loadData()),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}