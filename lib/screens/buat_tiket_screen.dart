import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class BuatTiketScreen extends StatefulWidget {
  const BuatTiketScreen({super.key});

  @override
  State<BuatTiketScreen> createState() => _BuatTiketScreenState();
}

class _BuatTiketScreenState extends State<BuatTiketScreen> {
  final _judulCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _kategori = 'Hardware';
  String _prioritas = 'Medium';
  bool _loading = false;

  final List<String> _kategoriList = ['Hardware', 'Software', 'Jaringan', 'Lainnya'];
  final List<String> _prioritasList = ['Low', 'Medium', 'High'];

  void _submit() async {
    if (_judulCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Judul tiket tidak boleh kosong', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tiket berhasil dikirim!', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Buat Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Judul Tiket'),
              TextField(controller: _judulCtrl,
                  decoration: const InputDecoration(hintText: 'Masukkan judul tiket')),
              const SizedBox(height: 16),

              _label('Kategori'),
              DropdownButtonFormField<String>(
                value: _kategori,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD3D1C7))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD3D1C7))),
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _kategoriList.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (v) => setState(() => _kategori = v!),
              ),
              const SizedBox(height: 16),

              _label('Prioritas'),
              Row(
                children: _prioritasList.map((p) {
                  final isActive = _prioritas == p;
                  Color activeColor = AppTheme.primary;
                  if (p == 'Low') activeColor = AppTheme.success;
                  if (p == 'High') activeColor = AppTheme.danger;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _prioritas = p),
                      child: Container(
                        margin: EdgeInsets.only(right: p != 'High' ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? activeColor : cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isActive ? activeColor : const Color(0xFFD3D1C7)),
                        ),
                        child: Text(p,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isActive ? Colors.white : AppTheme.neutral)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _label('Deskripsi'),
              TextField(controller: _descCtrl, maxLines: 5,
                  decoration: const InputDecoration(hintText: 'Jelaskan masalah kamu secara detail...')),
              const SizedBox(height: 16),

              _label('Lampiran'),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.secondary.withOpacity(0.4), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: AppTheme.neutral, size: 28),
                      const SizedBox(height: 8),
                      Text('Upload foto atau ambil dari kamera',
                          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.neutral)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _uploadBtn('Galeri', Icons.photo_library_outlined, cardColor),
                          const SizedBox(width: 8),
                          _uploadBtn('Kamera', Icons.camera_alt_outlined, cardColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Kirim Tiket'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _uploadBtn(String label, IconData icon, Color cardColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD3D1C7)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.neutral),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.neutral)),
        ],
      ),
    );
  }
}