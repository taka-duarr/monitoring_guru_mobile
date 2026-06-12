import 'dart:io';
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
import 'profile_screen.dart';
import 'main_navigation_wrapper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _jadwalList = [];
  bool _isLoading = true;

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
    return const AssetImage(''); // Fallback
  }

  @override
  void initState() {
    super.initState();
    _fetchJadwal();
  }

  Future<void> _fetchJadwal() async {
    try {
      final response = await ApiService.getJadwal();
      if (!mounted) return;
      if (response['success']) {
        setState(() {
          _jadwalList = response['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetch jadwal: $e");
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _executeLogout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Konfirmasi Keluar',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : Colors.indigo.shade900),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: GoogleFonts.inter(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w600),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isKetua = auth.role.toLowerCase() == 'ketuakelas';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String kelasName = _jadwalList.isNotEmpty && _jadwalList[0]['kelas'] != null
        ? (_jadwalList[0]['kelas']['name']?.toString() ?? '-')
        : '-';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : Colors.indigo.shade900)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchJadwal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Card
                    GestureDetector(
                      onTap: () {
                        final nav = MainNavigationWrapper.of(context);
                        if (nav != null) {
                          final isGuru = Provider.of<AuthProvider>(context, listen: false).role.toLowerCase() == 'guru';
                          nav.currentIndex = isGuru ? 2 : 1;
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark 
                                ? [const Color(0xFF312E81), const Color(0xFF4C1D95)] 
                                : [Colors.indigo.shade600, Colors.purple.shade600]
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.indigo.withValues(alpha: 0.3), 
                              blurRadius: 15, 
                              offset: const Offset(0, 5)
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              child: ClipOval(
                                child: auth.profilePhotoPath.isNotEmpty
                                    ? Image(
                                        image: _getAvatarImage(auth.profilePhotoPath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, o, s) {
                                          return const Icon(Icons.person, size: 36, color: Colors.white);
                                        },
                                      )
                                    : const Icon(Icons.person, size: 36, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, ${auth.name}',
                                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  Text(
                                    isKetua ? 'Ketua Kelas $kelasName' : 'Guru Pengajar',
                                    style: GoogleFonts.inter(color: Colors.indigo.shade100),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    

                    Text(
                      'Jadwal Hari Ini', 
                      style: GoogleFonts.outfit(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? const Color(0xFFF1F5F9) : Colors.blueGrey.shade800
                      )
                    ),
                    const SizedBox(height: 16),
                    
                    _jadwalList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text('Tidak ada jadwal hari ini.', style: GoogleFonts.inter(color: Colors.grey)),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _jadwalList.length,
                            itemBuilder: (context, index) {
                              final j = _jadwalList[index];
                              final hasMasuk = j['absen_masuk'] != null;
                              final hasKeluar = j['absen_keluar'] != null;
                              final isSelesai = hasMasuk && hasKeluar;

                              // Status-based accent line color definition
                              Color statusColor;
                              if (isSelesai) {
                                statusColor = isDark ? const Color(0xFF10B981) : const Color(0xFF10B981); // Emerald Green
                              } else if (hasMasuk) {
                                statusColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFF59E0B); // Amber Yellow
                              } else {
                                statusColor = isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5); // Indigo Blue
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                    topLeft: Radius.circular(6),
                                    bottomLeft: Radius.circular(6),
                                  ),
                                  border: Border(
                                    left: BorderSide(color: statusColor, width: 6),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    InkWell(
                                      onTap: !isKetua ? () {
                                        if (j['mapel'] != null && j['mapel']['id'] != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => RiwayatMapelScreen(
                                                mapelId: j['mapel']['id'],
                                                mapelName: j['mapel']['name'] ?? 'Mapel',
                                              ),
                                            ),
                                          );
                                        }
                                      } : null,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        leading: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF334155) : Colors.indigo.shade50, 
                                            borderRadius: BorderRadius.circular(12)
                                          ),
                                          child: Icon(Icons.book, color: isDark ? const Color(0xFF818CF8) : Colors.indigo),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                j['mapel']['name'] ?? 'Mapel', 
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? const Color(0xFFF1F5F9) : Colors.black87
                                                )
                                              )
                                            ),
                                            if (!isKetua) Icon(Icons.chevron_right, color: isDark ? const Color(0xFF818CF8) : Colors.indigo, size: 20),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              '${j['jam_mulai']} - ${j['jam_selesai']}',
                                              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.black54),
                                            ),
                                            Text(
                                              'Kelas: ${j['kelas']['name']}',
                                              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.black54),
                                            ),
                                            Text(
                                              'Ruang: ${j['ruangan']['name']}',
                                              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (hasMasuk)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                        child: Column(
                                          children: [
                                            Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.login, size: 16, color: isDark ? const Color(0xFF34D399) : Colors.teal.shade500),
                                                    const SizedBox(width: 6),
                                                    Text('Masuk: ', style: GoogleFonts.inter(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                                                    Text(
                                                      j['absen_masuk']['jam_masuk'] ?? '-', 
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13, 
                                                        fontWeight: FontWeight.bold,
                                                        color: isDark ? Colors.white : const Color(0xFF1E293B)
                                                      )
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.logout, 
                                                      size: 16, 
                                                      color: hasKeluar 
                                                          ? (isDark ? const Color(0xFFF87171) : Colors.red.shade500) 
                                                          : (isDark ? const Color(0xFF475569) : Colors.grey.shade400),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text('Keluar: ', style: GoogleFonts.inter(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                                                    Text(
                                                      hasKeluar ? (j['absen_keluar']['jam_keluar'] ?? '-') : '-', 
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13, 
                                                        fontWeight: FontWeight.bold, 
                                                        color: hasKeluar 
                                                            ? (isDark ? Colors.white : const Color(0xFF1E293B)) 
                                                            : (isDark ? const Color(0xFF475569) : Colors.grey.shade500)
                                                      )
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                if (!isKetua)
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => AbsenMuridScreen(
                                                              absenMasukId: j['absen_masuk']['id'],
                                                              mapelName: j['mapel']['name'] ?? 'Mapel',
                                                              kelasName: j['kelas']['name'] ?? '-',
                                                            ),
                                                          ),
                                                        ).then((_) => _fetchJadwal());
                                                      },
                                                      icon: const Icon(Icons.people, size: 18),
                                                      label: const Text('Absen Murid'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: isDark ? const Color(0xFF334155) : Colors.indigo.shade50,
                                                        foregroundColor: isDark ? const Color(0xFFE2E8F0) : Colors.indigo.shade700,
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                                      ),
                                                    ),
                                                  ),
                                                if (!isKetua) const SizedBox(width: 8),
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: isSelesai ? null : () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => const ScannerScreen(),
                                                        ),
                                                      ).then((_) => _fetchJadwal());
                                                    },
                                                    icon: Icon(isSelesai ? Icons.check_circle : Icons.qr_code_scanner, size: 18),
                                                    label: Text(isSelesai ? 'Selesai' : 'Scan QR KELUAR'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: isSelesai 
                                                          ? (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100) 
                                                          : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.2) : Colors.red.shade50),
                                                      foregroundColor: isSelesai 
                                                          ? (isDark ? const Color(0xFF64748B) : Colors.grey.shade600) 
                                                          : (isDark ? const Color(0xFFFCA5A5) : Colors.red.shade700),
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (!isSelesai)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                        child: isKetua
                                            ? ElevatedButton.icon(
                                                icon: const Icon(Icons.qr_code, color: Colors.white, size: 20),
                                                label: Text(
                                                  hasMasuk ? 'Generate QR KELUAR' : 'Generate QR MASUK', 
                                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: hasMasuk 
                                                      ? (isDark ? const Color(0xFFD97706) : Colors.amber.shade600) 
                                                      : Theme.of(context).primaryColor,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  elevation: 0,
                                                ),
                                                onPressed: () {
                                                  _showQrModal(context, j['id'].toString(), j['mapel']['name'] ?? 'Mapel', hasMasuk);
                                                },
                                              )
                                            : !hasMasuk ? ElevatedButton.icon(
                                                icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                                                label: Text(
                                                  'Scan QR MASUK', 
                                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(context).primaryColor,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  elevation: 0,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()))
                                                    .then((_) => _fetchJadwal());
                                                },
                                              ) : const SizedBox.shrink(),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showQrModal(BuildContext context, String jadwalId, String mapelName, bool wasMasuk) {
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
          final currentJadwal = updatedList.firstWhere((j) => j['id'].toString() == jadwalId, orElse: () => null);
          if (currentJadwal != null) {
            final isNowMasuk = currentJadwal['absen_masuk'] != null;
            final isNowKeluar = currentJadwal['absen_keluar'] != null;
            
            if (!wasMasuk && isNowMasuk) {
              timer.cancel();
              if (mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                _fetchJadwal();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sip! Guru berhasil absen MASUK!')));
              }
            } else if (wasMasuk && isNowKeluar) {
              timer.cancel();
              if (mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                _fetchJadwal();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sip! Guru berhasil absen KELUAR!')));
              }
            }
          }
        }
      } catch (e) {
        // abaikan error koneksi saat polling
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.blueGrey.shade200,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                mapelName, 
                textAlign: TextAlign.center, 
                style: GoogleFonts.outfit(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? const Color(0xFFF1F5F9) : Colors.blueGrey.shade800
                )
              ),
              const SizedBox(height: 6),
              Text(
                wasMasuk ? 'Tunjukkan QR ini agar Guru bisa absen KELUAR' : 'Tunjukkan QR ini agar Guru bisa absen MASUK', 
                textAlign: TextAlign.center, 
                style: GoogleFonts.inter(
                  fontSize: 13, 
                  color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade400
                )
              ),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, // keep white background for scannable QR contrast
                    border: Border.all(color: isDark ? const Color(0xFF475569) : Colors.blueGrey.shade100, width: 4),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: QrImageView(
                    data: payload,
                    version: QrVersions.auto,
                    size: 220.0,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF334155) : Colors.blueGrey.shade100,
                    foregroundColor: isDark ? const Color(0xFFE2E8F0) : Colors.blueGrey.shade700,
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
    ).then((_) {
      pollingTimer?.cancel();
    });
  }
}
