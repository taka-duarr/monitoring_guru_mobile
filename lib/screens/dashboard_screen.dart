import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'riwayat_mapel_screen.dart';
import 'absen_murid_screen.dart';
import 'scanner_screen.dart';

// ─────────────────────────────────────────────────────────────
// COLOUR PALETTE
// ─────────────────────────────────────────────────────────────
class _Palette {
  static const Color bg = Color(0xFFF4F6FB);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color teal = Color(0xFF0D9488);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMid = Color(0xFF64748B);
  static const Color textLight = Color(0xFFCBD5E1);
  static const Color border = Color(0xFFE2E8F0);
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
}

// ─────────────────────────────────────────────────────────────
// SHIMMER WIDGET
// ─────────────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value + 1, 0),
              colors: const [
                _Palette.shimmerBase,
                _Palette.shimmerHighlight,
                _Palette.shimmerBase,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SKELETON LOADING CARD
// ─────────────────────────────────────────────────────────────
class _JadwalSkeletonCard extends StatelessWidget {
  const _JadwalSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _ShimmerBox(width: 48, height: 48, radius: 14),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ShimmerBox(width: 160, height: 14),
                  SizedBox(height: 8),
                  _ShimmerBox(width: 100, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              _ShimmerBox(width: 80, height: 12),
              SizedBox(width: 12),
              _ShimmerBox(width: 80, height: 12),
              SizedBox(width: 12),
              _ShimmerBox(width: 60, height: 12),
            ],
          ),
          const SizedBox(height: 16),
          const _ShimmerBox(width: double.infinity, height: 44, radius: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE ILLUSTRATION
// ─────────────────────────────────────────────────────────────
class _EmptyStatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.44,
      Paint()..color = const Color(0xFFEEF2FF),
    );

    final calRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + size.height * 0.02),
        width: size.width * 0.54,
        height: size.height * 0.48,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(calRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      calRect,
      Paint()
        ..color = const Color(0xFFE0E7FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final headerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        cx - size.width * 0.27,
        cy - size.height * 0.21,
        size.width * 0.54,
        size.height * 0.13,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(headerRect, Paint()..color = _Palette.primary);

    final dotPaint = Paint()..color = const Color(0xFFE0E7FF);
    final dotPaintFaded = Paint()..color = const Color(0xFFC7D2FE);
    const cols = 4;
    const rows = 3;
    final cellW = size.width * 0.1;
    final cellH = size.height * 0.09;
    final startX = cx - size.width * 0.22;
    final startY = cy - size.height * 0.02;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              startX + c * (cellW + 6),
              startY + r * (cellH + 6),
              cellW,
              cellH,
            ),
            const Radius.circular(6),
          ),
          (r + c) % 3 == 0 ? dotPaintFaded : dotPaint,
        );
      }
    }

    final xPaint = Paint()
      ..color = const Color(0xFFA5B4FC)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final xCx = cx;
    final xCy = cy + size.height * 0.22;
    canvas.drawLine(Offset(xCx - 8, xCy - 8), Offset(xCx + 8, xCy + 8), xPaint);
    canvas.drawLine(Offset(xCx + 8, xCy - 8), Offset(xCx - 8, xCy + 8), xPaint);

    canvas.drawCircle(Offset(cx - size.width * 0.38, cy - size.height * 0.28), 8,
        Paint()..color = const Color(0xFFC7D2FE));
    canvas.drawCircle(Offset(cx + size.width * 0.35, cy - size.height * 0.22), 6,
        Paint()..color = const Color(0xFFDDD6FE));
    canvas.drawCircle(Offset(cx + size.width * 0.40, cy + size.height * 0.30), 5,
        Paint()..color = const Color(0xFFC7D2FE));
    canvas.drawCircle(Offset(cx - size.width * 0.36, cy + size.height * 0.26), 7,
        Paint()..color = const Color(0xFFDDD6FE));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(painter: _EmptyStatePainter()),
            ),
            const SizedBox(height: 20),
            Text(
              'Tidak Ada Jadwal',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _Palette.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamu tidak memiliki jadwal mengajar\nuntuk hari ini. Nikmati hari liburmu! 🎉',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _Palette.textMid,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATUS CHIP
// ─────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUBJECT COLORS & ICONS
// ─────────────────────────────────────────────────────────────
const List<Color> _subjectColors = [
  Color(0xFF4F46E5),
  Color(0xFF0D9488),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF7C3AED),
  Color(0xFF2563EB),
  Color(0xFF059669),
  Color(0xFFEA580C),
];

const List<IconData> _subjectIcons = [
  Icons.calculate_rounded,
  Icons.science_rounded,
  Icons.history_edu_rounded,
  Icons.brush_rounded,
  Icons.computer_rounded,
  Icons.language_rounded,
  Icons.sports_soccer_rounded,
  Icons.music_note_rounded,
];

// ─────────────────────────────────────────────────────────────
// INFO PILL
// ─────────────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ABSEN TIME ITEM
// ─────────────────────────────────────────────────────────────
class _AbsenTimeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _AbsenTimeItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.inter(fontSize: 12, color: _Palette.textMid)),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          time,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: time == '-' ? _Palette.textLight : _Palette.textDark,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;
  final Color textColor;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.7 : 1.0,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QR BOTTOM SHEET
// ─────────────────────────────────────────────────────────────
class _QrBottomSheet extends StatelessWidget {
  final String mapelName;
  final String payload;
  final bool wasMasuk;

  const _QrBottomSheet({
    required this.mapelName,
    required this.payload,
    required this.wasMasuk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _Palette.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: wasMasuk
                    ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                    : [_Palette.primary, _Palette.secondary],
              ),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              wasMasuk ? 'QR ABSEN KELUAR' : 'QR ABSEN MASUK',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            mapelName,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _Palette.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            wasMasuk
                ? 'Tunjukkan QR ini agar Guru bisa absen KELUAR'
                : 'Tunjukkan QR ini agar Guru bisa absen MASUK',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _Palette.textMid,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _Palette.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: _Palette.border, width: 2),
            ),
            child: QrImageView(
              data: payload,
              version: QrVersions.auto,
              size: 220,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: _Palette.textDark,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: _Palette.textDark,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _Palette.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Menunggu scan dari guru...',
                style: GoogleFonts.inter(fontSize: 12, color: _Palette.textMid),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _Palette.border, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Tutup',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: _Palette.textMid,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// JADWAL CARD
// ─────────────────────────────────────────────────────────────
class _JadwalCard extends StatefulWidget {
  final Map<String, dynamic> jadwal;
  final bool isKetua;
  final VoidCallback onRefresh;

  const _JadwalCard({
    required this.jadwal,
    required this.isKetua,
    required this.onRefresh,
  });

  @override
  State<_JadwalCard> createState() => _JadwalCardState();
}

class _JadwalCardState extends State<_JadwalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _elevAnim;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _elevAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  bool get isKetua => widget.isKetua;

  void _showQrModal(
      BuildContext context, String jadwalId, String mapelName, bool wasMasuk) {
    final payload = jsonEncode({
      'type': 'absen_jadwal',
      'jadwal_id': jadwalId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    Timer? pollingTimer;
    pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final response = await ApiService.getJadwal();
        if (response['success']) {
          final updatedList = response['data'] as List;
          final currentJadwal = updatedList.firstWhere(
            (j) => j['id'].toString() == jadwalId,
            orElse: () => null,
          );
          if (currentJadwal != null) {
            final isNowMasuk = currentJadwal['absen_masuk'] != null;
            final isNowKeluar = currentJadwal['absen_keluar'] != null;
            if (!wasMasuk && isNowMasuk) {
              timer.cancel();
              if (mounted) {
                Navigator.pop(context);
                widget.onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  _snackBar('Guru berhasil absen MASUK! 🎉', _Palette.teal),
                );
              }
            } else if (wasMasuk && isNowKeluar) {
              timer.cancel();
              if (mounted) {
                Navigator.pop(context);
                widget.onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  _snackBar('Guru berhasil absen KELUAR! ✅', _Palette.primary),
                );
              }
            }
          }
        }
      } catch (_) {}
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QrBottomSheet(
        mapelName: mapelName,
        payload: payload,
        wasMasuk: wasMasuk,
      ),
    ).then((_) => pollingTimer?.cancel());
  }

  SnackBar _snackBar(String msg, Color color) {
    return SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.jadwal;
    final hasMasuk = j['absen_masuk'] != null;
    final hasKeluar = j['absen_keluar'] != null;
    final isSelesai = hasMasuk && hasKeluar;

    String statusLabel;
    Color statusColor;
    IconData statusIcon;
    if (isSelesai) {
      statusLabel = 'Selesai';
      statusColor = _Palette.teal;
      statusIcon = Icons.check_circle_rounded;
    } else if (hasMasuk) {
      statusLabel = 'Berlangsung';
      statusColor = _Palette.amber;
      statusIcon = Icons.schedule_rounded;
    } else {
      statusLabel = 'Belum Mulai';
      statusColor = _Palette.textMid;
      statusIcon = Icons.hourglass_empty_rounded;
    }

    final mapelName = j['mapel']?['name'] ?? 'Mapel';
    final colorIndex = mapelName.hashCode.abs() % _subjectColors.length;
    final subjectColor = _subjectColors[colorIndex];

    return AnimatedBuilder(
      animation: _elevAnim,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _Palette.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: subjectColor.withValues(
                    alpha: 0.08 + _elevAnim.value * 0.08),
                blurRadius: 16 + _elevAnim.value * 8,
                offset: Offset(0, 4 + _elevAnim.value * 4),
              ),
            ],
          ),
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _hoverCtrl.forward(),
        onTapUp: (_) => _hoverCtrl.reverse(),
        onTapCancel: () => _hoverCtrl.reverse(),
        onTap: !widget.isKetua
            ? () {
                if (j['mapel'] != null && j['mapel']['id'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RiwayatMapelScreen(
                        mapelId: j['mapel']['id'],
                        mapelName: j['mapel']['name'] ?? 'Mapel',
                      ),
                    ),
                  );
                }
              }
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [subjectColor, subjectColor.withValues(alpha: 0.4)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: subjectColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _subjectIcons[colorIndex],
                            color: subjectColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mapelName,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _Palette.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kelas ${j['kelas']?['name'] ?? '-'}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _Palette.textMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusChip(
                          label: statusLabel,
                          color: statusColor,
                          icon: statusIcon,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Jam + Ruang pills
                    Row(
                      children: [
                        _InfoPill(
                          icon: Icons.access_time_rounded,
                          label:
                              '${j['jam_mulai'] ?? '--:--'} – ${j['jam_selesai'] ?? '--:--'}',
                          color: _Palette.primary,
                        ),
                        const SizedBox(width: 10),
                        _InfoPill(
                          icon: Icons.meeting_room_rounded,
                          label: j['ruangan']?['name'] ?? '-',
                          color: _Palette.secondary,
                        ),
                      ],
                    ),

                    // Absen time row
                    if (hasMasuk) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _Palette.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _AbsenTimeItem(
                              icon: Icons.login_rounded,
                              label: 'Masuk',
                              time: j['absen_masuk']?['jam_masuk'] ?? '-',
                              color: _Palette.teal,
                            ),
                            Container(
                                width: 1, height: 30, color: _Palette.border),
                            _AbsenTimeItem(
                              icon: Icons.logout_rounded,
                              label: 'Keluar',
                              time: hasKeluar
                                  ? (j['absen_keluar']?['jam_keluar'] ?? '-')
                                  : '-',
                              color: hasKeluar
                                  ? _Palette.red
                                  : _Palette.textLight,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action buttons
                    ..._buildActions(context, j, hasMasuk, hasKeluar, isSelesai),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    Map<String, dynamic> j,
    bool hasMasuk,
    bool hasKeluar,
    bool isSelesai,
  ) {
    // ── KETUA KELAS
    if (isKetua) {
      if (isSelesai) {
        return [
          _ActionButton(
            label: 'Kelas Selesai',
            icon: Icons.check_circle_rounded,
            gradient: const LinearGradient(
                colors: [Color(0xFFCBD5E1), Color(0xFFE2E8F0)]),
            textColor: _Palette.textMid,
          ),
        ];
      }
      return [
        _ActionButton(
          label: hasMasuk ? 'Generate QR Keluar' : 'Generate QR Masuk',
          icon: Icons.qr_code_2_rounded,
          gradient: LinearGradient(
            colors: hasMasuk
                ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                : [_Palette.primary, _Palette.secondary],
          ),
          onTap: () => _showQrModal(
            context,
            j['id'].toString(),
            j['mapel']?['name'] ?? 'Mapel',
            hasMasuk,
          ),
        ),
      ];
    }

    // ── GURU
    if (!hasMasuk) {
      return [
        _ActionButton(
          label: 'Scan QR Masuk',
          icon: Icons.qr_code_scanner_rounded,
          gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
          onTap: () {
            Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ScannerScreen()))
                .then((_) => widget.onRefresh());
          },
        ),
      ];
    }

    return [
      Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Absen Murid',
              icon: Icons.people_alt_rounded,
              gradient: LinearGradient(
                  colors: [_Palette.primary, _Palette.primaryLight]),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AbsenMuridScreen(
                      absenMasukId: j['absen_masuk']['id'],
                      mapelName: j['mapel']?['name'] ?? 'Mapel',
                      kelasName: j['kelas']?['name'] ?? '-',
                    ),
                  ),
                ).then((_) => widget.onRefresh());
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: isSelesai
                ? const _ActionButton(
                    label: 'Selesai',
                    icon: Icons.check_circle_rounded,
                    gradient: LinearGradient(
                        colors: [Color(0xFFCBD5E1), Color(0xFFE2E8F0)]),
                    textColor: _Palette.textMid,
                  )
                : _ActionButton(
                    label: 'Scan QR Keluar',
                    icon: Icons.qr_code_scanner_rounded,
                    gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                    onTap: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ScannerScreen()))
                          .then((_) => widget.onRefresh());
                    },
                  ),
          ),
        ],
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────
// KETUA KELAS – HERO SECTION
// ─────────────────────────────────────────────────────────────
class _KetuaHeroSection extends StatefulWidget {
  final List<dynamic> jadwalList;
  final VoidCallback onRefresh;

  const _KetuaHeroSection({
    required this.jadwalList,
    required this.onRefresh,
  });

  @override
  State<_KetuaHeroSection> createState() => _KetuaHeroSectionState();
}

class _KetuaHeroSectionState extends State<_KetuaHeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeJadwal = widget.jadwalList.isNotEmpty
        ? widget.jadwalList.firstWhere(
            (j) => !(j['absen_masuk'] != null && j['absen_keluar'] != null),
            orElse: () => null,
          )
        : null;

    final hasMasuk =
        activeJadwal != null && activeJadwal['absen_masuk'] != null;
    final mapelName =
        activeJadwal != null ? (activeJadwal['mapel']?['name'] ?? 'Jadwal') : null;

    return Column(
      children: [
        if (widget.jadwalList.isNotEmpty)
          ...widget.jadwalList.map((j) => _JadwalCard(
                jadwal: j,
                isKetua: true,
                onRefresh: widget.onRefresh,
              )),
        if (activeJadwal != null) ...[
          const SizedBox(height: 8),
          _buildHeroButton(context, activeJadwal, hasMasuk, mapelName!),
        ] else if (widget.jadwalList.isEmpty)
          const _EmptyStateWidget(),
      ],
    );
  }

  Widget _buildHeroButton(
    BuildContext context,
    Map<String, dynamic> j,
    bool hasMasuk,
    String mapelName,
  ) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) =>
          Transform.scale(scale: _pulse.value, child: child),
      child: GestureDetector(
        onTap: () => _showKetuaQr(context, j, hasMasuk, mapelName),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasMasuk
                  ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                  : [_Palette.primary, _Palette.secondary],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (hasMasuk ? _Palette.amber : _Palette.primary)
                    .withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hasMasuk ? 'Generate QR\nAbsen Keluar' : 'Generate QR\nAbsen Masuk',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mapelName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Ketuk untuk membuka QR',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showKetuaQr(
    BuildContext context,
    Map<String, dynamic> j,
    bool hasMasuk,
    String mapelName,
  ) {
    final payload = jsonEncode({
      'type': 'absen_jadwal',
      'jadwal_id': j['id'].toString(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    Timer? pollingTimer;
    pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final response = await ApiService.getJadwal();
        if (response['success']) {
          final updatedList = response['data'] as List;
          final updated = updatedList.firstWhere(
            (x) => x['id'].toString() == j['id'].toString(),
            orElse: () => null,
          );
          if (updated != null) {
            final nowMasuk = updated['absen_masuk'] != null;
            final nowKeluar = updated['absen_keluar'] != null;
            if ((!hasMasuk && nowMasuk) || (hasMasuk && nowKeluar)) {
              timer.cancel();
              if (mounted) {
                Navigator.pop(context);
                widget.onRefresh();
              }
            }
          }
        }
      } catch (_) {}
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QrBottomSheet(
        mapelName: mapelName,
        payload: payload,
        wasMasuk: hasMasuk,
      ),
    ).then((_) => pollingTimer?.cancel());
  }
}

// ─────────────────────────────────────────────────────────────
// DASHBOARD SCREEN
// ─────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _jadwalList = [];
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _greetCtrl;
  late Animation<double> _greetFade;
  late Animation<Offset> _greetSlide;

  @override
  void initState() {
    super.initState();
    _greetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _greetFade = CurvedAnimation(parent: _greetCtrl, curve: Curves.easeOut);
    _greetSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _greetCtrl, curve: Curves.easeOut));
    _fetchJadwal();
  }

  @override
  void dispose() {
    _greetCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchJadwal() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await ApiService.getJadwal();
      if (response['success']) {
        setState(() {
          _jadwalList = response['data'];
          _isLoading = false;
        });
        _greetCtrl.forward(from: 0);
        return;
      }
    } catch (e) {
      debugPrint('Error fetch jadwal: $e');
    }
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
  }

  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isKetua = auth.role == 'ketuakelas';

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          _buildSliverAppBar(auth, isKetua, innerBoxScrolled),
        ],
        body: RefreshIndicator(
          onRefresh: _fetchJadwal,
          color: _Palette.primary,
          backgroundColor: Colors.white,
          child: _buildBody(isKetua),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    AuthProvider auth,
    bool isKetua,
    bool innerBoxScrolled,
  ) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      toolbarHeight: 96,
      automaticallyImplyLeading: false,
      backgroundColor: _Palette.primary,
      // Gradient + decorative circles background
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: 40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
      // Title: Dashboard (baris 1) + Greeting (baris 2) + Nama (baris 3)
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Dashboard',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _getGreeting(),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            auth.name,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      // Single logout button
      actions: [
        GestureDetector(
          onTap: _logout,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildBody(bool isKetua) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(isKetua),
          const SizedBox(height: 16),
          if (_isLoading) ...[
            const _JadwalSkeletonCard(),
            const _JadwalSkeletonCard(),
          ] else if (_hasError)
            _buildErrorState()
          else if (isKetua)
            _KetuaHeroSection(
              jadwalList: _jadwalList,
              onRefresh: _fetchJadwal,
            )
          else
            _buildGuruJadwalList(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isKetua) {
    return FadeTransition(
      opacity: _isLoading ? const AlwaysStoppedAnimation(1) : _greetFade,
      child: SlideTransition(
        position: _isLoading
            ? const AlwaysStoppedAnimation(Offset.zero)
            : _greetSlide,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKetua ? 'Aksi Ketua Kelas' : 'Jadwal Hari Ini',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _Palette.textDark,
                  ),
                ),
                Text(
                  _formattedDate(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _Palette.textMid,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (!_isLoading)
              GestureDetector(
                onTap: _fetchJadwal,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _Palette.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: _Palette.primary,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuruJadwalList() {
    if (_jadwalList.isEmpty) return const _EmptyStateWidget();
    return FadeTransition(
      opacity: _greetFade,
      child: Column(
        children: _jadwalList
            .map((j) => _JadwalCard(
                  jadwal: j,
                  isKetua: false,
                  onRefresh: _fetchJadwal,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _Palette.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: _Palette.red, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Jadwal',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _Palette.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi internet kamu\nlalu coba lagi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: _Palette.textMid, height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetchJadwal,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_Palette.primary, _Palette.secondary]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Coba Lagi',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
