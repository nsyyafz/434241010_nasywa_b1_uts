import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'admin/dashboard_admin_screen.dart';
import 'helpdesk/dashboard_helpdesk_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      // Cek role user
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final res = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      if (!mounted) return;

      final role = res['role'] ?? 'user';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'admin'
              ? const DashboardAdminScreen()
              : role == 'helpdesk'
                  ? const DashboardHelpdeskScreen()  // ← tambah ini
                  : const DashboardScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.confirmation_number_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'E-Ticketing Helpdesk',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Solusi Cepat, Laporan Tepat',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => _dot(i)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4 + 0.6 * _fadeAnim.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}