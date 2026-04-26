import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GradientBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;
  final Color? primaryColor;
  final bool hasCenterGap;
  final double centerGapWidth;

  const GradientBottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.primaryColor,
    this.hasCenterGap = false,
    this.centerGapWidth = 70,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? const Color(0xFF17FF45);
    final systemBottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomInset = systemBottomInset > 0 ? 8.0 : 6.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withAlpha(26), width: 1.1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: const [Color(0xFF0F1116), Color(0xFF1A1C23)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 28,
            offset: const Offset(0, -2),
          ),
          BoxShadow(
            color: primary.withAlpha(36),
            blurRadius: 18,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 6, 12, bottomInset),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _buildItems(primary),
        ),
      ),
    );
  }

  List<Widget> _buildItems(Color primary) {
    final widgets = <Widget>[];
    final insertGapAt = (items.length / 2).floor();

    for (var index = 0; index < items.length; index++) {
      if (hasCenterGap && index == insertGapAt) {
        widgets.add(SizedBox(width: centerGapWidth));
      }

      final item = items[index];
      final isSelected = index == currentIndex;

      widgets.add(
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onTap(index),
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color:
                      isSelected ? primary.withAlpha(18) : Colors.transparent,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconTheme(
                      data: IconThemeData(
                        color: isSelected ? primary : Colors.white,
                        size: isSelected ? 22 : 20,
                      ),
                      child: isSelected ? item.activeIcon : item.icon,
                    ),
                    const SizedBox(height: 1),
                    if (item.label != null)
                      Text(
                        item.label!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? primary : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}
