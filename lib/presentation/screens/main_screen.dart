import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/bottom_nav.dart';
import '../providers/auth_provider.dart';

// --- Sudah di-merge, role-aware di dalam ---
import 'dashboard/dashboard_screen.dart';
import 'tiket/list_tiket_screen.dart';
import 'tiket/buat_tiket_screen.dart';
import 'profile/profile_screen.dart';

import 'riwayat/riwayat_screen.dart';

/// Shell tunggal buat semua role. Satu-satunya widget yang tau
/// gimana caranya pindah tab. Screen anak gak perlu tau navigasi tab lagi
/// (kecuali baca/tulis mainNavIndexProvider kalau butuh pindah tab dari dalam).
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserRoleProvider);
    final currentIndex = ref.watch(mainNavIndexProvider);

    return roleAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Gagal memuat: $e'))),
      data: (role) {
        final screens = [
          const DashboardScreen(),
          const ListTiketScreen(),
          const BuatTiketScreen(),
          const RiwayatScreen(),
          const ProfileScreen(),
        ];

        return Scaffold(
          body: IndexedStack(index: currentIndex, children: screens),
          bottomNavigationBar: BottomNav(
            currentIndex: currentIndex,
            onTap: (i) => ref.read(mainNavIndexProvider.notifier).state = i,
          ),
        );
      },
    );
  }
}