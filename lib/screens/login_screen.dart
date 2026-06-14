import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/premium_button.dart';
import 'main_navigation_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nikController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showPassword = false;

  // animated background
  Alignment _begin = Alignment.topLeft;
  Alignment _end = Alignment.bottomRight;
  late Timer _bgTimer;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success = await Provider.of<AuthProvider>(context, listen: false)
        .login(_nikController.text.trim(), _passwordController.text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainNavigationWrapper()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Gagal. Periksa NIK dan Password!')),
      );
    }
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Silahkan hubungi administrator')),
    );
  }

  void _startBackgroundAnimation() {
    _bgTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      setState(() {
        _begin = _begin == Alignment.topLeft ? Alignment.topRight : Alignment.topLeft;
        _end = _end == Alignment.bottomRight ? Alignment.bottomLeft : Alignment.bottomRight;
      });
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (context, _, child) {
          return AnimatedContainer(
            duration: const Duration(seconds: 4),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF4F46E5), const Color(0xFF7C3AED), Colors.indigo.shade300],
                begin: _begin,
                end: _end,
              ),
            ),
            child: child,
          );
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(28.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: isDark ? const Color(0xFF334155) : Colors.indigo.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 48,
                          height: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Absensi Smart SMK',
                      style: GoogleFonts.outfit(
                        fontSize: 26, 
                        fontWeight: FontWeight.w700, 
                        color: isDark ? const Color(0xFFF1F5F9) : Colors.indigo.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masuk menggunakan NIK/NIS Anda',
                      style: GoogleFonts.inter(
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nikController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'NIK / NIS',
                        labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                        prefixIcon: Icon(Icons.badge, color: isDark ? const Color(0xFF94A3B8) : Colors.indigo.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF818CF8) : Colors.indigo.shade600, width: 1.5),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'NIK/NIS harus diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                        prefixIcon: Icon(Icons.lock, color: isDark ? const Color(0xFF94A3B8) : Colors.indigo.shade600),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF818CF8) : Colors.indigo.shade600, width: 1.5),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password harus diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    PremiumButton(
                      label: 'Masuk',
                      isLoading: _isLoading,
                      onPressed: _login,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          'Lupa Password?',
                          style: GoogleFonts.inter(
                            color: isDark ? const Color(0xFF818CF8) : Colors.indigo.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _startBackgroundAnimation();
  }

  @override
  void dispose() {
    _nikController.dispose();
    _passwordController.dispose();
    _bgTimer.cancel();
    super.dispose();
  }
}
