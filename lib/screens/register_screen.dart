import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  void _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    // Validasi
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak sama')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Daftar ke Supabase Auth
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      // Simpan data user ke tabel users
      if (response.user != null) {
        await Supabase.instance.client.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': name,
          'role': 'user',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Akun berhasil dibuat!', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Widget _field(String label, String hint,
      {IconData? icon,
      bool obscure = false,
      VoidCallback? toggleObscure,
      bool showToggle = false,
      TextEditingController? controller,
      TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: showToggle
                ? IconButton(
                    icon: Icon(obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: toggleObscure,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Buat Akun Baru',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
              const SizedBox(height: 4),
              Text('Isi data diri kamu dengan benar',
                  style:
                      GoogleFonts.inter(fontSize: 13, color: AppTheme.neutral)),
              const SizedBox(height: 24),
              _field('Nama Lengkap', 'Masukkan nama lengkap',
                  icon: Icons.badge_outlined, controller: _nameCtrl),
              _field('Email', 'Masukkan email',
                  icon: Icons.email_outlined,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress),
              _field('Password', 'Buat password',
                  icon: Icons.lock_outline,
                  controller: _passCtrl,
                  obscure: _obscure1,
                  showToggle: true,
                  toggleObscure: () =>
                      setState(() => _obscure1 = !_obscure1)),
              _field('Konfirmasi Password', 'Ulangi password',
                  icon: Icons.lock_outline,
                  controller: _confirmCtrl,
                  obscure: _obscure2,
                  showToggle: true,
                  toggleObscure: () =>
                      setState(() => _obscure2 = !_obscure2)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Daftar'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sudah punya akun? ',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.neutral)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Masuk',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}