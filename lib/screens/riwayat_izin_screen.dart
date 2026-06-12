import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class RiwayatIzinScreen extends StatefulWidget {
  const RiwayatIzinScreen({super.key});

  @override
  State<RiwayatIzinScreen> createState() => _RiwayatIzinScreenState();
}

class _RiwayatIzinScreenState extends State<RiwayatIzinScreen> {
  bool _isLoading = true;
  List<dynamic> _riwayatIzin = [];

  @override
  void initState() {
    super.initState();
    _fetchRiwayatIzin();
  }

  Future<void> _fetchRiwayatIzin() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getIzinGuru();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        if (mounted) {
          setState(() => _riwayatIzin = data);
        }
      }
    } catch (e) {
      debugPrint('Error fetch riwayat izin: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? const Color(0xFFF1F5F9) : Colors.blueGrey.shade800),
        title: Text(
          'Riwayat Izin Guru',
          style: GoogleFonts.outfit(
            color: isDark ? const Color(0xFFF1F5F9) : Colors.blueGrey.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRiwayatIzin,
              child: _riwayatIzin.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_outlined, size: 56, color: isDark ? const Color(0xFF475569) : Colors.blueGrey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada riwayat izin.',
                              style: GoogleFonts.inter(
                                color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade500,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _riwayatIzin.length,
                      itemBuilder: (context, index) {
                        final item = _riwayatIzin[index];
                        final bool approved = item['approval'].toString() == '1' ||
                            item['approval'].toString().toLowerCase() == 'true';
                        final String tanggal = item['tanggal_izin']?.toString() ?? '-';
                        final String judul = item['judul']?.toString() ?? '-';
                        final String pesan = item['pesan']?.toString() ?? '-';

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : Colors.blueGrey.shade100,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: approved ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$judul • $tanggal',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pesan,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: approved
                                      ? (isDark ? const Color(0xFF064E3B) : Colors.green.shade50)
                                      : (isDark ? const Color(0xFF78350F) : Colors.amber.shade50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  approved ? 'Disetujui' : 'Menunggu',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: approved
                                        ? (isDark ? const Color(0xFFA7F3D0) : Colors.green.shade700)
                                        : (isDark ? const Color(0xFFFDE68A) : Colors.amber.shade700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
