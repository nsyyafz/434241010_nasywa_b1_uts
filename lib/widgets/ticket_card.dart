import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ticket_model.dart';
import '../theme/app_theme.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const TicketCard({super.key, required this.ticket, required this.onTap});

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, // ← diganti
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
                Text('#${ticket.id}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.neutral)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusBg(ticket.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(ticket.status,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(ticket.status))),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(ticket.title,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
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
                  child: Text('NA',
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