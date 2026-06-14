import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../widgets/premium_button.dart';
import 'login_screen.dart';

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
    _localPhotoPath = auth.profilePhotoPath.isNotEmpty
        ? auth.profilePhotoPath
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        if (!mounted) return;
        setState(() {
          _localPhotoPath = result.files.single.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal memilih foto.')));
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
        photoPath: _localPhotoPath,
      );

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _passwordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui!')),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $errorMsg')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancelEdit() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _isEditing = false;
      _nameController.text = auth.name;
      _phoneController.text = auth.phone;
      _localPhotoPath = auth.profilePhotoPath.isNotEmpty
          ? auth.profilePhotoPath
          : null;
      _passwordController.clear();
    });
  }

  void _executeLogout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Konfirmasi Keluar',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF1F5F9) : Colors.indigo.shade900,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: GoogleFonts.inter(
              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _executeLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Keluar',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  ImageProvider _getAvatarImage(String? path) {
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http') || path.startsWith('https')) {
        return NetworkImage(path);
      } else {
        final file = File(path);
        if (file.existsSync()) {
          return FileImage(file);
        }
      }
    }
    return const AssetImage(''); // Fallback handled by builder
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isKetua = auth.role.toLowerCase() == 'ketuakelas';
    final roleLabel = isKetua ? 'Ketua Kelas' : 'Guru Pengajar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profil Pengguna',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF1F5F9) : Colors.indigo.shade900,
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Photo Card
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withValues(
                              alpha: isDark ? 0.3 : 0.15,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _localPhotoPath != null
                            ? Image(
                                image: _getAvatarImage(_localPhotoPath),
                                fit: BoxFit.cover,
                                errorBuilder: (c, o, s) {
                                  return Container(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : Colors.indigo.shade50,
                                    child: Icon(
                                      Icons.person,
                                      size: 60,
                                      color: isDark
                                          ? const Color(0xFF818CF8)
                                          : Colors.indigo.shade400,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : Colors.indigo.shade50,
                                child: Center(
                                  child: Text(
                                    auth.name.isNotEmpty
                                        ? auth.name[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.outfit(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF818CF8)
                                          : Colors.indigo.shade700,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickPhoto,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                auth.name,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : Colors.indigo.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                roleLabel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF818CF8)
                      : Colors.indigo.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              if (!_isEditing)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: isDark ? const Color(0xFF818CF8) : Colors.indigo,
                  ),
                  label: Text(
                    'Edit Profil',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF818CF8)
                          : Colors.indigo.shade700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.indigo.shade50,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Form Cards
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.1 : 0.03,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Personal',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : Colors.indigo.shade900,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // NIK / NIS (Disable)
                    TextFormField(
                      initialValue: auth.nik.isNotEmpty ? auth.nik : '-',
                      enabled: false,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: isKetua
                            ? 'NIS (Nomor Induk Siswa)'
                            : 'NIK (Nomor Induk Karyawan)',
                        labelStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.grey.shade600,
                        ),
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.indigo.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF475569)
                                : Colors.grey.shade300,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : Colors.grey.shade200,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                            : Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Role (Disable)
                    TextFormField(
                      initialValue: roleLabel,
                      enabled: false,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Jabatan / Role',
                        labelStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.grey.shade600,
                        ),
                        prefixIcon: Icon(
                          Icons.work_outline,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.indigo.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF475569)
                                : Colors.grey.shade300,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : Colors.grey.shade200,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                            : Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama Lengkap (Editable in edit mode)
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        labelStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.grey.shade600,
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.indigo.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF475569)
                                : Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF475569)
                                : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF818CF8)
                                : Colors.indigo.shade600,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: _isEditing
                            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                            : (isDark
                                  ? const Color(
                                      0xFF0F172A,
                                    ).withValues(alpha: 0.7)
                                  : Colors.grey.shade50),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Nama Lengkap harus diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // No Telepon (Editable in edit mode)
                    TextFormField(
                      controller: _phoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon',
                        labelStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.grey.shade600,
                        ),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.indigo.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF475569)
                                : Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF475569)
                                : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF818CF8)
                                : Colors.indigo.shade600,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: _isEditing
                            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                            : (isDark
                                  ? const Color(
                                      0xFF0F172A,
                                    ).withValues(alpha: 0.7)
                                  : Colors.grey.shade50),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Nomor Telepon harus diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Baru (Editable in edit mode, only display if editing)
                    if (_isEditing) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              'Password Baru (Kosongkan jika tidak diubah)',
                          labelStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : Colors.grey.shade600,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : Colors.indigo.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF818CF8)
                                  : Colors.indigo.shade600,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _cancelEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF475569)
                                : Colors.grey.shade300,
                          ),
                          foregroundColor: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.grey.shade700,
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PremiumButton(
                        label: 'Simpan',
                        isLoading: _isSaving,
                        onPressed: _saveProfile,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Logout Button
                InkWell(
                  onTap: _logout,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF7F1D1D).withValues(alpha: 0.2)
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFB91C1C).withValues(alpha: 0.4)
                            : Colors.red.shade100,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: isDark
                              ? const Color(0xFFFCA5A5)
                              : Colors.red.shade700,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Keluar dari Akun',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFCA5A5)
                                : Colors.red.shade700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
