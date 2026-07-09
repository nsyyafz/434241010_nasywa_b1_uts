import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final _supabase = Supabase.instance.client;

  Future<String> getUserName(String userId) async {
    final res = await _supabase
        .from('users')
        .select('full_name')
        .eq('id', userId)
        .single();
    return res['full_name'] ?? '';
  }

  Future<List<Map<String, dynamic>>> getHelpdeskList() async {
    final res = await _supabase.from('users').select('id, full_name').eq('role', 'helpdesk');
    return List<Map<String, dynamic>>.from(res);
  }

  /// BARU — dipakai di edit_profile_screen (ambil nama & email sendiri)
  Future<Map<String, dynamic>> getOwnProfile(String userId) async {
    return await _supabase
        .from('users')
        .select('full_name, email')
        .eq('id', userId)
        .single();
  }

  /// BARU — dipakai di edit_profile_screen (update nama sendiri)
  Future<void> updateFullName({required String userId, required String fullName}) async {
    await _supabase.from('users').update({'full_name': fullName}).eq('id', userId);
  }

  /// BARU — dipakai di user_management_screen (ambil semua user, khusus admin)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final res = await _supabase.from('users').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// BARU — dipakai di user_management_screen (toggle aktif/nonaktif, khusus admin)
  Future<void> toggleActiveStatus({required String userId, required bool isActive}) async {
    await _supabase.from('users').update({'is_active': isActive}).eq('id', userId);
  }
}