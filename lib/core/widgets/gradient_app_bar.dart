import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color? primaryColor;
  final Color? secondaryColor;

  const GradientAppBar({
    required this.title,
    this.actions,
    this.primaryColor,
    this.secondaryColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? Theme.of(context).colorScheme.primary;
    final secondary = secondaryColor ?? const Color(0xFF0E1116);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withAlpha(26), width: 1.1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [secondary.withAlpha(250), const Color(0xFF1A1D23)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(115),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: primary.withAlpha(50),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 20,
                right: 20,
                top: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: LinearGradient(
                      colors: [
                        primary.withAlpha(20),
                        primary.withAlpha(150),
                        primary.withAlpha(20),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (actions != null) ...[
                      const SizedBox(width: 14),
                      IconTheme(
                        data: IconThemeData(color: Colors.white, size: 25),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(90);
}
