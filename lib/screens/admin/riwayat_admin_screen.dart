import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/ticket_model.dart';
import '../../widgets/ticket_card.dart';
import 'detail_tiket_admin_screen.dart';

class RiwayatAdminScreen extends StatefulWidget {
  const RiwayatAdminScreen({super.key});

  @override
  State<RiwayatAdminScreen> createState() => _RiwayatAdminScreenState();
}

class _RiwayatAdminScreenState extends State<RiwayatAdminScreen> {
  final _supabase = Supabase.instance.client;
  String _filter = 'Semua';
  final List<String> _filters = ['Semua', 'Closed', 'Rejected'];
  List<Ticket> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    try {
      final res = await _supabase
          .from('tickets')
          .select()
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
    return _tickets.where((t) => t.status == _filter.toLowerCase()).toList();
  }

  int get _closedCount => _tickets.where((t) => t.status == 'closed').length;
  int get _rejectedCount => _tickets.where((t) => t.status == 'rejected').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
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
                                    color:
                                        AppTheme.neutral.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                Text('Belum ada riwayat tiket',
                                    style: GoogleFonts.inter(
                                        color: AppTheme.neutral,
                                        fontSize: 14)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => TicketCard(
                              ticket: _filtered[i],
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => DetailTiketAdminScreen(
                                          ticket: _filtered[i]))),
                            ),
                          ),
                  ),
                ],
              ),
            ),
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