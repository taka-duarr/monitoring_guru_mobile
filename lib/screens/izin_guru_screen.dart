import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class IzinGuruScreen extends StatefulWidget {
  const IzinGuruScreen({Key? key}) : super(key: key);

  @override
  State<IzinGuruScreen> createState() => _IzinGuruScreenState();
}

class _IzinGuruScreenState extends State<IzinGuruScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<dynamic> _jadwalList = [];

  final TextEditingController _pesanController = TextEditingController();

  String? _selectedJadwalId;
  String _jenisIzin = 'Sakit';
  DateTime _tanggalIzin = DateTime.now();
  TimeOfDay _jamIzin = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _fetchJadwal();
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

  String _formatTime(TimeOfDay value) {
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

  Future<void> _fetchJadwal() async {
    try {
      final response = await ApiService.getJadwal();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _jadwalList = data;
          if (_selectedJadwalId == null && data.isNotEmpty) {
            _selectedJadwalId = data.first['id'].toString();
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetch jadwal izin: $e');
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _jamIzin,
    );

    if (picked != null) {
      setState(() => _jamIzin = picked);
    }
  }

  Future<void> _submitIzin() async {
    if (_selectedJadwalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jadwal ajar terlebih dahulu')),
      );
      return;
    }

    if (_pesanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keterangan / alasan harus diisi')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.submitIzinGuru({
        'jadwal_ajar_id': _selectedJadwalId,
        'tanggal_izin': _tanggalIzin.toIso8601String().split('T').first,
        'jam_izin': _formatTime(_jamIzin),
        'judul': _jenisIzin,
        'pesan': _pesanController.text.trim(),
      });

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Pengajuan izin berhasil dikirim')),
        );
        Navigator.pop(context);
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
                  Text(
                    'Pengajuan Izin',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade900,
                    ),
                  ),
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
                          color: Colors.black.withOpacity(0.04),
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
                          value: _selectedJadwalId,
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
                          ),
                          items: _jadwalList
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item['id'].toString(),
                                  child: Text(
                                    _jadwalLabel(item),
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedJadwalId = value);
                          },
                        ),
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
                        Text('Jam Izin', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickTime,
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
                                    _formatTime(_jamIzin),
                                    style: GoogleFonts.inter(fontSize: 14, color: Colors.blueGrey.shade800),
                                  ),
                                ),
                                Icon(Icons.schedule, color: Colors.blueGrey.shade400),
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
                                selected: _jenisIzin == 'Sakit',
                                onTap: () => setState(() => _jenisIzin = 'Sakit'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ChoicePill(
                                label: 'Keperluan Lain',
                                selected: _jenisIzin == 'Keperluan Lain',
                                onTap: () => setState(() => _jenisIzin = 'Keperluan Lain'),
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
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 26),
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
                                'Upload File (Max: 2MB)',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.blueGrey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lampiran dapat ditambahkan nanti jika backend sudah siap',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.blueGrey.shade400),
                              ),
                            ],
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
              color: Colors.black.withOpacity(0.06),
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