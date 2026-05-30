import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'scanner_screen.dart';

import 'riwayat_mapel_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _jadwalList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJadwal();
  }

  Future<void> _fetchJadwal() async {
    try {
      final response = await ApiService.getJadwal();
      if (response['success']) {
        setState(() {
          _jadwalList = response['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetch jadwal: $e");
    }
    setState(() => _isLoading = false);
  }

  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isKetua = auth.role == 'ketuakelas';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
        backgroundColor: Colors.white,
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.indigo.shade600, Colors.purple.shade600]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.person, size: 36, color: Colors.white),
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
                                  isKetua ? 'Ketua Kelas' : 'Guru Pengajar',
                                  style: GoogleFonts.inter(color: Colors.indigo.shade100),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    

                    Text('Jadwal Hari Ini', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
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

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
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
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        leading: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
                                          child: const Icon(Icons.book, color: Colors.indigo),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(child: Text(j['mapel']['name'] ?? 'Mapel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                            if (!isKetua) const Icon(Icons.chevron_right, color: Colors.indigo, size: 20),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text('${j['jam_mulai']} - ${j['jam_selesai']}'),
                                            Text('Kelas: ${j['kelas']['name']} • Ruang: ${j['ruangan']['name']}'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (hasMasuk)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                        child: Column(
                                          children: [
                                            const Divider(color: Colors.black12, height: 1),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.login, size: 16, color: Colors.teal.shade500),
                                                    const SizedBox(width: 6),
                                                    Text('Masuk: ', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                                                    Text(j['absen_masuk']['jam_masuk'] ?? '-', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(Icons.logout, size: 16, color: hasKeluar ? Colors.red.shade500 : Colors.grey),
                                                    const SizedBox(width: 6),
                                                    Text('Keluar: ', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                                                    Text(hasKeluar ? (j['absen_keluar']['jam_keluar'] ?? '-') : '-', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: hasKeluar ? Colors.black87 : Colors.grey)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        ),
                                      ),
                                    if (!isSelesai)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                        child: isKetua
                                            ? ElevatedButton.icon(
                                                icon: const Icon(Icons.qr_code, color: Colors.white, size: 20),
                                                label: Text(hasMasuk ? 'Generate QR KELUAR' : 'Generate QR MASUK', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: hasMasuk ? Colors.amber.shade600 : Colors.blue.shade600,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  elevation: 0,
                                                ),
                                                onPressed: () {
                                                  _showQrModal(context, j['id'].toString(), j['mapel']['name'] ?? 'Mapel', hasMasuk);
                                                },
                                              )
                                            : ElevatedButton.icon(
                                                icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                                                label: Text(hasMasuk ? 'Scan QR KELUAR' : 'Scan QR MASUK', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: hasMasuk ? Colors.amber.shade600 : Colors.teal.shade500,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  elevation: 0,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()))
                                                    .then((_) => _fetchJadwal());
                                                },
                                              ),
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
                Navigator.pop(context);
                _fetchJadwal();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sip! Guru berhasil absen MASUK!')));
              }
            } else if (wasMasuk && isNowKeluar) {
              timer.cancel();
              if (mounted) {
                Navigator.pop(context);
                _fetchJadwal();
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
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
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
                  color: Colors.blueGrey.shade200,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              Text(mapelName, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
              const SizedBox(height: 6),
              Text(wasMasuk ? 'Tunjukkan QR ini agar Guru bisa absen KELUAR' : 'Tunjukkan QR ini agar Guru bisa absen MASUK', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: Colors.blueGrey.shade400)),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blueGrey.shade100, width: 4),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
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
                    backgroundColor: Colors.blueGrey.shade100,
                    foregroundColor: Colors.blueGrey.shade700,
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
