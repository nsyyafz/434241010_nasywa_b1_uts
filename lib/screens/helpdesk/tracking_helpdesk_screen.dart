import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/ticket_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/progress_ticket_bar.dart';
import 'detail_tiket_helpdesk_screen.dart';

class TrackingHelpdeskScreen extends StatelessWidget {
  final Ticket ticket;
  const TrackingHelpdeskScreen({super.key, required this.ticket});

  List<Map<String, dynamic>> _getSteps() {
    final allSteps = [
      {'label': 'Tiket Dibuat', 'sub': 'Tiket dikirim oleh user', 'status': 'done'},
      {'label': 'Tiket Diterima', 'sub': 'Tiket diterima sistem', 'status': 'done'},
      {'label': 'Sedang Diproses', 'sub': 'Ditugaskan ke kamu', 'status': 'active'},
      {'label': 'Selesai', 'sub': 'Menunggu penyelesaian...', 'status': 'pending'},
    ];

    switch (ticket.status) {
      case 'open':
        allSteps[0]['status'] = 'done';
        allSteps[1]['status'] = 'pending';
        allSteps[2]['status'] = 'pending';
        allSteps[3]['status'] = 'pending';
        break;
      case 'in_progress':
        allSteps[0]['status'] = 'done';
        allSteps[1]['status'] = 'done';
        allSteps[2]['status'] = 'active';
        allSteps[3]['status'] = 'pending';
        break;
      case 'closed':
        allSteps[0]['status'] = 'done';
        allSteps[1]['status'] = 'done';
        allSteps[2]['status'] = 'done';
        allSteps[3]['status'] = 'done';
        allSteps[3]['sub'] = 'Tiket telah diselesaikan';
        break;
      case 'rejected':
        allSteps[0]['status'] = 'done';
        allSteps[1]['status'] = 'done';
        allSteps[2]['status'] = 'done';
        allSteps[3]['label'] = 'Ditolak';
        allSteps[3]['sub'] = 'Tiket tidak dapat diproses';
        allSteps[3]['status'] = 'rejected';
        break;
    }
    return allSteps;
  }

  int _getProgressPercent() {
    final steps = _getSteps();
    final doneCount = steps.where((s) => s['status'] == 'done').length;
    final hasActive = steps.any((s) => s['status'] == 'active');
    final hasRejected = steps.any((s) => s['status'] == 'rejected');
    if (hasRejected) return 100;
    return ((doneCount * 25) + (hasActive ? 25 : 0)).clamp(0, 100);
  }

  String _getProgressLabel() {
    if (ticket.status == 'rejected') return 'Ditolak';
    if (ticket.status == 'closed') return 'Selesai';
    return 'Sedang Diproses';
  }

  Color _getProgressColor() {
    if (ticket.status == 'rejected') return AppTheme.danger;
    if (ticket.status == 'closed') return AppTheme.success;
    return AppTheme.primary;
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
      case 'closed': return AppTheme.success;
      case 'rejected': return AppTheme.danger;
      default: return AppTheme.neutral;
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'open': return const Color(0xFFEAF3DE);
      case 'in_progress': return const Color(0xFFE6F1FB);
      case 'closed': return const Color(0xFFEAF3DE);
      case 'rejected': return const Color(0xFFFCEBEB);
      default: return const Color(0xFFF1EFE8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tracking Tiket'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('#${ticket.id.substring(0, 8)}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.neutral)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusBg(ticket.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_statusLabel(ticket.status),
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(ticket.status))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(ticket.title,
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Kategori: ${ticket.category}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.neutral)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== BARU: Progress bar persentase =====
            Container(
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
              child: ProgressTicketBar(
                percent: _getProgressPercent(),
                color: _getProgressColor(),
                label: _getProgressLabel(),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progres Tiket',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  ...List.generate(steps.length, (i) {
                    final step = steps[i];
                    final isLast = i == steps.length - 1;
                    return _timelineItem(
                      label: step['label'] as String,
                      sub: step['sub'] as String,
                      stepStatus: step['status'] as String,
                      isLast: isLast,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        DetailTiketHelpdeskScreen(ticket: ticket)),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: Text('Lihat Detail Tiket',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineItem({
    required String label,
    required String sub,
    required String stepStatus,
    required bool isLast,
  }) {
    Color circleColor;
    Color lineColor;
    Widget circleChild;
    bool isDashed = false;

    switch (stepStatus) {
      case 'done':
        circleColor = AppTheme.primary;
        lineColor = AppTheme.primary;
        circleChild = const Icon(Icons.check_rounded, color: Colors.white, size: 14);
        break;
      case 'active':
        circleColor = AppTheme.primary;
        lineColor = const Color(0xFFD3D1C7);
        circleChild = Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle));
        isDashed = true;
        break;
      case 'rejected':
        circleColor = AppTheme.danger;
        lineColor = const Color(0xFFD3D1C7);
        circleChild = const Icon(Icons.close_rounded, color: Colors.white, size: 14);
        break;
      default:
        circleColor = const Color(0xFFD3D1C7);
        lineColor = const Color(0xFFD3D1C7);
        circleChild = const SizedBox();
        isDashed = true;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            stepStatus == 'active'
                ? Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withOpacity(0.15)),
                    child: Center(
                        child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: circleColor),
                            child: Center(child: circleChild))))
                : Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: circleColor),
                    child: Center(child: circleChild)),
            if (!isLast)
              CustomPaint(
                  size: const Size(2, 50),
                  painter: _LinePainter(
                      color: lineColor, dashed: isDashed)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: stepStatus == 'pending'
                            ? AppTheme.neutral
                            : stepStatus == 'rejected'
                                ? AppTheme.danger
                                : const Color(0xFF2C2C2A))),
                const SizedBox(height: 3),
                Text(sub,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.neutral)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final bool dashed;
  const _LinePainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    if (!dashed) {
      canvas.drawLine(Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height), paint);
    } else {
      double y = 0;
      const dashH = 5.0;
      const gapH = 4.0;
      while (y < size.height) {
        canvas.drawLine(Offset(size.width / 2, y),
            Offset(size.width / 2, y + dashH), paint);
        y += dashH + gapH;
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.color != color || old.dashed != dashed;
}