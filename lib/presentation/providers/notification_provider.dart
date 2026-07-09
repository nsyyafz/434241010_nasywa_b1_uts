import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Jumlah notifikasi belum dibaca buat user yang login.
/// Dipakai buat badge merah di icon bell (dashboard, list_tiket, profile).
final unreadNotifCountProvider = FutureProvider<int>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;

  final res = await supabase
      .from('notifications')
      .select()
      .eq('user_id', userId)
      .eq('is_read', false);

  return (res as List).length;
});