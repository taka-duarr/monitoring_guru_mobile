import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────────────────────────
class T {
  // Background & Surface
  static const bg      = Color(0xFFF0F4FF); // very light blue tint
  static const card    = Color(0xFFFFFFFF);
  static const card2   = Color(0xFFEEF2FF);

  // Borders & Dividers
  static const border  = Color(0xFFD6E0FF);
  static const border2 = Color(0xFFEEF2FF);

  // Text
  static const ink     = Color(0xFF1A3A8F); // SMK Negeri 2 Surabaya blue
  static const inkDark = Color(0xFF0F2360); // darker shade for headings
  static const sub     = Color(0xFF4B5F9E); // blue-tinted sub text
  static const muted   = Color(0xFF8E9CC4); // blue-tinted muted
  static const onInk   = Color(0xFFFFFFFF);

  // Status
  static const amber   = Color(0xFFF59E0B);
  static const amberBg = Color(0xFFFFFBEB);
  static const amberBr = Color(0xFFFDE68A);
  static const green   = Color(0xFF16A34A);
  static const greenBg = Color(0xFFF0FDF4);
  static const greenBr = Color(0xFFBBF7D0);
  static const red     = Color(0xFFDC2626);
  static const redBg   = Color(0xFFFEF2F2);
  static const redBr   = Color(0xFFFECACA);
  static const blue    = Color(0xFF2563EB);
  static const blueBg  = Color(0xFFEFF6FF);
  static const blueBr  = Color(0xFFBFDBFE);

  // Utility
  static BorderRadius r8  = BorderRadius.circular(8);
  static BorderRadius r12 = BorderRadius.circular(12);
  static BorderRadius r16 = BorderRadius.circular(16);
  static BorderRadius r20 = BorderRadius.circular(20);
  static BorderRadius r99 = BorderRadius.circular(99);

  static List<BoxShadow> shadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4)),
  ];
}

// ─────────────────────────────────────────────────────────────────
//  Text Styles
// ─────────────────────────────────────────────────────────────────
class TS {
  static TextStyle h1({Color? color}) => GoogleFonts.outfit(
      fontSize: 26, fontWeight: FontWeight.w800, color: color ?? T.ink, letterSpacing: -0.5);

  static TextStyle h2({Color? color}) => GoogleFonts.outfit(
      fontSize: 20, fontWeight: FontWeight.w800, color: color ?? T.ink, letterSpacing: -0.3);

  static TextStyle h3({Color? color}) => GoogleFonts.outfit(
      fontSize: 16, fontWeight: FontWeight.w700, color: color ?? T.ink);

  static TextStyle body({Color? color}) => GoogleFonts.inter(
      fontSize: 14, color: color ?? T.sub, height: 1.5);

  static TextStyle bodyBold({Color? color}) => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w700, color: color ?? T.ink);

  static TextStyle small({Color? color}) => GoogleFonts.inter(
      fontSize: 12, color: color ?? T.muted);

  static TextStyle smallBold({Color? color}) => GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w700, color: color ?? T.sub);

  static TextStyle label({Color? color}) => GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w700,
      color: color ?? T.muted, letterSpacing: 1.0);

  static TextStyle mono({Color? color, double size = 24}) => GoogleFonts.inter(
      fontSize: size, fontWeight: FontWeight.w900,
      color: color ?? T.ink, letterSpacing: -1.5);
}

// ─────────────────────────────────────────────────────────────────
//  Shared Widget Helpers
// ─────────────────────────────────────────────────────────────────

/// Minimal card decoration
BoxDecoration cardDeco({Color? bg, Color? border, BorderRadius? radius}) => BoxDecoration(
      color: bg ?? T.card,
      borderRadius: radius ?? T.r16,
      border: Border.all(color: border ?? T.border),
      boxShadow: T.shadow,
    );

/// Label chip / badge
Widget tBadge(String text, {Color? bg, Color? fg, Color? border}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? T.card2,
        borderRadius: T.r99,
        border: Border.all(color: border ?? T.border),
      ),
      child: Text(text, style: TS.small(color: fg ?? T.sub).copyWith(fontWeight: FontWeight.w700)),
    );

/// Time badge
Widget timeBadge(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: T.card2, borderRadius: T.r99, border: Border.all(color: T.border)),
      child: Text(text, style: TS.smallBold()),
    );

/// Section header
Widget sectionHead(String label, {Color? dotColor}) => Row(
      children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(color: dotColor ?? T.muted, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label.toUpperCase(), style: TS.label()),
      ],
    );

/// Thin page divider
Widget divider({double? indent}) =>
    Divider(color: T.border, thickness: 1, indent: indent, endIndent: indent);

/// Minimalist input decoration
InputDecoration minInput({required String label, String? hint, Widget? prefix}) => InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TS.small(color: T.muted),
      prefixIcon: prefix,
      filled: true,
      fillColor: T.card2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: T.r12, borderSide: BorderSide(color: T.border)),
      enabledBorder: OutlineInputBorder(borderRadius: T.r12, borderSide: BorderSide(color: T.border)),
      disabledBorder: OutlineInputBorder(borderRadius: T.r12, borderSide: BorderSide(color: T.border2)),
      focusedBorder: OutlineInputBorder(borderRadius: T.r12, borderSide: const BorderSide(color: T.ink, width: 1.5)),
    );

/// Primary button style
ButtonStyle primaryBtn({Color? bg}) => ElevatedButton.styleFrom(
      backgroundColor: bg ?? T.ink,
      foregroundColor: T.onInk,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: T.r12),
      padding: const EdgeInsets.symmetric(vertical: 15),
    );

/// Secondary ghost button style
ButtonStyle ghostBtn() => ElevatedButton.styleFrom(
      backgroundColor: T.card2,
      foregroundColor: T.sub,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: T.r12, side: BorderSide(color: T.border)),
      padding: const EdgeInsets.symmetric(vertical: 15),
    );

/// App theme (force light)
ThemeData appLightTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: T.bg,
      cardColor: T.card,
      primaryColor: T.ink,
      colorScheme: ColorScheme.fromSeed(
        seedColor: T.ink,
        brightness: Brightness.light,
        surface: T.card,
        onSurface: T.inkDark,
        primary: T.ink,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: T.inkDark),
        bodyMedium: GoogleFonts.inter(color: T.sub),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: T.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: T.inkDark),
        iconTheme: const IconThemeData(color: T.ink),
      ),
      dividerColor: T.border,
    );
