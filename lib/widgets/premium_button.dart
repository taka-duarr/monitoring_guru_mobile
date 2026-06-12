import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: (_) {
        if (!isDisabled) {
          setState(() => _scale = 0.97);
        }
      },
      onTapUp: (_) {
        if (!isDisabled) {
          setState(() => _scale = 1.0);
        }
      },
      onTapCancel: () {
        if (!isDisabled) {
          setState(() => _scale = 1.0);
        }
      },
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: isDisabled
                ? null
                : LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                        : [Colors.indigo.shade600, Colors.purple.shade500],
                  ),
            color: isDisabled ? theme.disabledColor.withValues(alpha: 0.12) : null,
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF6366F1) : Colors.indigo.shade600).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? theme.disabledColor : Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
