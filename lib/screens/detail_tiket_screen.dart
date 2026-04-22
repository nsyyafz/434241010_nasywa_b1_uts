import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late List<Comment> _comments;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.ticket.comments);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open': return AppTheme.success;
      case 'In Progress': return AppTheme.primary;
      case 'Pending': return AppTheme.warning;
      case 'Closed': return AppTheme.neutral;
      case 'Rejected': return AppTheme.danger;
      default: return AppTheme.neutral;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Open': return const Color(0xFFEAF3DE);
      case 'In Progress': return const Color(0xFFE6F1FB);
      case 'Pending': return const Color(0xFFFAEEDA);
      case 'Closed': return const Color(0xFFF1EFE8);
      case 'Rejected': return const Color(0xFFFCEBEB);
      default: return const Color(0xFFF1EFE8);
    }
  }

  void _sendComment() {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() {
      _comments.add(Comment(
        author: 'Nasywa',
        message: _commentCtrl.text.trim(),
        time: TimeOfDay.now().format(context),
        isHelpdesk: false,
      ));
      _commentCtrl.clear();
    });
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
                            Text('#${t.id}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.neutral)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusBg(t.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(t.status,
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                                      color: _statusColor(t.status))),
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
                            Expanded(child: _infoRow(Icons.flag_outlined, t.priority,
                                color: t.priority == 'High' ? AppTheme.danger
                                    : t.priority == 'Medium' ? AppTheme.warning : AppTheme.success)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _infoRow(Icons.person_outline, 'Assigned: ${t.assignee}'),
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
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                                        color: AppTheme.primary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Attachment
                  _card(cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lampiran', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.image_outlined, color: AppTheme.neutral, size: 32),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Komentar
                  _card(cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aktivitas', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        if (_comments.isEmpty)
                          Center(child: Text('Belum ada komentar',
                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.neutral)))
                        else
                          ..._comments.map((c) => _commentBubble(c)),
                      ],
                    ),
                  ),
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
                        hintText: 'Tulis komentar...',
                        hintStyle: GoogleFonts.inter(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFFD3D1C7))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFFD3D1C7))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendComment,
                    child: Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
        Flexible(child: Text(text,
            style: GoogleFonts.inter(fontSize: 12, color: color ?? AppTheme.neutral))),
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
              child: Text('HD', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
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
                      style: GoogleFonts.inter(fontSize: 13,
                          color: c.isHelpdesk ? AppTheme.primary : Colors.white)),
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
              child: Text('NA', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}