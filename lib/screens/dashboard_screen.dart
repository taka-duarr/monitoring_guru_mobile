import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'riwayat_mapel_screen.dart';
import 'absen_murid_screen.dart';
import 'scanner_screen.dart';
import 'profile_screen.dart';
import 'main_navigation_wrapper.dart';
import 'package:flutter/services.dart';


// ─────────────────────────────────────────────────────────────────
//  Local aliases for backward compat
// ─────────────────────────────────────────────────────────────────
class _C {
  static const bg       = T.bg;
  static const card     = T.card;
  static const border   = T.border;
  static const ink      = T.ink;
  static const inkDark  = T.inkDark;
  static const sub      = T.sub;
  static const muted    = T.muted;
  static const amber    = T.amber;
  static const amberBg  = T.amberBg;
  static const amberBdr = T.amberBr;
  static const green    = T.green;
  static const blue     = T.blue;
  static const blueBg   = T.blueBg;
  static const slate50  = T.card2;
  static const slate100 = T.card2;
  static const slate200 = T.border;
  static const wa       = T.green;
}

Widget _sectionLabel(String text) => Text(
      text.toUpperCase(),
      style: TS.label(),
    );

Widget _dot({Color color = T.muted, double size = 6}) => Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

BoxDecoration _cardDeco({Color? border, Color? bg}) => cardDeco(bg: bg, border: border);

// ─────────────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────────────
//  Animated helpers
// ─────────────────────────────────────────────────────────────────

/// Pressable card with scale feedback
class _PressCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const _PressCard({required this.child, this.onTap, this.onLongPress});
  @override
  State<_PressCard> createState() => _PressCardState();
}

class _PressCardState extends State<_PressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.96,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.reverse(),
      onTapUp: (_) { _c.forward(); widget.onTap?.call(); },
      onTapCancel: () => _c.forward(),
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: _c, child: widget.child),
    );
  }
}

/// Stagger-in item: fades+slides from bottom with [delay]
class _StaggerItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggerItem({required this.index, required this.child});
  @override
  State<_StaggerItem> createState() => _StaggerItemState();
}

class _StaggerItemState extends State<_StaggerItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Count-up number animation
class _CountUp extends StatelessWidget {
  final int target;
  final TextStyle style;
  const _CountUp({required this.target, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: target),
      duration: Duration(milliseconds: 600 + target * 80),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(v.toString(), style: style),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _jadwalList = [];
  bool _isLoading = true;

  List<dynamic> _tahunAjarans = [];
  String? _selectedTahunAjaranId;
  Map<String, dynamic> _semuaJadwal = {};

  // countdown timer
  Timer? _countdownTimer;
  Duration _countdownDuration = Duration.zero;
  String? _nextJamMulai;

  @override
  void initState() {
    super.initState();
    _fetchJadwal();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  ImageProvider _getAvatarImage(String? path) {
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http') || path.startsWith('https')) return NetworkImage(path);
      final file = File(path);
      if (file.existsSync()) return FileImage(file);
      
      final storageUrl = ApiService.baseUrl.replaceAll('/api', '/storage');
      return NetworkImage('$storageUrl/$path');
    }
    return const AssetImage('assets/placeholder.png');
  }

  Future<void> _fetchJadwal() async {
    try {
      final response = await ApiService.getJadwal(tahunAjaranId: _selectedTahunAjaranId);
      if (!mounted) return;
      if (response['success']) {
        setState(() {
          _jadwalList = response['data'] is List ? response['data'] : [];
          _tahunAjarans = response['tahun_ajarans'] is List ? response['tahun_ajarans'] : [];
          _selectedTahunAjaranId = response['selected_tahun_ajaran']?.toString();
          
          if (response['semua_jadwal'] is Map) {
            _semuaJadwal = Map<String, dynamic>.from(response['semua_jadwal']);
          } else {
            _semuaJadwal = {};
          }
          
          _initCountdown();
        });
      }
    } catch (e) {
      debugPrint("Error fetch jadwal: $e");
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _initCountdown() {
    _countdownTimer?.cancel();
    // find first jadwal that hasn't started yet
    final next = _jadwalList.firstWhere(
      (j) => j['absen_masuk'] == null,
      orElse: () => null,
    );
    if (next == null) {
      _nextJamMulai = null;
      return;
    }
    _nextJamMulai = next['jam_mulai'] as String?;
    if (_nextJamMulai == null) return;

    final parts = _nextJamMulai!.split(':');
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]), parts.length > 2 ? int.parse(parts[2]) : 0);
    final diff = target.difference(now);
    _countdownDuration = diff.isNegative ? Duration.zero : diff;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_countdownDuration.inSeconds > 0) {
          _countdownDuration -= const Duration(seconds: 1);
        } else {
          _countdownTimer?.cancel();
        }
      });
    });
  }

  String get _countdownText {
    final h = _countdownDuration.inHours.toString().padLeft(2, '0');
    final m = (_countdownDuration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_countdownDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _executeLogout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Konfirmasi Keluar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: _C.ink)),
        content: Text('Apakah Anda yakin ingin keluar?', style: GoogleFonts.inter(color: _C.sub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: _C.sub, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _executeLogout(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0,
            ),
            child: Text('Keluar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── stats helpers ────────────────────────────────────────────
  int get _total => _jadwalList.length;
  int get _selesai => _jadwalList.where((j) => j['absen_masuk'] != null && j['absen_keluar'] != null).length;
  int get _belum => _jadwalList.where((j) => j['absen_masuk'] == null).length;

  List<dynamic> get _ongoingList =>
      _jadwalList.where((j) => j['absen_masuk'] != null && j['absen_keluar'] == null).toList();

  List<dynamic> get _otherList =>
      _jadwalList.where((j) => !(j['absen_masuk'] != null && j['absen_keluar'] == null)).toList();

  // ─── helpers ──────────────────────────────────────────────────
  void _launchWa(String noTelp) async {
    String digits = noTelp.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) digits = '62${digits.substring(1)}';
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi 🌤️';
    if (h < 15) return 'Selamat Siang ☀️';
    if (h < 18) return 'Selamat Sore 🌇';
    return 'Selamat Malam 🌙';
  }

  String _formatDate() {
    final now = DateTime.now();
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dayName = days[now.weekday == 7 ? 0 : now.weekday];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isKetua = auth.role.toLowerCase() == 'ketuakelas';
    final String kelasGrade = _jadwalList.isNotEmpty && _jadwalList[0]['kelas'] != null
        ? (_jadwalList[0]['kelas']['grade']?.toString() ?? '')
        : '';
    final String kelasName = _jadwalList.isNotEmpty && _jadwalList[0]['kelas'] != null
        ? (_jadwalList[0]['kelas']['name']?.toString() ?? '-')
        : '-';

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : RefreshIndicator(
                onRefresh: _fetchJadwal,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StaggerItem(index: 0, child: _buildHeader(auth)),
                      const SizedBox(height: 16),
                      _StaggerItem(index: 1, child: _buildDatePill()),
                      const SizedBox(height: 24),
                      _StaggerItem(index: 2, child: _buildSummarySection()),
                      const SizedBox(height: 24),
                      if (_ongoingList.isNotEmpty) ...[
                        _buildOngoingSection(isKetua),
                        const SizedBox(height: 24),
                      ],
                      _buildTodaySection(isKetua),
                      const SizedBox(height: 24),
                      _buildFilterTahunAjaran(),
                      const SizedBox(height: 16),
                      _buildSemuaJadwal(isKetua),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────
  Widget _buildHeader(AuthProvider auth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Avatar + Greeting
        Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: const BoxDecoration(
                color: _C.ink, shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: auth.profilePhotoPath.isNotEmpty
                  ? ClipOval(
                      child: Image(
                        image: _getAvatarImage(auth.profilePhotoPath),
                        width: 52, height: 52, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          _getInitials(auth.name),
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    )
                  : Text(
                      _getInitials(auth.name),
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _C.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  auth.name,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _C.inkDark),
                ),
              ],
            ),
          ],
        ),
        // Right: Logout Button
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _C.border, width: 1.5),
            color: Colors.white,
          ),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded, color: _C.sub, size: 20),
            onPressed: _logout,
            tooltip: 'Keluar',
          ),
        ),
      ],
    );
  }

  Widget _buildDatePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10, offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 16, color: _C.ink),
          const SizedBox(width: 8),
          Text(
            _formatDate(),
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _C.ink),
          ),
        ],
      ),
    );
  }

  // ─── SUMMARY SECTION ─────────────────────────────────────────────
  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.ink, _C.sub],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: T.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ringkasan Hari Ini',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Sisa: $_belum',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStats(),
          const SizedBox(height: 16),
          _buildCountdown(),
        ],
      ),
    );
  }

  // ─── STATS ─────────────────────────────────────────────────────
  Widget _buildStats() {
    return Row(
      children: [
        _statCard(_total, 'Jadwal', numColor: _C.ink),
        const SizedBox(width: 8),
        _statCard(_selesai, 'Selesai', numColor: _C.green),
        const SizedBox(width: 8),
        _statCard(_belum, 'Belum', numColor: _C.sub),
      ],
    );
  }

  Widget _statCard(int value, String label, {Color numColor = _C.ink}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: _cardDeco(),
        child: Column(
          children: [
            _CountUp(
              target: value,
              style: GoogleFonts.outfit(
                  fontSize: 24, fontWeight: FontWeight.w900, color: numColor),
            ),
            const SizedBox(height: 4),
            Text(label.toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 9,
                    color: _C.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5)),
          ],
        ),
      ),
    );
  }

  // ─── COUNTDOWN ─────────────────────────────────────────────────
  Widget _buildCountdown() {
    if (_nextJamMulai == null) {
      // all done
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: _C.slate100, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.check_circle_rounded, color: _C.green, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Semua Selesai!',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: _C.ink)),
                Text('Tidak ada jadwal lagi hari ini',
                    style: GoogleFonts.inter(fontSize: 12, color: _C.muted)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: _cardDeco(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: _C.muted),
                    const SizedBox(width: 4),
                    Text('KELAS BERIKUTNYA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _C.muted, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pukul ${_nextJamMulai!.substring(0, 5)}',
                  style: GoogleFonts.inter(fontSize: 13, color: _C.sub),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _countdownText,
                style: GoogleFonts.jetBrainsMono != null
                    ? GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: _C.ink, letterSpacing: -1)
                    : GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: _C.ink, letterSpacing: -1),
              ),
              Text('Hitung Mundur',
                  style: GoogleFonts.inter(fontSize: 9, color: _C.muted, letterSpacing: .5, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── ONGOING ────────────────────────────────────────────────────
  Widget _buildOngoingSection(bool isKetua) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _dot(color: _C.amber, size: 7),
            const SizedBox(width: 7),
            _sectionLabel('Sedang Berlangsung'),
          ],
        ),
        const SizedBox(height: 10),
        ..._ongoingList.map((j) => _buildOngoingCard(j, isKetua)),
      ],
    );
  }

  Widget _buildOngoingCard(dynamic j, bool isKetua) {
    final mapelName = j['mapel']?['name'] ?? 'Mata Pelajaran';
    final guruName  = j['guru']?['name'] ?? '-';
    final guruTelp  = j['guru']?['no_telp']?.toString() ?? '';
    final kelasGrade = j['kelas']?['grade']?.toString() ?? '';
    final kelasName = j['kelas']?['name'] ?? '-';
    final ruangan   = j['ruangan']?['name'] ?? '-';
    final jamMulai  = (j['jam_mulai'] as String).substring(0, 5);
    final jamSelesai = (j['jam_selesai'] as String).substring(0, 5);
    final masukTime = j['absen_masuk']?['jam_masuk']?.toString().substring(0, 5) ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _C.amberBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.amberBdr),
        boxShadow: [BoxShadow(color: _C.amber.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // top shimmer bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_C.amber, Color(0xFFFBBF24), _C.amber]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // time badge
                      Wrap(
                        spacing: 6, runSpacing: 4,
                        children: [
                          _timeBadge('$jamMulai – $jamSelesai'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(mapelName,
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _C.ink),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(
                        isKetua
                            ? 'Guru: $guruName · $ruangan'
                            : 'Kelas ${kelasGrade.isNotEmpty ? '$kelasGrade ' : ''}$kelasName · $ruangan',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF78716C)),
                      ),
                      if (isKetua) ...[
                        const SizedBox(height: 2),
                        Text('Masuk: $masukTime',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF78716C))),
                      ],
                      if (isKetua && guruTelp.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _waBadge(guruTelp),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // action buttons
                Column(
                  children: [
                    if (!isKetua) ...[
                      _actionBtn(
                        label: 'Scan Keluar',
                        icon: Icons.qr_code_scanner_rounded,
                        bg: _C.ink, fg: Colors.white,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()))
                            .then((_) => _fetchJadwal()),
                      ),
                      const SizedBox(height: 6),
                      _actionBtn(
                        label: 'Absen Murid',
                        icon: Icons.people_rounded,
                        bg: _C.slate100, fg: _C.sub,
                        border: _C.border,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AbsenMuridScreen(
                              absenMasukId: j['absen_masuk']['id'],
                              mapelName: j['mapel']['name'] ?? 'Mapel',
                              kelasName: j['kelas']['name'] ?? '-',
                            ))).then((_) => _fetchJadwal()),
                      ),
                    ] else
                      _actionBtn(
                        label: 'QR Keluar',
                        icon: Icons.qr_code_rounded,
                        bg: _C.amber, fg: Colors.white,
                        onTap: () => _showQrModal(context, j['id'].toString(), mapelName, true),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEMUA JADWAL ──────────────────────────────────────────────
  Widget _buildFilterTahunAjaran() {
    if (_tahunAjarans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _dot(color: _C.blue),
            const SizedBox(width: 7),
            _sectionLabel('Filter Tahun Ajaran'),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: _cardDeco(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedTahunAjaranId,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _C.sub),
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _C.ink),
              onChanged: (String? newValue) {
                if (newValue != null && newValue != _selectedTahunAjaranId) {
                  setState(() {
                    _selectedTahunAjaranId = newValue;
                    _isLoading = true;
                  });
                  _fetchJadwal();
                }
              },
              items: _tahunAjarans.map<DropdownMenuItem<String>>((ta) {
                final isActive = ta['is_active'] == 1 || ta['is_active'] == true || ta['is_active'] == '1';
                final label = '${ta['tahun_mulai']}/${ta['tahun_selesai']} - Semester ${ta['semester']}${isActive ? ' (Aktif)' : ''}';
                return DropdownMenuItem<String>(
                  value: ta['id'].toString(),
                  child: Text(label),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSemuaJadwal(bool isKetua) {
    if (_semuaJadwal.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _cardDeco(),
        child: Center(
          child: Text('Tidak ada jadwal pada tahun ajaran ini.',
              style: GoogleFonts.inter(color: _C.muted, fontSize: 13)),
        ),
      );
    }

    final List<String> orderDays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _dot(color: _C.sub),
            const SizedBox(width: 7),
            _sectionLabel('Semua Jadwal Mengajar'),
          ],
        ),
        const SizedBox(height: 10),
        ...orderDays.map((hari) {
          if (!_semuaJadwal.containsKey(hari)) return const SizedBox.shrink();
          final List jadwals = _semuaJadwal[hari] ?? [];
          if (jadwals.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    hari,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: _C.ink),
                  ),
                ),
                ...List.generate(jadwals.length, (i) => _StaggerItem(
                  index: i,
                  child: _buildSimpleScheduleCard(jadwals[i], isKetua),
                )),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSimpleScheduleCard(dynamic j, bool isKetua) {
    final mapelName  = j['mapel']?['name'] ?? 'Mata Pelajaran';
    final guruName   = j['guru']?['name'] ?? '-';
    final kelasGrade = j['kelas']?['grade']?.toString() ?? '';
    final kelasName  = j['kelas']?['name'] ?? '-';
    final ruangan    = j['ruangan']?['name'] ?? '-';
    final jamMulai   = (j['jam_mulai'] as String).substring(0, 5);
    final jamSelesai = (j['jam_selesai'] as String).substring(0, 5);

    return _PressCard(
      onTap: j['mapel'] != null && j['mapel']['id'] != null
          ? () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => RiwayatMapelScreen(
                  mapelId: j['mapel']['id'].toString(),
                  mapelName: mapelName,
                )))
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: _cardDeco(bg: _C.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _timeBadge('$jamMulai – $jamSelesai'),
                const Icon(Icons.calendar_today_rounded, size: 14, color: _C.slate200),
              ],
            ),
            const SizedBox(height: 8),
            Text(mapelName, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: _C.ink)),
            const SizedBox(height: 4),
            Text(
              isKetua
                  ? 'Guru: $guruName · $ruangan'
                  : 'Kelas ${kelasGrade.isNotEmpty ? '$kelasGrade ' : ''}$kelasName · $ruangan',
              style: GoogleFonts.inter(fontSize: 13, color: _C.sub),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TODAY SCHEDULE ─────────────────────────────────────────────
  Widget _buildTodaySection(bool isKetua) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _dot(),
            const SizedBox(width: 7),
            _sectionLabel('Jadwal Hari Ini'),
          ],
        ),
        const SizedBox(height: 10),
        if (_otherList.isEmpty && _ongoingList.isEmpty)
          _emptyState()
        else if (_otherList.isEmpty)
          const SizedBox.shrink()
        else
          ...List.generate(_otherList.length, (i) => _StaggerItem(
            index: i,
            child: _buildScheduleCard(_otherList[i], isKetua),
          )),
      ],
    );
  }

  Widget _buildScheduleCard(dynamic j, bool isKetua) {
    final hasMasuk  = j['absen_masuk'] != null;
    final hasKeluar = j['absen_keluar'] != null;
    final isDone = hasMasuk && hasKeluar;

    final mapelName  = j['mapel']?['name'] ?? 'Mata Pelajaran';
    final guruName   = j['guru']?['name'] ?? '-';
    final guruTelp   = j['guru']?['no_telp']?.toString() ?? '';
    final kelasGrade = j['kelas']?['grade']?.toString() ?? '';
    final kelasName  = j['kelas']?['name'] ?? '-';
    final ruangan    = j['ruangan']?['name'] ?? '-';
    final jamMulai   = (j['jam_mulai'] as String).substring(0, 5);
    final jamSelesai = (j['jam_selesai'] as String).substring(0, 5);

    return _PressCard(
      onTap: !isKetua && j['mapel'] != null && j['mapel']['id'] != null
          ? () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => RiwayatMapelScreen(
                  mapelId: j['mapel']['id'],
                  mapelName: j['mapel']['name'] ?? 'Mapel',
                )))
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: _cardDeco(bg: isDone ? _C.slate50 : _C.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // badges row
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: [
                      _timeBadge('$jamMulai – $jamSelesai'),
                      _statusBadge(isDone: isDone, hasMasuk: hasMasuk),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // name
                  Row(
                    children: [
                      Expanded(
                        child: Text(mapelName,
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _C.ink)),
                      ),
                      if (!isKetua)
                        const Icon(Icons.chevron_right_rounded, color: _C.muted, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // sub info
                  Text(
                    isKetua
                        ? 'Guru: $guruName · $ruangan'
                        : 'Kelas ${kelasGrade.isNotEmpty ? '$kelasGrade ' : ''}$kelasName · $ruangan',
                    style: GoogleFonts.inter(fontSize: 13, color: _C.sub),
                  ),
                  // phone (ketua only)
                  if (isKetua && guruTelp.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _waBadge(guruTelp),
                  ],
                ],
              ),
            ),
            // absen time row
            if (hasMasuk) ...[
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _C.slate50, borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _C.slate100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.login_rounded, size: 14, color: _C.sub),
                    const SizedBox(width: 6),
                    Text(
                      j['absen_masuk']['jam_masuk']?.toString().substring(0, 5) ?? '-',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _C.ink),
                    ),
                    if (hasKeluar) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: _C.muted),
                      const SizedBox(width: 8),
                      const Icon(Icons.logout_rounded, size: 14, color: _C.sub),
                      const SizedBox(width: 6),
                      Text(
                        j['absen_keluar']['jam_keluar']?.toString().substring(0, 5) ?? '-',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _C.ink),
                      ),
                    ] else
                      Text(' · Belum keluar',
                          style: GoogleFonts.inter(fontSize: 12, color: _C.muted)),
                  ],
                ),
              ),
            ],
            // action buttons
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _buildCardActions(j, isKetua, hasMasuk, hasKeluar, isDone, mapelName),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLockedButton(String time) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: _C.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.slate200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, size: 16, color: _C.sub),
            const SizedBox(width: 8),
            Text(
              'Terbuka pukul $time',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _C.sub, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardActions(
    dynamic j, bool isKetua, bool hasMasuk, bool hasKeluar, bool isDone, String mapelName,
  ) {
    if (isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDCFCE7)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: _C.green, size: 15),
            const SizedBox(width: 6),
            Text('Selesai', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _C.green)),
          ],
        ),
      );
    }

    // TIME VALIDATION (Lock before jam_mulai)
    final now = DateTime.now();
    bool isLocked = false;
    String jamMulaiFormatted = '-';
    if (!hasMasuk && j['jam_mulai'] != null) {
      jamMulaiFormatted = j['jam_mulai'].toString().substring(0, 5);
      final parts = j['jam_mulai'].toString().split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final min = int.tryParse(parts[1]) ?? 0;
        final target = DateTime(now.year, now.month, now.day, hour, min);
        if (now.isBefore(target)) {
          isLocked = true;
        }
      }
    }

    if (isKetua) {
      if (isLocked) {
        return _buildLockedButton(jamMulaiFormatted);
      }
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showQrModal(context, j['id'].toString(), mapelName, hasMasuk),
          icon: const Icon(Icons.qr_code_rounded, size: 18),
          label: Text(hasMasuk ? 'Generate QR KELUAR' : 'Generate QR MASUK',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasMasuk ? _C.amber : _C.ink,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      );
    }

    // Guru: not started
    if (!hasMasuk) {
      if (isLocked) {
        return _buildLockedButton(jamMulaiFormatted);
      }
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()))
              .then((_) => _fetchJadwal()),
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
          label: Text('Scan QR MASUK', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.ink, foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      );
    }

    // Guru: has masuk, no keluar → Scan keluar + Absen murid
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()))
                .then((_) => _fetchJadwal()),
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
            label: Text('Scan Keluar', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.ink, foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AbsenMuridScreen(
                  absenMasukId: j['absen_masuk']['id'],
                  mapelName: j['mapel']['name'] ?? 'Mapel',
                  kelasName: j['kelas']['name'] ?? '-',
                ))).then((_) => _fetchJadwal()),
            icon: const Icon(Icons.people_rounded, size: 16),
            label: Text('Absen Murid', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.slate100, foregroundColor: _C.sub,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _C.border)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared small widgets ───────────────────────────────────────
  Widget _timeBadge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: _C.slate100, border: Border.all(color: _C.border),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _C.sub, letterSpacing: .3)),
      );

  Widget _statusBadge({required bool isDone, required bool hasMasuk}) {
    if (isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: _C.slate100, borderRadius: BorderRadius.circular(99)),
        child: Text('Selesai', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _C.sub)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: _C.blueBg, borderRadius: BorderRadius.circular(99)),
      child: Text('Belum Absen', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _C.blue)),
    );
  }

  Widget _waBadge(String noTelp) => GestureDetector(
        onTap: () => _launchWa(noTelp),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _C.slate50, border: Border.all(color: _C.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_rounded, size: 13, color: _C.wa),
              const SizedBox(width: 4),
              Text(noTelp,
                  style: GoogleFonts.inter(fontSize: 12, color: _C.sub, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _actionBtn({
    required String label, required IconData icon,
    required Color bg, required Color fg, Color? border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
          border: border != null ? Border.all(color: border) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: _cardDeco(),
        child: Column(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: _C.slate100, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.event_busy_rounded, color: _C.muted, size: 26),
            ),
            const SizedBox(height: 12),
            Text('Tidak ada jadwal hari ini',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: _C.ink),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Nikmati harimu!',
                style: GoogleFonts.inter(fontSize: 13, color: _C.muted),
                textAlign: TextAlign.center),
          ],
        ),
      );

  // ─── QR MODAL ──────────────────────────────────────────────────
  void _showQrModal(BuildContext context, String jadwalId, String mapelName, bool wasMasuk) async {
    Timer? pollingTimer;
    Timer? countdownTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        int countdown = 30;
        String payload = jsonEncode({
          'type': 'absen_jadwal',
          'jadwal_id': jadwalId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        return StatefulBuilder(
          builder: (ctxState, setState) {
            if (countdownTimer == null) {
              countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (mounted) {
                  setState(() {
                    countdown--;
                    if (countdown <= 0) {
                      countdown = 30;
                      payload = jsonEncode({
                        'type': 'absen_jadwal',
                        'jadwal_id': jadwalId,
                        'timestamp': DateTime.now().millisecondsSinceEpoch,
                      });
                    }
                  });
                }
              });

              pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
                try {
                  final response = await ApiService.getJadwal();
                  if (response['success']) {
                    final updatedList = response['data'] as List;
                    final cur = updatedList.firstWhere(
                      (j) => j['id'].toString() == jadwalId, orElse: () => null);
                    if (cur != null) {
                      final nowMasuk  = cur['absen_masuk'] != null;
                      final nowKeluar = cur['absen_keluar'] != null;
                      if ((!wasMasuk && nowMasuk) || (wasMasuk && nowKeluar)) {
                        timer.cancel();
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          Navigator.pop(ctx);
                          _fetchJadwal();
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(wasMasuk ? 'Guru berhasil absen KELUAR!' : 'Guru berhasil absen MASUK!'),
                            backgroundColor: _C.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ));
                        }
                      }
                    }
                  }
                } catch (_) {}
              });
            }

            return Container(
              decoration: const BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: _C.slate200, borderRadius: BorderRadius.circular(99)),
                  ),
                  const SizedBox(height: 20),
                  Text(mapelName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: _C.ink)),
                  const SizedBox(height: 6),
                  Text(
                    wasMasuk ? 'Tunjukkan QR agar Guru bisa absen KELUAR' : 'Tunjukkan QR agar Guru bisa absen MASUK',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13, color: _C.sub),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _C.slate100, width: 4),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)],
                    ),
                    child: QrImageView(data: payload, version: QrVersions.auto, size: 220),
                  ),
                  const SizedBox(height: 12),
                  Text('QR diperbarui dalam ${countdown}s',
                      style: GoogleFonts.inter(fontSize: 13, color: _C.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.slate100, foregroundColor: _C.sub,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Tutup', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      pollingTimer?.cancel();
      countdownTimer?.cancel();
    });
  }
}
