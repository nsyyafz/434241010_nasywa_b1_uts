import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<Map<String, dynamic>> getUserRoleAndStatus(String userId) async {
    return await _supabase
        .from('users')
        .select('role, is_active')
        .eq('id', userId)
        .single();
  }

  Future<void> logoutIfInactive() async {
    await _supabase.auth.signOut();
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    await _supabase.from('users').insert({
      'id': userId,
      'email': email,
      'full_name': fullName,
      'role': 'user',
    });
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}