import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _authRepo = AuthRepository();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

 void _kirimLink() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak boleh kosong')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _authRepo.resetPassword(email);
      if (mounted) setState(() { _loading = false; _sent = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim link: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _sent ? _successView() : _formView(),
      ),
    );
  }

  Widget _formView() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_reset_rounded,
              size: 40, color: AppTheme.primary),
        ),
        const SizedBox(height: 24),
        Text('Lupa Password?',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary)),
        const SizedBox(height: 8),
        Text(
          'Masukkan email kamu dan kami akan mengirimkan link untuk reset password.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.neutral),
        ),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Email',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Masukkan email kamu',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _kirimLink,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Kirim Link Reset'),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text('Kembali ke Login',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _successView() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF3DE),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              size: 40, color: AppTheme.success),
        ),
        const SizedBox(height: 24),
        Text('Email Terkirim!',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary)),
        const SizedBox(height: 8),
        Text(
          'Link reset password telah dikirim ke\n${_emailCtrl.text.trim()}\n\nCek inbox atau folder spam kamu.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.neutral),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kembali ke Login'),
        ),
      ],
    );
  }
}