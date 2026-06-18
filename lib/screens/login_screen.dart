import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'main_navigation_wrapper.dart';

// SMK brand colors
const kBlue = Color(0xFF1A3A8F);
const kBlueMid = Color(0xFF2352C4);
const kBlueLite = Color(0xFF4A7FE5);
const kBlueBg = Color(0xFFEEF2FF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _nikController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showPassword = false;

  late final List<AnimationController> _anims = List.generate(
    5,
    (i) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    ),
  );
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNik = prefs.getString('saved_nik');
    final savedPass = prefs.getString('saved_password');
    if (savedNik != null && savedPass != null) {
      if (mounted) {
        setState(() {
          _nikController.text = savedNik;
          _passwordController.text = savedPass;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _fades = _anims
        .map((a) => CurvedAnimation(parent: a, curve: Curves.easeOut))
        .toList();
    _slides = _anims
        .map(
          (a) => Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        )
        .toList();

    for (int i = 0; i < _anims.length; i++) {
      Future.delayed(Duration(milliseconds: 100 + i * 90), () {
        if (mounted) _anims[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final a in _anims) a.dispose();
    _nikController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _anim(int i, Widget child) => FadeTransition(
    opacity: _fades[i],
    child: SlideTransition(position: _slides[i], child: child),
  );

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final success = await Provider.of<AuthProvider>(
      context,
      listen: false,
    ).login(_nikController.text.trim(), _passwordController.text);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_nik', _nikController.text.trim());
      await prefs.setString('saved_password', _passwordController.text);

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => const MainNavigationWrapper(),
          transitionsBuilder: (_, animation, __, child) {
            final curve = CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn);
            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
              child: FadeTransition(
                opacity: curve,
                child: child,
              ),
            );
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'NIK/NIS atau password salah.',
                style: TS.smallBold(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: T.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: T.r12),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topH = size.height * 0.36;

    return Scaffold(
      backgroundColor: kBlueBg,
      body: Stack(
        children: [
          // ── Gradient top header ──────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topH + 40,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kBlue, kBlueMid, kBlueLite],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                // Bubbles for visual texture
              ),
              child: Stack(
                children: [
                  // decorative circles (animated)
                  const Positioned(
                    top: -40,
                    right: -30,
                    child: _FloatingBubble(size: 160, delay: 0),
                  ),
                  const Positioned(
                    bottom: 20,
                    left: -20,
                    child: _FloatingBubble(size: 100, delay: 1000),
                  ),
                  // Logo + greeting in header
                  SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 36),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo circle
                            _anim(
                              0,
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.school_rounded,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _anim(
                              1,
                              Column(
                                children: [
                                  Text(
                                    _greeting(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Masuk untuk mulai presensi',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── White card form ──────────────────────────────
          Positioned(
            top: topH - 10,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── NIK ───────────────────────────────
                      _anim(
                        2,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Username / NIK'),
                            const SizedBox(height: 8),
                            _field(
                              controller: _nikController,
                              hint: 'Masukkan NIK atau NIS',
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.number,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Wajib diisi'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Password ──────────────────────────
                      _anim(
                        3,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Password'),
                            const SizedBox(height: 8),
                            _field(
                              controller: _passwordController,
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              obscure: !_showPassword,
                              suffix: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: T.muted,
                                ),
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Wajib diisi'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Forgot ────────────────────────────
                      _anim(
                        3,
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Hubungi administrator sekolah.',
                                      style: TS.small(color: Colors.white),
                                    ),
                                    backgroundColor: T.sub,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: T.r12,
                                    ),
                                    margin: const EdgeInsets.all(16),
                                  ),
                                ),
                            child: Text(
                              'Butuh bantuan?',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Submit button ─────────────────────
                      _anim(
                        4,
                        _PressableButton(
                          onTap: _isLoading ? null : _login,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kBlue, kBlueMid],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: T.r12,
                              boxShadow: [
                                BoxShadow(
                                  color: kBlue.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: _isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Masuk',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Footer ────────────────────────────
                      Center(
                        child: Text(
                          'SMK NEGERI 2 SURABAYA',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: T.muted,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi 🌤️';
    if (h < 15) return 'Selamat Siang ☀️';
    if (h < 18) return 'Selamat Sore 🌆';
    return 'Selamat Malam 🌙';
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: T.inkDark,
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: TS.bodyBold(color: T.inkDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TS.body(color: T.muted),
        prefixIcon: Icon(icon, size: 18, color: T.muted),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF5F7FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: T.r12,
          borderSide: const BorderSide(color: Color(0xFFD6E0FF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: T.r12,
          borderSide: const BorderSide(color: Color(0xFFD6E0FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: T.r12,
          borderSide: const BorderSide(color: kBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: T.r12,
          borderSide: BorderSide(color: T.red, width: 1.4),
        ),
      ),
      validator: validator,
    );
  }
}

// ──────────────────────────────────────────────────────────────────
class _PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressableButton({required this.child, this.onTap});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    lowerBound: 0.94,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.reverse(),
      onTapUp: (_) {
        final cb = widget.onTap;
        _c.forward().then((_) => cb?.call());
      },
      onTapCancel: () => _c.forward(),
      child: ScaleTransition(scale: _c, child: widget.child),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
class _FloatingBubble extends StatefulWidget {
  final double size;
  final int delay;
  const _FloatingBubble({required this.size, required this.delay});

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  late final Animation<Offset> _anim = Tween<Offset>(
    begin: const Offset(0, 0),
    end: const Offset(0, -0.15),
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _anim,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
    );
  }
}
