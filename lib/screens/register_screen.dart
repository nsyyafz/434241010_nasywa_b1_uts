import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  void _register() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akun berhasil dibuat!', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _field(String label, String hint,
      {IconData? icon,
      bool obscure = false,
      VoidCallback? toggleObscure,
      bool showToggle = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          obscureText: obscure,
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
            color: cardColor, // ← diganti
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
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.neutral)),
              const SizedBox(height: 24),
              _field('Nama Lengkap', 'Masukkan nama lengkap', icon: Icons.badge_outlined),
              _field('Email', 'Masukkan email', icon: Icons.email_outlined),
              _field('Username', 'Buat username', icon: Icons.person_outline),
              _field('Password', 'Buat password',
                  icon: Icons.lock_outline,
                  obscure: _obscure1,
                  showToggle: true,
                  toggleObscure: () => setState(() => _obscure1 = !_obscure1)),
              _field('Konfirmasi Password', 'Ulangi password',
                  icon: Icons.lock_outline,
                  obscure: _obscure2,
                  showToggle: true,
                  toggleObscure: () => setState(() => _obscure2 = !_obscure2)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Daftar'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sudah punya akun? ',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.neutral)),
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