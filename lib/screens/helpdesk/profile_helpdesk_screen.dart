import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../setting_screen.dart';
import 'bottom_nav_helpdesk.dart';
import 'riwayat_helpdesk_screen.dart';

class ProfileHelpdeskScreen extends StatefulWidget {
  const ProfileHelpdeskScreen({super.key});

  @override
  State<ProfileHelpdeskScreen> createState() => _ProfileHelpdeskScreenState();
}

class _ProfileHelpdeskScreenState extends State<ProfileHelpdeskScreen> {
  final _supabase = Supabase.instance.client;
  String _fullName = '';
  String _email = '';
  String _initial = 'HD';
  int _total = 0;
  int _inProgress = 0;
  int _closed = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final userRes = await _supabase
          .from('users')
          .select('full_name, email')
          .eq('id', userId)
          .single();

      final ticketRes = await _supabase
          .from('tickets')
          .select('status')
          .eq('assigned_to', userId);

      if (mounted) {
        final name = userRes['full_name'] ?? '';
        final tickets = List<Map<String, dynamic>>.from(ticketRes);
        setState(() {
          _fullName = name;
          _email = userRes['email'] ?? '';
          _initial = name.isNotEmpty
              ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
              : 'HD';
          _total = tickets.length;
          _inProgress = tickets.where((t) => t['status'] == 'in_progress').length;
          _closed = tickets.where((t) => t['status'] == 'closed').length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profil'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: Text(_initial,
                              style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary)),
                        ),
                        const SizedBox(height: 12),
                        Text(_fullName,
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('🎧 Helpdesk Support',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: Colors.white)),
                        ),
                        const SizedBox(height: 4),
                        Text(_email,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),

                  // Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Transform.translate(
                      offset: const Offset(0, -20),
                      child: Row(
                        children: [
                          _statCard('$_total', 'Total Tiket', cardColor),
                          const SizedBox(width: 8),
                          _statCard('$_inProgress', 'In Progress', cardColor),
                          const SizedBox(width: 8),
                          _statCard('$_closed', 'Selesai', cardColor),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _menuItem(Icons.history_rounded, 'Riwayat Tiket',
                              () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const RiwayatHelpdeskScreen()),
                                  ),
                              context),
                          const Divider(height: 1, indent: 56),
                          _menuItem(
                            Icons.settings_outlined,
                            'Pengaturan',
                            () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettingScreen())),
                            context,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton(
                      onPressed: () => _showLogoutDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: const BorderSide(color: AppTheme.danger),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Keluar',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavHelpdesk(
          currentIndex: 3, onTap: (_) => Navigator.pop(context)),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Yakin ingin keluar dari akun?',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppTheme.neutral)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: Text('Keluar',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color cardColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppTheme.neutral),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap,
      BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(label,
          style:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: AppTheme.neutral),
      onTap: onTap,
    );
  }
}