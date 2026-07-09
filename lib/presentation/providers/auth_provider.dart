import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/user_repository.dart';

// =====================================================================
// REPOSITORY
// =====================================================================

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// =====================================================================
// USER DATA PROVIDERS
// Semua pakai .autoDispose supaya cache otomatis kebuang begitu tidak
// ada widget yang watch lagi. Ini cuma lapisan aman kedua — invalidate
// manual di AuthController.signOut() tetap yang utama, karena tab di
// bottom nav biasanya di-keep-alive jadi autoDispose sendiri gak cukup.
// =====================================================================

/// Cuma role-nya aja. Dipakai di screen yang cuma butuh tau role
/// (list_tiket, buat_tiket) tanpa perlu nama/email.
final currentUserRoleProvider = FutureProvider.autoDispose<String>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;
  final res =
      await supabase.from('users').select('role').eq('id', userId).single();
  return res['role'] ?? 'user';
});

final userNameProvider = FutureProvider.autoDispose<String>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser!.id;
  return repo.getUserName(userId);
});

/// Data lengkap buat ProfileScreen: nama, email, role dalam SATU query.
final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;
  final res = await supabase
      .from('users')
      .select('full_name, email, role')
      .eq('id', userId)
      .single();

  return UserProfile(
    fullName: res['full_name'] ?? '',
    email: res['email'] ?? '',
    role: res['role'] ?? 'user',
  );
});

class UserProfile {
  final String fullName;
  final String email;
  final String role;

  const UserProfile({
    required this.fullName,
    required this.email,
    required this.role,
  });

  String get initial => fullName.isNotEmpty
      ? fullName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
      : (role == 'admin' ? 'AD' : (role == 'helpdesk' ? 'HD' : 'NA'));
}

// =====================================================================
// UI STATE
// =====================================================================

final mainNavIndexProvider = StateProvider<int>((ref) => 0);

// =====================================================================
// AUTH CONTROLLER
// Satu pintu buat sign out. Semua screen (Profile, Setting, dll) manggil
// ref.read(authControllerProvider).signOut(ref) daripada manggil
// Supabase.signOut() langsung + invalidate manual di masing-masing tempat.
// =====================================================================

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController();
});

class AuthController {
  Future<void> signOut(WidgetRef ref) async {
    await Supabase.instance.client.auth.signOut();
    invalidateUserProviders(ref);
  }
}

/// Buang semua cache provider yang nyimpen data terikat ke user/session.
/// Dipanggil pas logout, dan idealnya juga dipanggil pas login sukses
/// (jaga-jaga kalau ganti akun tanpa logout eksplisit).
///
/// PENTING: tambahin provider baru ke sini kalau nanti bikin provider
/// baru yang datanya spesifik per-user (misal ticketStatsProvider,
/// unreadNotifCountProvider ada di file lain — invalidate juga di
/// pemanggil kalau providernya bukan dari file ini).
void invalidateUserProviders(WidgetRef ref) {
  ref.invalidate(userProfileProvider);
  ref.invalidate(currentUserRoleProvider);
  ref.invalidate(userNameProvider);
}