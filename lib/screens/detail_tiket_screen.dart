import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';
import '../theme/app_theme.dart';
import 'tracking_screen.dart';

class DetailTiketScreen extends StatefulWidget {
  final Ticket ticket;
  const DetailTiketScreen({super.key, required this.ticket});

  @override
  State<DetailTiketScreen> createState() => _DetailTiketScreenState();
}

class _DetailTiketScreenState extends State<DetailTiketScreen> {
  final _commentCtrl = TextEditingController();
  final _supabase = Supabase.instance.client;
  List<Comment> _comments = [];
  bool _loadingComments = true;
  bool _sending = false;
  String _userName = '';
  String _userInitial = 'NA';

  @override
  void initState() {
    super.initState();
    _loadComments();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final res = await _supabase
          .from('users')
          .select('full_name')
          .eq('id', userId)
          .single();
      if (mounted) {
        final name = res['full_name'] ?? '';
        setState(() {
          _userName = name;
          _userInitial = name.isNotEmpty
              ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
              : 'NA';
        });
      }
    } catch (_) {}
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

  Color _statusColor(String status) {
    switch (status) {
      case 'open': return AppTheme.success;
      case 'in_progress': return AppTheme.primary;
      case 'closed': return AppTheme.neutral;
      case 'rejected': return AppTheme.danger;
      default: return AppTheme.neutral;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'open': return const Color(0xFFEAF3DE);
      case 'in_progress': return const Color(0xFFE6F1FB);
      case 'closed': return const Color(0xFFF1EFE8);
      case 'rejected': return const Color(0xFFFCEBEB);
      default: return const Color(0xFFF1EFE8);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'closed': return 'Closed';
      case 'rejected': return 'Rejected';
      default: return status;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'low': return 'Low';
      case 'medium': return 'Medium';
      case 'high': return 'High';
      default: return priority;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high': return AppTheme.danger;
      case 'medium': return AppTheme.warning;
      default: return AppTheme.success;
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
              icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
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
                                  color: _statusBg(t.status),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(_statusLabel(t.status),
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _statusColor(t.status))),
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
                                  child: _infoRow(
                                      Icons.flag_outlined,
                                      _priorityLabel(t.priority),
                                      color: _priorityColor(t.priority))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _infoRow(Icons.person_outline,
                              'Assigned: ${t.assignee}'),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        TrackingScreen(ticket: t))),
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

                  // Attachment
                  _card(cardColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lampiran',
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.image_outlined,
                                color: AppTheme.neutral, size: 32),
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
                        hintText: 'Tulis komentar...',
                        hintStyle: GoogleFonts.inter(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                                color: Color(0xFFD3D1C7))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                                color: Color(0xFFD3D1C7))),
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
                                  color: Colors.white, strokeWidth: 2),
                            )
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
              child: Text(_userInitial,
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