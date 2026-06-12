import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/premium_button.dart';
import 'main_navigation_wrapper.dart';
import 'riwayat_izin_screen.dart';

class IzinGuruScreen extends StatefulWidget {
  const IzinGuruScreen({super.key});

  @override
  State<IzinGuruScreen> createState() => _IzinGuruScreenState();
}

class _IzinGuruScreenState extends State<IzinGuruScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isPickingFile = false;
  List<dynamic> _jadwalList = [];

  final TextEditingController _pesanController = TextEditingController();

  String _jenisIzin = 'sakit';
  DateTime _tanggalIzin = DateTime.now();
  String? _selectedJadwalId;
  String? _selectedFilePath;
  String? _selectedFileName;

  Uint8List? get _selectedFileBytes => null;

  @override
  void initState() {
    super.initState();
    _fetchRiwayatIzin();
  }

  @override
  void dispose() {
    _pesanController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day-$month-$year';
  }



  String _jadwalLabel(dynamic item) {
    final mapel = item['mapel']?['name'] ?? 'Mapel';
    final kelas = item['kelas']?['name'] ?? '-';
    final ruang = item['ruangan']?['name'] ?? '-';
    final jamMulai = item['jam_mulai'] ?? '--:--';
    final jamSelesai = item['jam_selesai'] ?? '--:--';
    return '$mapel • $kelas • $ruang ($jamMulai - $jamSelesai)';
  }

  Future<void> _fetchRiwayatIzin() async {
    try {
      final response = await ApiService.getJadwal();

      if (response['success'] == true) {
        final List<dynamic> jadwalData = response['data'] ?? [];
        if (mounted) {
          setState(() {
            _jadwalList = jadwalData;
            if (jadwalData.isEmpty) {
              _selectedJadwalId = null;
            } else if (_selectedJadwalId == null ||
                !jadwalData.any((item) => item['id']?.toString() == _selectedJadwalId)) {
              _selectedJadwalId = jadwalData.first['id']?.toString();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch jadwal: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalIzin,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _tanggalIzin = picked);
    }
  }

  Future<void> _pickFile() async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);

    try {
      const typeGroup = XTypeGroup(
        label: 'Bukti Izin',
        extensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      final picked = await openFile(
        acceptedTypeGroups: [typeGroup],
        confirmButtonText: 'Pilih',
      );

      if (!mounted) return;
      if (picked == null) {
        return;
      }

      final size = await picked.length();
      if (size > 2 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran file maksimal 2MB')),
        );
        return;
      }

      if (picked.path.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Path file tidak valid, silakan pilih file lain')),
        );
        return;
      }

      setState(() {
        _selectedFilePath = picked.path;
        _selectedFileName = picked.name.isEmpty ? 'file' : picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka file picker')),
      );
      debugPrint('Error pick file izin: $e');
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  Future<void> _submitIzin() async {
    if (_selectedJadwalId == null || _selectedJadwalId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jadwal ajar terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final tanggal = _tanggalIzin.toIso8601String().split('T').first;
      final judul = _jenisIzin == 'sakit' ? 'Sakit' : 'Izin';
      final pesan = _pesanController.text.trim();

      final payload = <String, String>{
        'tanggal': tanggal,
        'jenis': _jenisIzin,
        'jadwal_ajar_id': _selectedJadwalId!,
        // Compatibility for backend that maps directly to table columns.
        'tanggal_izin': tanggal,
        'judul': judul,
      };

      if (pesan.isNotEmpty) {
        payload['keterangan'] = pesan;
        payload['pesan'] = pesan;
      }

      final response = await ApiService.submitIzinGuru(
        data: payload,
        fileBytes: _selectedFileBytes,
        fileName: _selectedFileName,
        filePath: _selectedFilePath,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Pengajuan izin berhasil dikirim')),
        );
        setState(() {
          _jenisIzin = 'sakit';
          _tanggalIzin = DateTime.now();
          _selectedFilePath = null;
          _selectedFileName = null;
          _pesanController.clear();
        });
        _fetchRiwayatIzin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal mengirim pengajuan izin')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan jaringan')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Restrict access: only users with role 'guru' may access this screen
    if (!auth.isAuthenticated || auth.role.toLowerCase() != 'guru') {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          iconTheme: IconThemeData(color: isDark ? const Color(0xFFF1F5F9) : Colors.blueGrey.shade800),
          title: Text(
            'Pengajuan Izin',
            style: GoogleFonts.outfit(
              color: isDark ? const Color(0xFFF1F5F9) : Colors.blueGrey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: isDark ? const Color(0xFF475569) : Colors.blueGrey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Akses ditolak',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF1F5F9) : Colors.blueGrey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fitur ini hanya dapat diakses oleh Guru.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 160,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainNavigationWrapper()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Kembali', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: isDark ? const Color(0xFFF1F5F9) : Colors.blueGrey.shade800),
        title: Text(
          'Pengajuan Izin',
          style: GoogleFonts.outfit(
            color: isDark ? const Color(0xFFF1F5F9) : Colors.blueGrey.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Formulir ketidakhadiran harian',
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadwal Ajar',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: ValueKey('jadwal_${_selectedJadwalId ?? 'none'}_${_jadwalList.length}'),
                          initialValue: _selectedJadwalId,
                          isExpanded: true,
                          dropdownColor: Theme.of(context).cardColor,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.blueGrey.shade100),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.blueGrey.shade100),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? const Color(0xFF818CF8) : Colors.indigo.shade300, width: 1.4),
                            ),
                            hintText: _jadwalList.isEmpty ? 'Belum ada jadwal tersedia' : 'Pilih jadwal ajar',
                            hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : Colors.grey),
                          ),
                          items: _jadwalList
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item['id']?.toString(),
                                  child: Text(
                                    _jadwalLabel(item),
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _jadwalList.isEmpty
                              ? null
                              : (value) {
                                  setState(() => _selectedJadwalId = value);
                                },
                        ),
                        if (_jadwalList.isEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Jadwal tidak ditemukan untuk akun ini.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFFFBBF24) : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _fetchRiwayatIzin,
                                child: const Text('Muat ulang'),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        const SizedBox(height: 16),
                        Text(
                          'Tanggal',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? const Color(0xFF475569) : Colors.blueGrey.shade100),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatDate(_tanggalIzin),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: isDark ? const Color(0xFFF1F5F9) : Colors.blueGrey.shade800,
                                    ),
                                  ),
                                ),
                                Icon(Icons.calendar_month, color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade400),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Jenis Izin',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _ChoicePill(
                                label: 'Sakit',
                                selected: _jenisIzin == 'sakit',
                                onTap: () => setState(() => _jenisIzin = 'sakit'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ChoicePill(
                                label: 'Izin',
                                selected: _jenisIzin == 'izin',
                                onTap: () => setState(() => _jenisIzin = 'izin'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Keterangan / Alasan',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _pesanController,
                          maxLines: 5,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Tuliskan alasan lengkap...',
                            hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : Colors.grey),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.blueGrey.shade100),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.blueGrey.shade100),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? const Color(0xFF818CF8) : Colors.indigo.shade300, width: 1.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bukti (Surat Dokter/Lampiran)',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _isPickingFile ? null : _pickFile,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF475569) : Colors.indigo.shade100,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.file_upload_outlined,
                                  size: 34,
                                  color: isDark ? const Color(0xFF818CF8) : Colors.blueGrey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isPickingFile
                                      ? 'Membuka file picker...'
                                      : (_selectedFileName == null ? 'Pilih File Bukti (opsional)' : _selectedFileName!),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFFF1F5F9) : Colors.blueGrey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Format: jpg, jpeg, png, pdf, doc, docx (Maks: 2MB)',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade500,
                                  ),
                                ),
                                if (_selectedFileName != null) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedFilePath = null;
                                        _selectedFileName = null;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: isDark ? const Color(0xFFF87171) : Colors.red.shade700,
                                    ),
                                    child: const Text('Hapus lampiran'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        PremiumButton(
                          label: 'Kirim Pengajuan Izin',
                          isLoading: _isSubmitting,
                          onPressed: _submitIzin,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RiwayatIzinScreen()),
                              );
                            },
                            icon: const Icon(Icons.history, size: 20),
                            label: Text(
                              'Lihat Riwayat Izin',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? const Color(0xFF818CF8) : Colors.indigo.shade700,
                              side: BorderSide(
                                color: isDark ? const Color(0xFF475569) : Colors.indigo.shade200,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color bgColor;
    Color borderColor;
    Color textColor;
    
    if (selected) {
      bgColor = isDark ? const Color(0xFF312E81) : Colors.indigo.shade50;
      borderColor = isDark ? const Color(0xFF6366F1) : Colors.indigo.shade300;
      textColor = isDark ? const Color(0xFFC7D2FE) : Colors.indigo.shade700;
    } else {
      bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
      borderColor = isDark ? const Color(0xFF475569) : Colors.blueGrey.shade200;
      textColor = isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade700;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}