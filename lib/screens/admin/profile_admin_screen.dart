import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../setting_screen.dart';
import 'bottom_nav_admin.dart';
import 'list_tiket_admin_screen.dart';
import 'riwayat_admin_screen.dart';
import 'user_management_screen.dart';

class ProfileAdminScreen extends StatefulWidget {
  const ProfileAdminScreen({super.key});

  @override
  State<ProfileAdminScreen> createState() => _ProfileAdminScreenState();
}

class _ProfileAdminScreenState extends State<ProfileAdminScreen> {
  final _supabase = Supabase.instance.client;
  String _fullName = '';
  String _email = '';
  String _role = '';
  String _initial = 'AD';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final res = await _supabase
          .from('users')
          .select('full_name, email, role')
          .eq('id', userId)
          .single();

      if (mounted) {
        final name = res['full_name'] ?? '';
        setState(() {
          _fullName = name;
          _email = res['email'] ?? '';
          _role = res['role'] ?? '';
          _initial = name.isNotEmpty
              ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
              : 'AD';
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

  void _onNavTap(int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (index == 1) {
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ListTiketAdminScreen()),
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
                  // Header
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
                          child: Text(
                            _role == 'admin' ? '👑 Administrator' : '🎧 Helpdesk',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_email,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Menu
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
                          _menuItem(Icons.people_outline_rounded,
                              'Kelola Pengguna',
                              () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const UserManagementScreen()),
                                  ),
                              context),
                          const Divider(height: 1, indent: 56),
                          _menuItem(Icons.history_rounded, 'Riwayat Tiket',
                              () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const RiwayatAdminScreen()),
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

                  // Logout
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
      bottomNavigationBar: BottomNavAdmin(
        currentIndex: 2,
        onTap: _onNavTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
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