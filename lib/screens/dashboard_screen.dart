import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/dummy_data.dart';
import '../widgets/ticket_card.dart';
import '../widgets/bottom_nav.dart';
import 'detail_tiket_screen.dart';
import 'list_tiket_screen.dart';
import 'buat_tiket_screen.dart';
import 'profile_screen.dart';
import 'riwayat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final int _navIndex = 0;

  void _onNavTap(int index) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ListTiketScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BuatTiketScreen()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatScreen()));
    } else if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    }
  }

  int get _open => DummyData.tickets.where((t) => t.status == 'Open').length;
  int get _inProgress => DummyData.tickets.where((t) => t.status == 'In Progress').length;
  int get _closed => DummyData.tickets.where((t) => t.status == 'Closed').length;

  @override
  Widget build(BuildContext context) {
    final recent = DummyData.tickets.take(2).toList();
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, Nasywa! 👋',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
            Text('Semangat hari ini!',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.neutral)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                  const SizedBox(height: 4),
                  Text('${DummyData.tickets.length} Total Tiket',
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statPill('Open', _open, const Color(0xFFEAF3DE), AppTheme.success),
                      const SizedBox(width: 8),
                      _statPill('In Progress', _inProgress, Colors.white.withOpacity(0.2), Colors.white),
                      const SizedBox(width: 8),
                      _statPill('Closed', _closed, Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.8)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tiket terbaru
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tiket Terbaru',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ListTiketScreen())),
                  child: Text('Lihat Semua',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.secondary, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recent.map((t) => TicketCard(
                  ticket: t,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => DetailTiketScreen(ticket: t))),
                )),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(currentIndex: _navIndex, onTap: _onNavTap),
    );
  }

  Widget _statPill(String label, int count, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text('$label $count',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}