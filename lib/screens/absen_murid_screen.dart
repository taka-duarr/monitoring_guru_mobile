import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AbsenMuridScreen extends StatefulWidget {
  final String absenMasukId;
  final String mapelName;
  final String kelasName;

  const AbsenMuridScreen({
    super.key,
    required this.absenMasukId,
    required this.mapelName,
    required this.kelasName,
  });

  @override
  State<AbsenMuridScreen> createState() => _AbsenMuridScreenState();
}

class _AbsenMuridScreenState extends State<AbsenMuridScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _murids = [];

  @override
  void initState() {
    super.initState();
    _fetchMurids();
  }

  Future<void> _fetchMurids() async {
    try {
      final response = await ApiService.getAbsenMurid(widget.absenMasukId);
      if (response['success'] == true) {
        setState(() {
          _murids = response['data'] ?? [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAbsen() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final response = await ApiService.saveAbsenMurid(widget.absenMasukId, _murids);
      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Berhasil disimpan', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            backgroundColor: T.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context); // Kembali setelah save
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal menyimpan', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            backgroundColor: T.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan jaringan', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          backgroundColor: T.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _toggleAll(bool value) {
    HapticFeedback.lightImpact();
    setState(() {
      for (var murid in _murids) {
        murid['status'] = value ? 'masuk' : 'alpa';
      }
    });
  }

  void _showStatusSelector(Map<String, dynamic> murid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: T.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Status Absensi', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: T.inkDark)),
            const SizedBox(height: 16),
            _statusTile(murid, 'masuk', 'Masuk', Icons.check_circle_rounded, T.green),
            _statusTile(murid, 'izin', 'Izin', Icons.info_rounded, Colors.blue),
            _statusTile(murid, 'sakit', 'Sakit', Icons.local_hospital_rounded, Colors.orange),
            _statusTile(murid, 'terlambat', 'Terlambat', Icons.timer_rounded, Colors.amber),
            _statusTile(murid, 'alpa', 'Alpa / Tanpa Keterangan', Icons.cancel_rounded, T.red),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _statusTile(Map<String, dynamic> murid, String value, String label, IconData icon, Color color) {
    final isSelected = murid['status'] == value;
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => murid['status'] = value);
        Navigator.pop(context);
      },
      leading: Icon(icon, color: color),
      title: Text(label, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check, color: color) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? color.withValues(alpha: 0.1) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    int countMasuk = _murids.where((m) => m['status'] == 'masuk').length;
    bool allMasuk = _murids.isNotEmpty && countMasuk == _murids.length;

    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: T.inkDark),
        title: Column(
          children: [
            Text(
              'Absen Kelas ${widget.kelasName}',
              style: GoogleFonts.outfit(
                color: T.inkDark,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.mapelName,
              style: GoogleFonts.inter(
                color: T.sub,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: T.ink))
          : _murids.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(color: T.card2, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.people_outline_rounded, color: T.muted, size: 26),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada data murid\ndi kelas ini.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: T.muted, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary Banner
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: T.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: T.border),
                        boxShadow: T.shadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: T.card2,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.analytics_rounded, color: T.ink, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Masuk',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: T.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$countMasuk / ${_murids.length} Siswa',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: T.inkDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => _toggleAll(!allMasuk),
                            icon: Icon(
                              allMasuk ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: allMasuk ? T.green : T.sub,
                            ),
                            label: Text(
                              allMasuk ? 'Hapus Semua' : 'Set Semua Masuk',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: allMasuk ? T.green : T.sub,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: allMasuk ? T.greenBg : T.card2,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    // List Murid
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        itemCount: _murids.length,
                        itemBuilder: (context, index) {
                          final murid = _murids[index];
                          final status = murid['status'] ?? 'alpa';
                          
                          Color statusColor = T.red;
                          IconData statusIcon = Icons.cancel_rounded;
                          String statusText = 'Alpa';
                          
                          if (status == 'masuk') {
                            statusColor = T.green;
                            statusIcon = Icons.check_circle_rounded;
                            statusText = 'Masuk';
                          } else if (status == 'izin') {
                            statusColor = Colors.blue;
                            statusIcon = Icons.info_rounded;
                            statusText = 'Izin';
                          } else if (status == 'sakit') {
                            statusColor = Colors.orange;
                            statusIcon = Icons.local_hospital_rounded;
                            statusText = 'Sakit';
                          } else if (status == 'terlambat') {
                            statusColor = Colors.amber.shade600;
                            statusIcon = Icons.timer_rounded;
                            statusText = 'Terlambat';
                          }

                          return GestureDetector(
                            onTap: () {
                              _showStatusSelector(murid);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: status == 'masuk' ? T.card : const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: status == 'masuk' ? T.shadow : [],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      murid['no_absen']?.toString() ?? '-',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          murid['name'] ?? '-',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: T.inkDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'NIS: ${murid['nis'] ?? '-'}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: T.sub,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(statusIcon, size: 14, color: statusColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusText,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Save Button
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: T.card,
                        border: const Border(top: BorderSide(color: T.border2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          )
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveAbsen,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: T.ink,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Simpan Absensi',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
    );
  }
}
