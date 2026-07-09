import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/notification_provider.dart';
import '../notifikasi/notifikasi_screen.dart';

// --- Auth ---
import '../auth/login_screen.dart';

// --- Profile (sibling) ---
import 'edit_profile_screen.dart';
import 'setting_screen.dart';

// --- Admin / Helpdesk: item menu yang BUKAN tab (Riwayat udah jadi tab, gak di-push lagi) ---
import '../admin/user_management_screen.dart';

/// Tab "Profil". Gak punya bottomNavigationBar lagi — ditangani MainScreen.
/// Menu "Riwayat Tiket" pindah tab (index 3) via mainNavIndexProvider,
/// bukan Navigator.push, karena Riwayat udah jadi tab tersendiri.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
     await ref.read(authControllerProvider).signOut(ref);
     if (context.mounted) {
       Navigator.pushAndRemoveUntil(
         context,
         MaterialPageRoute(builder: (_) => const LoginScreen()),
         (route) => false,
       );
     }
   }

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget? _roleBadge(String role) {
    String? label;
    if (role == 'admin') label = '👑 Administrator';
    if (role == 'helpdesk') label = '🎧 Helpdesk Support';
    if (label == null) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
      ),
    );
  }

  /// Khusus admin ada menu "Kelola Pengguna" di paling atas.
  List<Widget> _menuItems(BuildContext context, WidgetRef ref, String role) {
    void goToRiwayat() => ref.read(mainNavIndexProvider.notifier).state = 3;

    switch (role) {
      case 'admin':
        return [
          _menuItem(Icons.people_outline_rounded, 'Kelola Pengguna',
              () => _push(context, const UserManagementScreen())),
          _divider(),
          _menuItem(Icons.history_rounded, 'Riwayat Tiket', goToRiwayat),
          _divider(),
          _menuItem(Icons.settings_outlined, 'Pengaturan',
              () => _push(context, const SettingScreen())),
        ];

      case 'helpdesk':
        return [
          _menuItem(Icons.history_rounded, 'Riwayat Tiket', goToRiwayat),
          _divider(),
          _menuItem(Icons.settings_outlined, 'Pengaturan',
              () => _push(context, const SettingScreen())),
        ];

      default: // user
        return [
          _menuItem(Icons.person_outline, 'Edit Profil',
              () => _push(context, const EditProfileScreen())),
          _divider(),
          _menuItem(Icons.receipt_long_outlined, 'Riwayat Tiket', goToRiwayat),
          _divider(),
          _menuItem(Icons.settings_outlined, 'Pengaturan',
              () => _push(context, const SettingScreen())),
        ];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Gagal memuat profil: $e')),
      ),
      data: (profile) => _buildScaffold(context, ref, profile),
    );
  }

  Widget _buildScaffold(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final role = profile.role;
    final showStats = role != 'admin';
    final statsAsync = ref.watch(ticketStatsProvider);
    final unreadAsync = ref.watch(unreadNotifCountProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profil'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppTheme.primary),
               onPressed: () => _push(context, const NotifikasiScreen()),
              ),
              unreadAsync.maybeWhen(
                data: (count) => count > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                              color: AppTheme.danger, shape: BoxShape.circle),
                          child: Center(
                            child: Text('$count',
                                style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    child: Text(profile.initial,
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary)),
                  ),
                  const SizedBox(height: 12),
                  Text(profile.fullName,
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  if (_roleBadge(role) != null) _roleBadge(role)!,
                  const SizedBox(height: 4),
                  Text(profile.email,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),

            // Stats (user & helpdesk aja)
            if (showStats)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: statsAsync.when(
                    loading: () => const SizedBox(
                        height: 70,
                        child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => SizedBox(
                        height: 70, child: Center(child: Text('Gagal: $e'))),
                    data: (stats) => Row(
                      children: [
                        _statCard('${stats.total}', 'Total Tiket', cardColor),
                        const SizedBox(width: 8),
                        _statCard(
                            '${stats.inProgress}', 'In Progress', cardColor),
                        const SizedBox(width: 8),
                        _statCard('${stats.closed}', 'Selesai', cardColor),
                      ],
                    ),
                  ),
                ),
              ),

            // Menu (khusus admin ada "Kelola Pengguna" di atas)
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
                child: Column(children: _menuItems(context, ref, role)),
              ),
            ),
            const SizedBox(height: 20),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: () => _showLogoutDialog(context, ref),
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
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              Navigator.pop(context);
              _logout(context, ref);
            },
            child:
                Text('Keluar', style: GoogleFonts.inter(color: Colors.white)),
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

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
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