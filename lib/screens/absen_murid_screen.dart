import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/premium_button.dart';

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
            content: Text(response['message'] ?? 'Berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali setelah save
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal menyimpan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan jaringan'), backgroundColor: Colors.red),
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
    setState(() {
      for (var murid in _murids) {
        murid['status'] = value ? 'hadir' : 'alpa';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int countHadir = _murids.where((m) => m['status'] == 'hadir').length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? const Color(0xFFF1F5F9) : Colors.blueGrey.shade800),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Absen Kelas ${widget.kelasName}',
              style: GoogleFonts.outfit(
                color: isDark ? const Color(0xFFF1F5F9) : Colors.blueGrey.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.mapelName,
              style: GoogleFonts.inter(
                color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade500,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLoading && _murids.isNotEmpty)
            TextButton(
              onPressed: () {
                bool allHadir = countHadir == _murids.length;
                _toggleAll(!allHadir);
              },
              child: Text(
                countHadir == _murids.length ? 'Deselect All' : 'Select All',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF818CF8) : Colors.indigo,
                ),
              ),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _murids.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada data murid di kelas ini.',
                    style: GoogleFonts.inter(color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      color: isDark ? const Color(0xFF1E1B4B) : Colors.indigo.shade50,
                      child: Text(
                        'Total Hadir: $countHadir dari ${_murids.length} Siswa',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFC7D2FE) : Colors.indigo.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _murids.length,
                        itemBuilder: (context, index) {
                          final murid = _murids[index];
                          final isHadir = murid['status'] == 'hadir';

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isHadir
                                    ? (isDark ? const Color(0xFF312E81) : Colors.indigo.shade100)
                                    : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : Colors.red.shade100),
                                width: 1.5,
                              ),
                            ),
                            child: CheckboxListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              activeColor: Theme.of(context).primaryColor,
                              checkColor: Colors.white,
                              title: Text(
                                murid['name'] ?? '-',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                'No. ${murid['no_absen'] ?? '-'} • NIS: ${murid['nis'] ?? '-'}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                ),
                              ),
                              value: isHadir,
                              onChanged: (bool? value) {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  murid['status'] = (value == true) ? 'hadir' : 'alpa';
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          )
                        ],
                      ),
                      child: PremiumButton(
                        label: 'Simpan Absensi',
                        isLoading: _isSaving,
                        onPressed: _saveAbsen,
                      ),
                    )
                  ],
                ),
    );
  }
}
