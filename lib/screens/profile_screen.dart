import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/dummy_data.dart';
import '../widgets/bottom_nav.dart';
import '../main.dart';
import 'login_screen.dart';
import 'riwayat_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final total = DummyData.tickets.length;
    final inProgress =
        DummyData.tickets.where((t) => t.status == 'In Progress').length;
    final closed =
        DummyData.tickets.where((t) => t.status == 'Closed').length;
    final isDark = MyApp.of(context)?.isDark ?? false;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profil'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header biru — Colors.white di sini SENGAJA, untuk kontras di atas biru
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
                    child: Text('NA',
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary)),
                  ),
                  const SizedBox(height: 12),
                  Text('Nasywa Ashilah',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('User · 434241010',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Row(
                  children: [
                    _statCard('$total', 'Total Tiket', cardColor),
                    const SizedBox(width: 8),
                    _statCard('$inProgress', 'In Progress', cardColor),
                    const SizedBox(width: 8),
                    _statCard('$closed', 'Selesai', cardColor),
                  ],
                ),
              ),
            ),

            // Menu list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor, // ← diganti
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
                    _menuItem(Icons.person_outline, 'Edit Profil', () {}, context),
                    _divider(),
                    _menuItem(
                      Icons.receipt_long_outlined,
                      'Riwayat Tiket',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RiwayatScreen()),
                      ),
                      context,
                    ),
                    _divider(),
                    _menuItem(Icons.notifications_outlined, 'Notifikasi', () {}, context),
                    _divider(),
                    // Dark mode toggle
                    ListTile(
                      leading: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                      title: Text(
                        isDark ? 'Mode Terang' : 'Mode Gelap',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      trailing: Switch(
                        value: isDark,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (_) => MyApp.of(context)?.toggleTheme(),
                      ),
                    ),
                    _divider(),
                    _menuItem(Icons.help_outline_rounded, 'Bantuan', () {}, context),
                    _divider(),
                    _menuItem(Icons.info_outline_rounded, 'Tentang Aplikasi', () {}, context),
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
      bottomNavigationBar: BottomNav(
        currentIndex: 4,
        onTap: (i) {
          Navigator.pop(context);
        },
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
        content:
            Text('Yakin ingin keluar dari akun?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppTheme.neutral)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
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
          color: cardColor, // ← diganti
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
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppTheme.neutral),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: AppTheme.neutral),
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56);
}