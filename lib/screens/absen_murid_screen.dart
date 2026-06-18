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
        murid['status'] = value ? 'hadir' : 'alpa';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int countHadir = _murids.where((m) => m['status'] == 'hadir').length;
    bool allHadir = _murids.isNotEmpty && countHadir == _murids.length;

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
                                    'Total Hadir',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: T.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$countHadir / ${_murids.length} Siswa',
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
                            onPressed: () => _toggleAll(!allHadir),
                            icon: Icon(
                              allHadir ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: allHadir ? T.green : T.sub,
                            ),
                            label: Text(
                              allHadir ? 'Hapus Semua' : 'Pilih Semua',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: allHadir ? T.green : T.sub,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: allHadir ? T.greenBg : T.card2,
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
                          final isHadir = murid['status'] == 'hadir';

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                murid['status'] = isHadir ? 'alpa' : 'hadir';
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isHadir ? T.card : const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isHadir ? T.border : T.redBr.withValues(alpha: 0.5),
                                  width: isHadir ? 1.5 : 1.5,
                                ),
                                boxShadow: isHadir ? T.shadow : [],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: isHadir ? T.card2 : T.redBg,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      murid['no_absen']?.toString() ?? '-',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isHadir ? T.ink : T.red,
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
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      color: isHadir ? T.green : Colors.transparent,
                                      border: Border.all(
                                        color: isHadir ? T.green : T.border,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: isHadir 
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                        : null,
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
