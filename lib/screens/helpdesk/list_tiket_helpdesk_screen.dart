import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/ticket_model.dart';
import '../../widgets/ticket_card.dart';
import 'bottom_nav_helpdesk.dart';
import 'detail_tiket_helpdesk_screen.dart';
import 'profile_helpdesk_screen.dart';
import 'notifikasi_helpdesk_screen.dart';

class ListTiketHelpdeskScreen extends StatefulWidget {
  const ListTiketHelpdeskScreen({super.key});

  @override
  State<ListTiketHelpdeskScreen> createState() => _ListTiketHelpdeskScreenState();
}

class _ListTiketHelpdeskScreenState extends State<ListTiketHelpdeskScreen> {
  final _supabase = Supabase.instance.client;
  String _filter = 'Semua';
  final List<String> _filters = ['Semua', 'open', 'in_progress', 'closed'];
  final List<String> _filterLabels = ['Semua', 'Open', 'In Progress', 'Closed'];
  List<Ticket> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final res = await _supabase
          .from('tickets')
          .select()
          .eq('assigned_to', userId)
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

  List<Ticket> get _filtered => _filter == 'Semua'
      ? _tickets
      : _tickets.where((t) => t.status == _filter).toList();

  void _onNavTap(int index) {
    if (index == 1) return;
    if (index == 0) Navigator.pop(context);
    if (index == 2) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NotifikasiHelpdeskScreen()));
    }
    if (index == 3) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ProfileHelpdeskScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tiket Saya'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: _filterLabels.length,
                      itemBuilder: (_, i) {
                        final isActive = _filter == _filters[i];
                        return GestureDetector(
                          onTap: () => setState(() => _filter = _filters[i]),
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
                              child: Text(_filterLabels[i],
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
                    child: _filtered.isEmpty
                        ? Center(
                            child: Text('Tidak ada tiket',
                                style: GoogleFonts.inter(color: AppTheme.neutral)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => TicketCard(
                              ticket: _filtered[i],
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => DetailTiketHelpdeskScreen(
                                          ticket: _filtered[i])))
                                  .then((_) => _loadTickets()),
                            ),
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavHelpdesk(currentIndex: 1, onTap: _onNavTap),
    );
  }
}