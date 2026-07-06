import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class BottomNavAdmin extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavAdmin({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _navItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard'),
              _navItem(1, Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Tiket'),
              _navItem(2, Icons.person_rounded, Icons.person_outline, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isActive ? active : inactive,
                  color: isActive ? AppTheme.primary : AppTheme.neutral,
                  size: 22),
              const SizedBox(height: 2),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isActive ? AppTheme.primary : AppTheme.neutral,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}