import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'absen_murid_screen.dart';

class RiwayatMapelScreen extends StatefulWidget {
  final String mapelId;
  final String mapelName;

  const RiwayatMapelScreen({Key? key, required this.mapelId, required this.mapelName}) : super(key: key);

  @override
  State<RiwayatMapelScreen> createState() => _RiwayatMapelScreenState();
}

class _RiwayatMapelScreenState extends State<RiwayatMapelScreen> {
  bool _isLoading = true;
  List<dynamic> _riwayat = [];

  String _formatTanggal(dynamic value) {
    final tanggal = value?.toString().trim() ?? '';
    if (tanggal.isEmpty) return '-';

    final parsed = DateTime.tryParse(tanggal);
    if (parsed != null) {
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year.toString();
      return '$day-$month-$year';
    }

    final normalized = tanggal.split('T').first;
    final parts = normalized.split(RegExp(r'[-/]'));
    if (parts.length == 3) {
      if (parts[0].length == 4) {
        return '${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[0]}';
      }

      return '${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[2].length == 4 ? parts[2] : parts[2].padLeft(4, '0')}';
    }

    return tanggal;
  }

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    try {
      final response = await ApiService.getRiwayatMapel(widget.mapelId);
      if (response['success'] == true) {
        setState(() {
          _riwayat = response['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching riwayat: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blueGrey.shade800),
        title: Text(
          'Riwayat ${widget.mapelName}',
          style: GoogleFonts.outfit(
            color: Colors.blueGrey.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _riwayat.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.blueGrey.shade200),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat mengajar\nuntuk mata pelajaran ini.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.blueGrey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _riwayat.length,
                  itemBuilder: (context, index) {
                    final item = _riwayat[index];
                    final tanggal = _formatTanggal(item['tanggal']);
                    final jamMasuk = item['jam_masuk'] ?? '-';
                    final absenKeluar = item['absen_keluar'];
                    final jamKeluar = absenKeluar != null ? absenKeluar['jam_keluar'] : '-';
                    final isSelesai = absenKeluar != null;
                    final kelas = item['kelas']?['name'] ?? '-';
                    final ruangan = item['ruangan']?['name'] ?? '-';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tanggal,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelesai ? Colors.green.shade50 : Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isSelesai ? 'Selesai' : 'Sedang Mengajar',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: isSelesai ? Colors.green.shade700 : Colors.amber.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Kelas $kelas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(ruangan, style: GoogleFonts.inter(color: Colors.blueGrey.shade600, fontSize: 13)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Masuk', style: GoogleFonts.inter(fontSize: 11, color: Colors.blueGrey.shade500)),
                                        Text(jamMasuk, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Keluar', style: GoogleFonts.inter(fontSize: 11, color: Colors.blueGrey.shade500)),
                                        Text(jamKeluar, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AbsenMuridScreen(
                                        absenMasukId: item['id'],
                                        mapelName: widget.mapelName,
                                        kelasName: kelas,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.people, size: 18),
                                label: const Text('Absen Murid'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo.shade50,
                                  foregroundColor: Colors.indigo.shade700,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
