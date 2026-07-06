import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatItem {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  StatItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
}

class StatGrid extends StatelessWidget {
  final List<StatItem> items;
  final int crossAxisCount;

  const StatGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.6,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 18, color: item.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${item.count}',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Text(item.label,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.75))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}