import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/ticket_model.dart';
import '../../theme/app_theme.dart';

class DetailTiketHelpdeskScreen extends StatefulWidget {
  final Ticket ticket;
  const DetailTiketHelpdeskScreen({super.key, required this.ticket});

  @override
  State<DetailTiketHelpdeskScreen> createState() =>
      _DetailTiketHelpdeskScreenState();
}

class _DetailTiketHelpdeskScreenState
    extends State<DetailTiketHelpdeskScreen> {
  final _commentCtrl = TextEditingController();
  final _laporCtrl = TextEditingController();
  final _supabase = Supabase.instance.client;
  List<Comment> _comments = [];
  bool _loadingComments = true;
  bool _sending = false;
  bool _finishing = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket.status;
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final res = await _supabase
          .from('comments')
          .select('*, users(full_name, role)')
          .eq('ticket_id', widget.ticket.id)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _comments = (res as List).map((e) => Comment.fromJson(e)).toList();
          _loadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _finishTiket() async {
    setState(() => _finishing = true);
    try {
      await _supabase
          .from('tickets')
          .update({'status': 'closed'})
          .eq('id', widget.ticket.id);

      // Notifikasi ke user
      await _supabase.from('notifications').insert({
        'user_id': widget.ticket.userId,
        'title': 'Tiket selesai dikerjakan',
        'message': 'Tiket "${widget.ticket.title}" telah diselesaikan oleh helpdesk',
        'type': 'closed',
        'ticket_id': widget.ticket.id,
      });

      if (mounted) {
        setState(() {
          _currentStatus = 'closed';
          _finishing = false;
        });
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

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Selesaikan Tiket',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Tandai tiket "${widget.ticket.title}" sebagai selesai? User akan mendapat notifikasi.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppTheme.neutral)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success),
            onPressed: () {
              Navigator.pop(context);
              _finishTiket();
            },
            child: Text('Selesaikan',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    final message = _commentCtrl.text.trim();
    _commentCtrl.clear();

    setState(() => _sending = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('comments').insert({
        'ticket_id': widget.ticket.id,
        'user_id': userId,
        'message': message,
      });

      await _supabase.from('notifications').insert({
        'user_id': widget.ticket.userId,
        'title': 'Komentar baru dari Helpdesk',
        'message': 'Helpdesk membalas tiket "${widget.ticket.title}"',
        'type': 'comment',
        'ticket_id': widget.ticket.id,
      });

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
      final admins = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'admin');

      final userId = _supabase.auth.currentUser!.id;
      final message = '[LAPORAN HELPDESK] ${_laporCtrl.text.trim()}';

      await _supabase.from('comments').insert({
        'ticket_id': widget.ticket.id,
        'user_id': userId,
        'message': message,
      });

      for (final admin in admins) {
        await _supabase.from('notifications').insert({
          'user_id': admin['id'],
          'title': 'Laporan dari Helpdesk',
          'message': 'Helpdesk melaporkan tiket "${widget.ticket.title}"',
          'type': 'info',
          'ticket_id': widget.ticket.id,
        });
      }

      if (mounted) {
        _laporCtrl.clear();
        Navigator.pop(context);
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

  void _showLaporDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Lapor ke Admin',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tulis laporan yang akan dikirim ke admin:',
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppTheme.neutral)),
            const SizedBox(height: 12),
            TextField(
              controller: _laporCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Contoh: Tiket sudah selesai dikerjakan',
                hintStyle: GoogleFonts.inter(fontSize: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppTheme.neutral)),
          ),
          ElevatedButton(
            onPressed: _laporKeAdmin,
            child: Text('Kirim Laporan',
                style: GoogleFonts.inter(color: Colors.white)),
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

  @override
  void dispose() {
    _commentCtrl.dispose();
    _laporCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          TextButton.icon(
            onPressed: _showLaporDialog,
            icon: const Icon(Icons.report_outlined,
                color: AppTheme.warning, size: 18),
            label: Text('Lapor',
                style: GoogleFonts.inter(
                    color: AppTheme.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
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
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: AppTheme.neutral)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
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
                          Text(t.title,
                              style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(t.description,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.neutral,
                                  height: 1.6)),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                  child: _infoRow(
                                      Icons.calendar_today_outlined, t.date)),
                              Expanded(
                                  child: _infoRow(Icons.flag_outlined,
                                      t.priority.toUpperCase())),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _infoRow(Icons.folder_outlined,
                              'Kategori: ${t.category}'),
                        ],
                      )),
                  const SizedBox(height: 12),

                  // Tombol Finish — hanya muncul kalau belum closed
                  if (!isFinished)
                    _card(cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Penyelesaian Tiket',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              'Klik tombol di bawah jika pekerjaan sudah selesai',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppTheme.neutral),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.success,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                onPressed: _finishing ? null : _showFinishDialog,
                                icon: _finishing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Icon(Icons.check_circle_outline_rounded,
                                        size: 20),
                                label: Text(
                                    _finishing
                                        ? 'Memproses...'
                                        : 'Selesai / Finish',
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ),
                            ),
                          ],
                        )),

                  if (isFinished)
                    _card(cardColor,
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppTheme.success, size: 20),
                            const SizedBox(width: 8),
                            Text('Tiket ini telah diselesaikan',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w600)),
                          ],
                        )),

                  const SizedBox(height: 12),

                  // Komentar
                  _card(cardColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Aktivitas',
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          if (_loadingComments)
                            const Center(child: CircularProgressIndicator())
                          else if (_comments.isEmpty)
                            Center(
                                child: Text('Belum ada komentar',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppTheme.neutral)))
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: 'Balas ke user...',
                        hintStyle: GoogleFonts.inter(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                const BorderSide(color: Color(0xFFD3D1C7))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                const BorderSide(color: Color(0xFFD3D1C7))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                                color: AppTheme.primary, width: 1.5)),
                        filled: true,
                        fillColor:
                            Theme.of(context).scaffoldBackgroundColor,
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
                        color: _sending
                            ? AppTheme.neutral
                            : AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
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
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
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
        Flexible(
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 12, color: color ?? AppTheme.neutral))),
      ],
    );
  }

  Widget _commentBubble(Comment c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            c.isHelpdesk ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (c.isHelpdesk) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.secondary,
              child: Text('HD',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: c.isHelpdesk
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        c.isHelpdesk ? AppTheme.surface : AppTheme.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(c.isHelpdesk ? 4 : 16),
                      bottomRight:
                          Radius.circular(c.isHelpdesk ? 16 : 4),
                    ),
                  ),
                  child: Text(c.message,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: c.isHelpdesk
                              ? AppTheme.primary
                              : Colors.white)),
                ),
                const SizedBox(height: 3),
                Text(c.time,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppTheme.neutral)),
              ],
            ),
          ),
          if (!c.isHelpdesk) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.neutral,
              child: Text('U',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}