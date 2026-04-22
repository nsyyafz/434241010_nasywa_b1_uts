import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/dummy_data.dart';
import '../models/ticket_model.dart';
import '../widgets/ticket_card.dart';
import '../widgets/bottom_nav.dart';
import 'detail_tiket_screen.dart';
import 'buat_tiket_screen.dart';
import 'profile_screen.dart';
import 'riwayat_screen.dart';

class ListTiketScreen extends StatefulWidget {
  const ListTiketScreen({super.key});

  @override
  State<ListTiketScreen> createState() => _ListTiketScreenState();
}

class _ListTiketScreenState extends State<ListTiketScreen> {
  String _filter = 'Semua';
  final List<String> _filters = ['Semua', 'Open', 'In Progress', 'Pending', 'Closed', 'Rejected'];

  List<Ticket> get _filtered => _filter == 'Semua'
      ? DummyData.tickets
      : DummyData.tickets.where((t) => t.status == _filter).toList();

  void _onNavTap(int index) {
    if (index == 1) return;
    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BuatTiketScreen()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatScreen()));
    } else if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Daftar Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppTheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
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
            child: _filtered.isEmpty
                ? Center(child: Text('Tidak ada tiket',
                    style: GoogleFonts.inter(color: AppTheme.neutral)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => TicketCard(
                      ticket: _filtered[i],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => DetailTiketScreen(ticket: _filtered[i]))),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(currentIndex: 1, onTap: _onNavTap),
    );
  }
}