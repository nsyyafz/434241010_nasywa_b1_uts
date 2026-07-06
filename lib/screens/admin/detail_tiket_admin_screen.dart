import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/ticket_model.dart';
import '../../theme/app_theme.dart';
import 'tracking_admin_screen.dart';
import 'list_tiket_admin_screen.dart';

class DetailTiketAdminScreen extends StatefulWidget {
  final Ticket ticket;
  const DetailTiketAdminScreen({super.key, required this.ticket});

  @override
  State<DetailTiketAdminScreen> createState() => _DetailTiketAdminScreenState();
}

class _DetailTiketAdminScreenState extends State<DetailTiketAdminScreen> {
  final _commentCtrl = TextEditingController();
  final _supabase = Supabase.instance.client;

  List<Comment> _comments = [];
  List<Map<String, dynamic>> _helpdeskList = [];
  String? _selectedHelpdesk;

  bool _loadingComments = true;
  bool _sending = false;
  bool _assigning = false;

  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket.status;
    _loadComments();
    _loadHelpdesks();
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

  Future<void> _loadHelpdesks() async {
    try {
      final res = await _supabase
          .from('users')
          .select('id, full_name')
          .eq('role', 'helpdesk');

      if (mounted) {
        setState(() {
          _helpdeskList = List<Map<String, dynamic>>.from(res);
        });
      }
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
      // Assign ke helpdesk + otomatis set status in_progress
      await _supabase.from('tickets').update({
        'assigned_to': _selectedHelpdesk,
        'status': 'in_progress',
      }).eq('id', widget.ticket.id);

      final helpdeskName = _helpdeskList
          .firstWhere((h) => h['id'] == _selectedHelpdesk)['full_name'];

      // Notifikasi ke helpdesk
      await _supabase.from('notifications').insert({
        'user_id': _selectedHelpdesk,
        'title': 'Tiket baru ditugaskan',
        'message': 'Kamu ditugaskan untuk menangani tiket "${widget.ticket.title}"',
        'type': 'info',
        'ticket_id': widget.ticket.id,
      });

      // Notifikasi ke user bahwa tiketnya sedang diproses
      await _supabase.from('notifications').insert({
        'user_id': widget.ticket.userId,
        'title': 'Tiket sedang diproses',
        'message': 'Tiket "${widget.ticket.title}" sedang ditangani oleh helpdesk',
        'type': 'status_update',
        'ticket_id': widget.ticket.id,
      });

      if (mounted) {
        setState(() {
          _assigning = false;
          _currentStatus = 'in_progress';
        });
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
        'title': 'Komentar baru',
        'message': 'Admin membalas tiket "${widget.ticket.title}"',
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

  Future<void> _deleteTiket() async {
    try {
      await _supabase.from('comments').delete().eq('ticket_id', widget.ticket.id);
      await _supabase.from('notifications').delete().eq('ticket_id', widget.ticket.id);
      await _supabase.from('tickets').delete().eq('id', widget.ticket.id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ListTiketAdminScreen()),
        );
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
        title: Text('Hapus Tiket',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.danger),
            onPressed: _showDeleteDialog,
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
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        TrackingAdminScreen(ticket: t))),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        AppTheme.secondary.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.timeline_rounded,
                                      color: AppTheme.primary, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Lihat Tracking Tiket',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )),
                  const SizedBox(height: 12),

                  // Assign Helpdesk
                  _card(cardColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assign Helpdesk',
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            'Pilih helpdesk → status tiket otomatis jadi In Progress',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppTheme.neutral),
                          ),
                          const SizedBox(height: 12),
                          _helpdeskList.isEmpty
                              ? Text('Belum ada helpdesk terdaftar',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: AppTheme.neutral))
                              : DropdownButtonFormField<String>(
                                  value: _selectedHelpdesk,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFD3D1C7))),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFD3D1C7))),
                                    filled: true,
                                    fillColor: cardColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    prefixIcon: const Icon(
                                        Icons.person_search_outlined,
                                        color: AppTheme.neutral),
                                  ),
                                  hint: Text('Pilih helpdesk',
                                      style: GoogleFonts.inter(
                                          color: AppTheme.neutral)),
                                  items: _helpdeskList
                                      .map((h) => DropdownMenuItem<String>(
                                            value: h['id'],
                                            child: Text(h['full_name'],
                                                style: GoogleFonts.inter(
                                                    fontSize: 14)),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedHelpdesk = v),
                                ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _assigning ? null : _assignTiket,
                            icon: _assigning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.assignment_ind_outlined,
                                    size: 18),
                            label: Text(
                                _assigning ? 'Mengassign...' : 'Assign Tiket',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        hintText: 'Tulis balasan...',
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
                          fontSize: 13,
                          color: c.isHelpdesk ? AppTheme.primary : Colors.white)),
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