import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

class IzinGuruScreen extends StatefulWidget {
  const IzinGuruScreen({super.key});

  @override
  State<IzinGuruScreen> createState() => _IzinGuruScreenState();
}

class _IzinGuruScreenState extends State<IzinGuruScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isPickingFile = false;
  List<dynamic> _riwayatIzin = [];
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

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
      final results = await Future.wait([
        ApiService.getIzinGuru(),
        ApiService.getJadwal(),
      ]);

      final izinResponse = results[0];
      final jadwalResponse = results[1];

      if (izinResponse['success'] == true) {
        final List<dynamic> data = izinResponse['data'] ?? [];
        if (mounted) {
          setState(() => _riwayatIzin = data);
        }
      }

      if (jadwalResponse['success'] == true) {
        final List<dynamic> jadwalData = jadwalResponse['data'] ?? [];
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
      debugPrint('Error fetch riwayat izin: $e');
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

    // Restrict access: only users with role 'guru' may access this screen
    if (!auth.isAuthenticated || auth.role.toLowerCase() != 'guru') {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          iconTheme: IconThemeData(color: Colors.blueGrey.shade800),
          title: Text(
            'Pengajuan Izin',
            style: GoogleFonts.outfit(
              color: Colors.blueGrey.shade800,
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
                Icon(Icons.lock_outline, size: 56, color: Colors.blueGrey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Akses ditolak',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fitur ini hanya dapat diakses oleh Guru.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 160,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: Colors.blueGrey.shade800),
        title: Text(
          'Pengajuan Izin',
          style: GoogleFonts.outfit(
            color: Colors.blueGrey.shade800,
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
                      color: Colors.blueGrey.shade500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jadwal Ajar', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: ValueKey('jadwal_${_selectedJadwalId ?? 'none'}_${_jadwalList.length}'),
                          initialValue: _selectedJadwalId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.blueGrey.shade100),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.blueGrey.shade100),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.indigo.shade300, width: 1.4),
                            ),
                            hintText: _jadwalList.isEmpty ? 'Belum ada jadwal tersedia' : 'Pilih jadwal ajar',
                          ),
                          items: _jadwalList
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item['id']?.toString(),
                                  child: Text(
                                    _jadwalLabel(item),
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: 13),
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
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade700),
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
                        Text('Tanggal', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.blueGrey.shade100),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatDate(_tanggalIzin),
                                    style: GoogleFonts.inter(fontSize: 14, color: Colors.blueGrey.shade800),
                                  ),
                                ),
                                Icon(Icons.calendar_month, color: Colors.blueGrey.shade400),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Jenis Izin', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
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
                        Text('Keterangan / Alasan', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _pesanController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Tuliskan alasan lengkap...',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.blueGrey.shade100),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.blueGrey.shade100),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.indigo.shade300, width: 1.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Bukti (Surat Dokter/Lampiran)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _isPickingFile ? null : _pickFile,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.indigo.shade100, style: BorderStyle.solid),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.file_upload_outlined, size: 34, color: Colors.blueGrey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  _isPickingFile
                                      ? 'Membuka file picker...'
                                      : (_selectedFileName == null ? 'Pilih File Bukti (opsional)' : _selectedFileName!),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.blueGrey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Format: jpg, jpeg, png, pdf, doc, docx (Maks: 2MB)',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.blueGrey.shade500),
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
                                    child: const Text('Hapus lampiran'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitIzin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade600,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Kirim Pengajuan Izin',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Riwayat Izin', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 10),
                        if (_riwayatIzin.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blueGrey.shade100),
                            ),
                            child: Text(
                              'Belum ada riwayat izin.',
                              style: GoogleFonts.inter(color: Colors.blueGrey.shade500),
                            ),
                          )
                        else                          
                            ..._riwayatIzin.take(5).map((item) {
                            final bool approved = item['approval'].toString() == '1' ||
                            item['approval'].toString().toLowerCase() == 'true';
                            final String tanggal = item['tanggal_izin']?.toString() ?? '-';
                            final String judul = item['judul']?.toString() ?? '-';
                            final String pesan = item['pesan']?.toString() ?? '-';
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blueGrey.shade100),
                              ),
                              child: Row(
                                children: [                                                         
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: approved ? Colors.green : Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$judul • $tanggal',
                                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          const SizedBox(height: 2),
                                        Text(
                                          pesan,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    approved ? 'Disetujui' : 'Menunggu',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: approved ? Colors.green.shade700 : Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.blueGrey.shade100)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BottomMenuItem(
                  label: 'Jadwal',
                  icon: Icons.home_outlined,
                  selected: false,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    );
                  },
                ),
                _BottomMenuItem(
                  label: 'Izin',
                  icon: Icons.description_outlined,
                  selected: true,
                  onTap: () {},
                ),
                _BottomMenuItem(
                  label: 'Profil',
                  icon: Icons.person_outline,
                  selected: false,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.indigo.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.indigo.shade300 : Colors.blueGrey.shade200,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: selected ? Colors.indigo.shade700 : Colors.blueGrey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BottomMenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _BottomMenuItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.indigo.shade700 : Colors.blueGrey.shade400;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}