import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = MyApp.of(context)?.isDark ?? false;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pengaturan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tampilan',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral)),
            const SizedBox(height: 8),
            Container(
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
              child: ListTile(
                leading: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                title: Text(
                  isDark ? 'Mode Terang' : 'Mode Gelap',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Sesuaikan tampilan aplikasi',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.neutral),
                ),
                trailing: Switch(
                  value: isDark,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (_) => MyApp.of(context)?.toggleTheme(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Lainnya',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral)),
            const SizedBox(height: 8),
            Container(
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
                  _menuItem(Icons.help_outline_rounded, 'Bantuan',
                      'Pusat bantuan & FAQ', () {}),
                  const Divider(height: 1, indent: 56),
                  _menuItem(Icons.info_outline_rounded, 'Tentang Aplikasi',
                      'Versi 2.0.0', () {}),
                  const Divider(height: 1, indent: 56),
                  _menuItem(Icons.privacy_tip_outlined, 'Kebijakan Privasi',
                      'Lihat kebijakan privasi', () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.neutral)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: AppTheme.neutral),
      onTap: onTap,
    );
  }
}