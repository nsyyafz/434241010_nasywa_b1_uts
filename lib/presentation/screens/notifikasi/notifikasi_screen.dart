import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ticket_model.dart';
import '../../providers/notification_provider.dart';
import '../tiket/detail_tiket_screen.dart';

/// Gabungan NotifikasiScreen (user) + NotifikasiAdminScreen + NotifikasiHelpdeskScreen.
/// Query data notifikasi sama persis buat semua role (by user_id), jadi gak
/// perlu role-aware kecuali pas nentuin halaman detail tiket tujuan.
/// Selalu dibuka via Navigator.push (dari Dashboard/List Tiket/Profile),
/// bukan tab MainScreen — jadi pakai tombol back, bukan bottomNavigationBar.
class NotifikasiScreen extends ConsumerStatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  ConsumerState<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends ConsumerState<NotifikasiScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifs();
  }

  Future<void> _loadNotifs() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final res = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifs = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _tandaiSemuaDibaca() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      await _loadNotifs();
      ref.invalidate(unreadNotifCountProvider);
    } catch (_) {}
  }

  Future<void> _onNotifTap(Map<String, dynamic> notif) async {
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', notif['id']);
    } catch (_) {}

    final ticketId = notif['ticket_id'];
    if (ticketId != null && mounted) {
      try {
        final res = await _supabase.from('tickets').select().eq('id', ticketId).single();
        final ticket = Ticket.fromJson(res);

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailTiketScreen(ticket: ticket)),
          );
        }
      } catch (_) {}
    }

    await _loadNotifs();
    ref.invalidate(unreadNotifCountProvider);
  }

  IconData _iconFromType(String type) {
    switch (type) {
      case 'status_update':
        return Icons.update_rounded;
      case 'comment':
        return Icons.chat_bubble_outline_rounded;
      case 'closed':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'info':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _timeAgo(String createdAt) {
    final now = DateTime.now();
    final time = DateTime.parse(createdAt).toLocal();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final unreadCount = _notifs.where((n) => n['is_read'] == false).length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifikasi'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _tandaiSemuaDibaca,
              child: Text('Tandai semua',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.secondary)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_off_outlined,
                          size: 60, color: AppTheme.neutral),
                      const SizedBox(height: 16),
                      Text('Tidak ada notifikasi',
                          style: GoogleFonts.inter(color: AppTheme.neutral)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifs,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = _notifs[i];
                      final isRead = n['is_read'] as bool;
                      final type = n['type'] ?? 'info';
                      return GestureDetector(
                        onTap: () => _onNotifTap(n),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isRead ? cardColor : AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isRead
                                  ? Colors.transparent
                                  : AppTheme.secondary.withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? const Color(0xFFF1EFE8)
                                      : AppTheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_iconFromType(type),
                                    size: 20,
                                    color: isRead
                                        ? AppTheme.neutral
                                        : AppTheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(n['title'],
                                              style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.w700)),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                                color: AppTheme.primary,
                                                shape: BoxShape.circle),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(n['message'],
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppTheme.neutral)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(_timeAgo(n['created_at']),
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppTheme.neutral)),
                                        if (n['ticket_id'] != null) ...[
                                          const SizedBox(width: 8),
                                          Text('Lihat tiket →',
                                              style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: AppTheme.secondary,
                                                  fontWeight:
                                                      FontWeight.w500)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}