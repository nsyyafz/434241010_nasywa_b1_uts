import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ticket_model.dart';
import '../theme/app_theme.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;
  final String? userInitial;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
    this.userInitial,
  });

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${ticket.id.length > 8 ? ticket.id.substring(0, 8) : ticket.id}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.neutral)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
            const SizedBox(height: 6),
            Text(ticket.title,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(ticket.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.neutral)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ticket.date,
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.neutral)),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primary,
                  child: Text(userInitial ?? 'NA',
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}