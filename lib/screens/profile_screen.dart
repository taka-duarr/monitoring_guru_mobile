import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final TextEditingController _passwordController = TextEditingController();
  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: auth.name);
    _phoneController = TextEditingController(text: auth.phone);
    _localPhotoPath =
        auth.profilePhotoPath.isNotEmpty ? auth.profilePhotoPath : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  ImageProvider _avatar(String? path) {
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http') || path.startsWith('https')) return NetworkImage(path);
      final f = File(path);
      if (f.existsSync()) return FileImage(f);

      final storageUrl = ApiService.baseUrl.replaceAll('/api', '/storage');
      return NetworkImage('$storageUrl/$path');
    }
    return const AssetImage('assets/images/logo.png');
  }

  Future<void> _pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
      if (result?.files.single.path != null && mounted) {
        setState(() => _localPhotoPath = result!.files.single.path);
      }
    } catch (_) {}
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
        photoPath: _localPhotoPath,
      );
      if (!mounted) return;
      setState(() { _isEditing = false; _passwordController.clear(); });
      _showSnack('Profil berhasil diperbarui!', isError: false);
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelEdit() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _isEditing = false;
      _nameController.text = auth.name;
      _phoneController.text = auth.phone;
      _localPhotoPath = auth.profilePhotoPath.isNotEmpty ? auth.profilePhotoPath : null;
      _passwordController.clear();
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: T.r16),
        title: Text('Keluar dari Akun?', style: TS.h3()),
        content: Text('Anda akan diarahkan ke halaman login.', style: TS.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TS.body(color: T.sub).copyWith(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: T.red, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: T.r12),
            ),
            child: Text('Keluar', style: TS.bodyBold(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TS.small(color: Colors.white)),
      backgroundColor: isError ? T.red : T.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: T.r12),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isKetua = auth.role.toLowerCase() == 'ketuakelas';
    final roleLabel = isKetua ? 'Ketua Kelas' : 'Guru Pengajar';

    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profil' : 'Profil', style: TS.h3()),
        backgroundColor: T.card,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: T.border),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined, size: 20, color: T.sub),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Avatar Section ──────────────────────────────
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _pickPhoto : null,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: T.card2,
                      backgroundImage: _localPhotoPath != null
                          ? _avatar(_localPhotoPath)
                          : null,
                      child: _localPhotoPath == null
                          ? Text(
                              auth.name.isNotEmpty ? auth.name[0].toUpperCase() : '?',
                              style: TS.h1().copyWith(fontSize: 36),
                            )
                          : null,
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(color: T.ink, shape: BoxShape.circle,
                              border: Border.all(color: T.card, width: 2)),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(auth.name, style: TS.h2())),
            const SizedBox(height: 4),
            Center(
              child: tBadge(roleLabel, bg: T.card2, fg: T.sub, border: T.border),
            ),
            const SizedBox(height: 28),

            // ── Info Card ───────────────────────────────────
            Container(
              decoration: cardDeco(),
              child: Column(
                children: [
                  _infoTile(
                    icon: Icons.badge_outlined,
                    label: isKetua ? 'NIS' : 'NIK',
                    value: auth.nik.isNotEmpty ? auth.nik : '-',
                  ),
                  divider(indent: 56),
                  _infoTile(
                    icon: Icons.work_outline_rounded,
                    label: 'Jabatan',
                    value: roleLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Editable Fields ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informasi Akun', style: TS.h3()),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    enabled: _isEditing,
                    style: TS.bodyBold(),
                    decoration: minInput(
                      label: 'Nama Lengkap',
                      prefix: const Icon(Icons.person_outline_rounded, size: 18, color: T.muted),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    style: TS.bodyBold(),
                    decoration: minInput(
                      label: 'Nomor Telepon',
                      prefix: const Icon(Icons.phone_outlined, size: 18, color: T.muted),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TS.bodyBold(),
                      decoration: minInput(
                        label: 'Password Baru (opsional)',
                        prefix: const Icon(Icons.lock_outline_rounded, size: 18, color: T.muted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Action Buttons ──────────────────────────────
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _cancelEdit,
                      style: ghostBtn(),
                      child: Text('Batal', style: TS.bodyBold(color: T.sub)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: primaryBtn(),
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Simpan', style: TS.bodyBold(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Logout
              GestureDetector(
                onTap: _logout,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: T.redBg, borderRadius: T.r12,
                    border: Border.all(color: T.redBr),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: T.red, size: 18),
                      const SizedBox(width: 8),
                      Text('Keluar dari Akun', style: TS.bodyBold(color: T.red)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Sistem Informasi Monitoring Guru\nTeknik Informatika ITATS © ${DateTime.now().year}',
                textAlign: TextAlign.center,
                style: TS.small(color: T.muted).copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: T.card2, borderRadius: T.r8),
            child: Icon(icon, size: 18, color: T.sub),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TS.small()),
                const SizedBox(height: 2),
                Text(value, style: TS.bodyBold()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
