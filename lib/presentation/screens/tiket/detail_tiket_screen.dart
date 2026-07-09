import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import 'tracking_screen.dart';

/// Gabungan DetailTiketScreen (user) + DetailTiketAdminScreen + DetailTiketHelpdeskScreen.
/// Role-aware: user cuma lihat & komentar, admin bisa assign+delete, helpdesk bisa finish+lapor.
/// Selalu dibuka via Navigator.push (dari Dashboard/List/Riwayat/Notifikasi),
/// pemanggilnya sudah invalidate ticketsProvider & unreadNotifCountProvider di .then(),
/// jadi di sini cukup Navigator.pop setelah aksi berhasil.
class DetailTiketScreen extends ConsumerStatefulWidget {
  final Ticket ticket;
  const DetailTiketScreen({super.key, required this.ticket});

  @override
  ConsumerState<DetailTiketScreen> createState() => _DetailTiketScreenState();
}

class _DetailTiketScreenState extends ConsumerState<DetailTiketScreen> {
  final _commentCtrl = TextEditingController();
  final _laporCtrl = TextEditingController();

  final _ticketRepo = TicketRepository();
  final _commentRepo = CommentRepository();
  final _notifRepo = NotificationRepository();
  final _userRepo = UserRepository();
  final _supabase = Supabase.instance.client;

  List<Comment> _comments = [];
  List<Map<String, dynamic>> _helpdeskList = [];
  String? _selectedHelpdesk;
  String _userInitial = 'U';

  bool _loadingComments = true;
  bool _sending = false;
  bool _assigning = false;
  bool _finishing = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket.status;
    _loadComments();
    _loadOwnInitial();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _commentRepo.getComments(widget.ticket.id);
      if (mounted) setState(() {
        _comments = comments;
        _loadingComments = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  /// Dipakai buat avatar bubble komentar milik sendiri (role user)
  Future<void> _loadOwnInitial() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final name = await _userRepo.getUserName(userId);
      if (mounted && name.isNotEmpty) {
        setState(() {
          _userInitial =
              name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();
        });
      }
    } catch (_) {}
  }

  /// Khusus admin: load daftar helpdesk buat dropdown assign
  Future<void> _loadHelpdesks() async {
    try {
      final list = await _userRepo.getHelpdeskList();
      if (mounted) setState(() => _helpdeskList = list);
    } catch (_) {}
  }

  Future<void> _assignTiket() async {
    if (_selectedHelpdesk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih helpdesk dulu')),
      );
      return;
    }

    setState(() => _assigning = true);
    try {
      await _ticketRepo.assignTicket(
        ticketId: widget.ticket.id,
        helpdeskId: _selectedHelpdesk!,
      );

      final helpdeskName =
          _helpdeskList.firstWhere((h) => h['id'] == _selectedHelpdesk)['full_name'];

      await _notifRepo.send(
        userId: _selectedHelpdesk!,
        title: 'Tiket baru ditugaskan',
        message: 'Kamu ditugaskan untuk menangani tiket "${widget.ticket.title}"',
        type: 'info',
        ticketId: widget.ticket.id,
      );
      await _notifRepo.send(
        userId: widget.ticket.userId!,
        title: 'Tiket sedang diproses',
        message: 'Tiket "${widget.ticket.title}" sedang ditangani oleh helpdesk',
        type: 'status_update',
        ticketId: widget.ticket.id,
      );

      if (mounted) {
        setState(() {
          _assigning = false;
          _currentStatus = 'in_progress';
        });
        ref.invalidate(ticketsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tiket di-assign ke $helpdeskName & status jadi In Progress'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _assigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal assign: $e')),
        );
      }
    }
  }

  Future<void> _finishTiket() async {
    setState(() => _finishing = true);
    try {
      await _ticketRepo.updateStatus(ticketId: widget.ticket.id, status: 'closed');
      await _notifRepo.send(
        userId: widget.ticket.userId!,
        title: 'Tiket selesai dikerjakan',
        message: 'Tiket "${widget.ticket.title}" telah diselesaikan oleh helpdesk',
        type: 'closed',
        ticketId: widget.ticket.id,
      );

      if (mounted) {
        setState(() {
          _currentStatus = 'closed';
          _finishing = false;
        });
        ref.invalidate(ticketsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tiket berhasil diselesaikan!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _finishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyelesaikan tiket: $e')),
        );
      }
    }
  }

  Future<void> _sendComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    final message = _commentCtrl.text.trim();
    _commentCtrl.clear();

    setState(() => _sending = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final role = await ref.read(currentUserRoleProvider.future);

      await _commentRepo.sendComment(
        ticketId: widget.ticket.id,
        userId: userId,
        message: message,
      );

      // Notifikasi ke user pemilik tiket — kecuali kalau yang komentar user itu sendiri
      if (role != 'user') {
        final senderLabel = role == 'admin' ? 'Admin' : 'Helpdesk';
        await _notifRepo.send(
          userId: widget.ticket.userId!,
          title: 'Komentar baru',
          message: '$senderLabel membalas tiket "${widget.ticket.title}"',
          type: 'comment',
          ticketId: widget.ticket.id,
        );
      }

      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal kirim komentar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _laporKeAdmin() async {
    if (_laporCtrl.text.trim().isEmpty) return;
    try {
      final userId = _supabase.auth.currentUser!.id;
      final message = '[LAPORAN HELPDESK] ${_laporCtrl.text.trim()}';

      await _commentRepo.sendComment(
        ticketId: widget.ticket.id,
        userId: userId,
        message: message,
      );

      await _notifRepo.sendToAllAdmins(
        title: 'Laporan dari Helpdesk',
        message: 'Helpdesk melaporkan tiket "${widget.ticket.title}"',
        type: 'info',
        ticketId: widget.ticket.id,
      );

      if (mounted) {
        _laporCtrl.clear();
        Navigator.pop(context); // tutup dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil dikirim ke admin'),
            backgroundColor: AppTheme.success,
          ),
        );
        await _loadComments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal lapor: $e')),
        );
      }
    }
  }

  Future<void> _deleteTiket() async {
    try {
      await _ticketRepo.deleteTicket(widget.ticket.id);
      if (mounted) {
        Navigator.pop(context); // balik ke List/Dashboard/Riwayat, invalidate sudah ditangani caller
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tiket berhasil dihapus'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus tiket: $e')),
        );
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Tiket', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Tiket "${widget.ticket.title}" akan dihapus permanen. Lanjutkan?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter(color: AppTheme.neutral)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(context);
              _deleteTiket();
            },
            child: Text('Hapus', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Selesaikan Tiket', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Tandai tiket "${widget.ticket.title}" sebagai selesai? User akan mendapat notifikasi.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter(color: AppTheme.neutral)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () {
              Navigator.pop(context);
              _finishTiket();
            },
            child: Text('Selesaikan', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLaporDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Lapor ke Admin', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tulis laporan yang akan dikirim ke admin:',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.neutral)),
            const SizedBox(height: 12),
            TextField(
              controller: _laporCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Contoh: Tiket sudah selesai dikerjakan',
                hintStyle: GoogleFonts.inter(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter(color: AppTheme.neutral)),
          ),
          ElevatedButton(
            onPressed: _laporKeAdmin,
            child: Text('Kirim Laporan', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'closed': return 'Closed';
      case 'rejected': return 'Rejected';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'open': return AppTheme.success;
      case 'in_progress': return AppTheme.primary;
      case 'closed': return AppTheme.neutral;
      case 'rejected': return AppTheme.danger;
      default: return AppTheme.neutral;
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'open': return const Color(0xFFEAF3DE);
      case 'in_progress': return const Color(0xFFE6F1FB);
      case 'closed': return const Color(0xFFF1EFE8);
      case 'rejected': return const Color(0xFFFCEBEB);
      default: return const Color(0xFFF1EFE8);
    }
  }

  String _priorityLabel(String p) {
    switch (p) {
      case 'low': return 'Low';
      case 'medium': return 'Medium';
      case 'high': return 'High';
      default: return p;
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'high': return AppTheme.danger;
      case 'medium': return AppTheme.warning;
      default: return AppTheme.success;
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _laporCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(currentUserRoleProvider);

    return roleAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Gagal memuat: $e'))),
      data: (role) {
        // helpdesk list cuma perlu di-load kalau role admin
        if (role == 'admin' && _helpdeskList.isEmpty) {
          _loadHelpdesks();
        }
        return _buildScaffold(context, role);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, String role) {
    final t = widget.ticket;
    final cardColor = Theme.of(context).colorScheme.surface;
    final isFinished = _currentStatus == 'closed';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Tiket'),
        actions: [
          if (role == 'admin')
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
              onPressed: _showDeleteDialog,
            ),
          if (role == 'helpdesk')
            TextButton.icon(
              onPressed: _showLaporDialog,
              icon: const Icon(Icons.report_outlined, color: AppTheme.warning, size: 18),
              label: Text('Lapor',
                  style: GoogleFonts.inter(
                      color: AppTheme.warning, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          if (role == 'user')
            IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Info card
                  _card(cardColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('#${t.id.substring(0, 8)}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.neutral)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusBg(_currentStatus),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(_statusLabel(_currentStatus),
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _statusColor(_currentStatus))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(t.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(t.description,
                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.neutral, height: 1.6)),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(child: _infoRow(Icons.calendar_today_outlined, t.date)),
                              Expanded(
                                  child: _infoRow(
                                      Icons.flag_outlined,
                                      role == 'user'
                                          ? _priorityLabel(t.priority)
                                          : t.priority.toUpperCase(),
                                      color: role == 'user' ? _priorityColor(t.priority) : null)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (role == 'user')
                            _infoRow(Icons.person_outline, 'Assigned: ${t.assignee}')
                          else
                            _infoRow(Icons.folder_outlined, 'Kategori: ${t.category}'),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => TrackingScreen(ticket: t))),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.secondary.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.timeline_rounded, color: AppTheme.primary, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Lihat Tracking Tiket',
                                      style: GoogleFonts.inter(
                                          fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )),
                  const SizedBox(height: 12),

                  // Lampiran — cuma tampil buat role user (placeholder, belum ada Storage)
                  if (role == 'user')
                    _card(cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lampiran',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                  color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.image_outlined, color: AppTheme.neutral, size: 32),
                            ),
                          ],
                        )),
                  if (role == 'user') const SizedBox(height: 12),

                  // Assign Helpdesk — cuma admin
                  if (role == 'admin')
                    _card(cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Assign Helpdesk',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Pilih helpdesk → status tiket otomatis jadi In Progress',
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.neutral)),
                            const SizedBox(height: 12),
                            _helpdeskList.isEmpty
                                ? Text('Belum ada helpdesk terdaftar',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.neutral))
                                : DropdownButtonFormField<String>(
                                    value: _selectedHelpdesk,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      filled: true,
                                      fillColor: cardColor,
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      prefixIcon:
                                          const Icon(Icons.person_search_outlined, color: AppTheme.neutral),
                                    ),
                                    hint: Text('Pilih helpdesk',
                                        style: GoogleFonts.inter(color: AppTheme.neutral)),
                                    items: _helpdeskList
                                        .map((h) => DropdownMenuItem<String>(
                                              value: h['id'],
                                              child: Text(h['full_name'], style: GoogleFonts.inter(fontSize: 14)),
                                            ))
                                        .toList(),
                                    onChanged: (v) => setState(() => _selectedHelpdesk = v),
                                  ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _assigning ? null : _assignTiket,
                              icon: _assigning
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.assignment_ind_outlined, size: 18),
                              label: Text(_assigning ? 'Mengassign...' : 'Assign Tiket',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        )),
                  if (role == 'admin') const SizedBox(height: 12),

                  // Finish button — cuma helpdesk
                  if (role == 'helpdesk' && !isFinished)
                    _card(cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Penyelesaian Tiket',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Klik tombol di bawah jika pekerjaan sudah selesai',
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.neutral)),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.success,
                                    padding: const EdgeInsets.symmetric(vertical: 14)),
                                onPressed: _finishing ? null : _showFinishDialog,
                                icon: _finishing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                                label: Text(_finishing ? 'Memproses...' : 'Selesai / Finish',
                                    style: GoogleFonts.inter(
                                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ),
                          ],
                        )),
                  if (role == 'helpdesk' && isFinished)
                    _card(cardColor,
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
                            const SizedBox(width: 8),
                            Text('Tiket ini telah diselesaikan',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppTheme.success, fontWeight: FontWeight.w600)),
                          ],
                        )),
                  if (role == 'helpdesk') const SizedBox(height: 12),

                  // Komentar — semua role
                  _card(cardColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Aktivitas', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          if (_loadingComments)
                            const Center(child: CircularProgressIndicator())
                          else if (_comments.isEmpty)
                            Center(
                                child: Text('Belum ada komentar',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.neutral)))
                          else
                            ..._comments.map((c) => _commentBubble(c)),
                        ],
                      )),
                ],
              ),
            ),
          ),

          // Input komentar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: role == 'user' ? 'Tulis komentar...' : 'Balas ke user...',
                        hintStyle: GoogleFonts.inter(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFFD3D1C7))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFFD3D1C7))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sending ? null : _sendComment,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _sending ? AppTheme.neutral : AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Color cardColor, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? AppTheme.neutral),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: color ?? AppTheme.neutral))),
      ],
    );
  }

  Widget _commentBubble(Comment c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: c.isHelpdesk ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (c.isHelpdesk) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.secondary,
              child: Text('HD',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: c.isHelpdesk ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.isHelpdesk ? AppTheme.surface : AppTheme.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(c.isHelpdesk ? 4 : 16),
                      bottomRight: Radius.circular(c.isHelpdesk ? 16 : 4),
                    ),
                  ),
                  child: Text(c.message,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: c.isHelpdesk ? AppTheme.primary : Colors.white)),
                ),
                const SizedBox(height: 3),
                Text(c.time, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.neutral)),
              ],
            ),
          ),
          if (!c.isHelpdesk) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.neutral,
              child: Text(_userInitial,
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}