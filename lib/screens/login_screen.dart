import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
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
  Widget build(BuildContext context) {
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
                colors: [const Color(0xFF4F46E5), const Color(0xFF7C3AED), Colors.indigo.shade300],
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
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
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
                      backgroundColor: Colors.indigo.shade50,
                      child: Icon(Icons.qr_code_scanner_rounded, size: 40, color: Colors.indigo.shade700),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Absensi Smart SMK',
                      style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.indigo.shade900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masuk menggunakan NIK/NIS Anda',
                      style: GoogleFonts.inter(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nikController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'NIK / NIS',
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'NIK/NIS harus diisi';
                        if (v.trim().length < 6) return 'NIK/NIS tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password harus diisi';
                        if (v.length < 4) return 'Password terlalu pendek';
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.indigo.shade700, Colors.purple.shade400]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Masuk', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          'Lupa Password?',
                          style: GoogleFonts.inter(color: Colors.indigo.shade700),
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
