import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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

  final _pesanController = TextEditingController();
  String _jenisIzin = 'sakit';
  DateTime _tanggalIzin = DateTime.now();
  String? _selectedJadwalId;
  String? _selectedFilePath;
  String? _selectedFileName;

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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  Future<void> _fetchJadwal() async {
    try {
      final res = await ApiService.getJadwal();
      if (res['success'] == true && mounted) {
        final list = (res['data'] ?? []) as List;
        setState(() {
          _jadwalList = list;
          _selectedJadwalId = list.isNotEmpty ? list.first['id']?.toString() : null;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalIzin,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: T.ink, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggalIzin = picked);
  }

  Future<void> _pickFile() async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);
    try {
      const group = XTypeGroup(
        label: 'Bukti',
        extensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );
      final f = await openFile(acceptedTypeGroups: [group]);
      if (!mounted || f == null) return;
      final size = await f.length();
      if (size > 2 * 1024 * 1024) {
        _showSnack('Ukuran file maksimal 2MB', isError: true);
        return;
      }
      setState(() { _selectedFilePath = f.path; _selectedFileName = f.name.isEmpty ? 'file' : f.name; });
    } catch (_) {
      _showSnack('Gagal memilih file', isError: true);
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  Future<void> _submitIzin() async {
    if (_selectedJadwalId == null) {
      _showSnack('Pilih jadwal ajar terlebih dahulu', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final tanggal = _tanggalIzin.toIso8601String().split('T').first;
      final payload = <String, String>{
        'tanggal': tanggal,
        'jenis': _jenisIzin,
        'jadwal_ajar_id': _selectedJadwalId!,
        'tanggal_izin': tanggal,
        'judul': _jenisIzin == 'sakit' ? 'Sakit' : 'Izin',
        if (_pesanController.text.trim().isNotEmpty) ...{
          'keterangan': _pesanController.text.trim(),
          'pesan': _pesanController.text.trim(),
        },
      };
      final res = await ApiService.submitIzinGuru(
        data: payload, filePath: _selectedFilePath, fileName: _selectedFileName);
      if (!mounted) return;
      if (res['success'] == true) {
        _showSnack(res['message'] ?? 'Pengajuan berhasil dikirim', isError: false);
        setState(() {
          _jenisIzin = 'sakit';
          _tanggalIzin = DateTime.now();
          _selectedFilePath = null;
          _selectedFileName = null;
          _pesanController.clear();
        });
      } else {
        _showSnack(res['message'] ?? 'Gagal mengirim pengajuan', isError: true);
      }
    } catch (_) {
      _showSnack('Terjadi kesalahan jaringan', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TS.small(color: Colors.white)),
      backgroundColor: isError ? T.red : T.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: T.r12),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated || auth.role.toLowerCase() != 'guru') {
      return Scaffold(
        backgroundColor: T.bg,
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 48, color: T.muted),
            const SizedBox(height: 12),
            Text('Akses Ditolak', style: TS.h3()),
            const SizedBox(height: 6),
            Text('Halaman ini hanya untuk Guru.', style: TS.body()),
          ],
        )),
      );
    }

    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppBar(
        title: Text('Pengajuan Izin', style: TS.h3()),
        backgroundColor: T.card,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: T.border),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatIzinScreen())),
            icon: const Icon(Icons.history_rounded, size: 16, color: T.sub),
            label: Text('Riwayat', style: TS.smallBold()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: T.ink))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Jadwal Picker ─────────────────────────────
                _formCard(
                  label: 'Jadwal Ajar',
                  child: _jadwalList.isEmpty
                      ? Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: T.amber),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Tidak ada jadwal ditemukan.', style: TS.small(color: T.amber))),
                            TextButton(onPressed: _fetchJadwal, child: Text('Muat ulang', style: TS.smallBold())),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: T.card2, borderRadius: T.r12,
                            border: Border.all(color: T.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedJadwalId,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: T.sub),
                              style: TS.bodyBold(),
                              onChanged: (v) => setState(() => _selectedJadwalId = v),
                              items: _jadwalList.map((j) => DropdownMenuItem<String>(
                                value: j['id']?.toString(),
                                child: Text(
                                  '${j['mapel']?['name'] ?? ''} • ${j['kelas']?['name'] ?? ''} '
                                  '(${(j['jam_mulai'] ?? '').toString().substring(0, 5)})',
                                  style: TS.body(color: T.ink).copyWith(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )).toList(),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                // ── Tanggal ───────────────────────────────────
                _formCard(
                  label: 'Tanggal Izin',
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: T.card2, borderRadius: T.r12,
                        border: Border.all(color: T.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: T.sub),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_fmt(_tanggalIzin), style: TS.bodyBold())),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: T.muted),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Jenis Izin ────────────────────────────────
                _formCard(
                  label: 'Jenis Izin',
                  child: Row(
                    children: [
                      Expanded(child: _jenisBtn('sakit', 'Sakit', Icons.local_hospital_outlined)),
                      const SizedBox(width: 10),
                      Expanded(child: _jenisBtn('izin', 'Izin', Icons.description_outlined)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Keterangan ────────────────────────────────
                _formCard(
                  label: 'Keterangan / Alasan',
                  child: TextFormField(
                    controller: _pesanController,
                    maxLines: 4,
                    style: TS.bodyBold(),
                    decoration: minInput(label: '', hint: 'Tuliskan alasan izin Anda...'),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Upload File ───────────────────────────────
                _formCard(
                  label: 'Lampiran (opsional)',
                  child: GestureDetector(
                    onTap: _isPickingFile ? null : _pickFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                      decoration: BoxDecoration(
                        color: T.card2, borderRadius: T.r12,
                        border: Border.all(color: _selectedFileName != null ? T.green : T.border),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _selectedFileName != null
                                ? Icons.check_circle_rounded
                                : Icons.upload_file_rounded,
                            size: 28,
                            color: _selectedFileName != null ? T.green : T.muted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isPickingFile
                                ? 'Membuka...'
                                : _selectedFileName ?? 'Pilih File Bukti',
                            textAlign: TextAlign.center,
                            style: TS.smallBold(color: _selectedFileName != null ? T.green : T.sub),
                          ),
                          if (_selectedFileName == null)
                            Text('jpg, png, pdf, doc — maks 2MB',
                                style: TS.small(), textAlign: TextAlign.center),
                          if (_selectedFileName != null) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => setState(() { _selectedFilePath = null; _selectedFileName = null; }),
                              child: Text('Hapus', style: TS.small(color: T.red).copyWith(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Submit ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitIzin,
                    style: primaryBtn(),
                    child: _isSubmitting
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Kirim Pengajuan', style: TS.bodyBold(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _formCard({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TS.smallBold()),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _jenisBtn(String value, String label, IconData icon) {
    final selected = _jenisIzin == value;
    return GestureDetector(
      onTap: () => setState(() => _jenisIzin = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? T.ink : T.card2,
          borderRadius: T.r12,
          border: Border.all(color: selected ? T.ink : T.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : T.sub),
            const SizedBox(width: 6),
            Text(label,
                style: TS.bodyBold(color: selected ? Colors.white : T.sub)),
          ],
        ),
      ),
    );
  }
}