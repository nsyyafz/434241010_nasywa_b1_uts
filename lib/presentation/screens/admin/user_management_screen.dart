import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/user_repository.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _userRepo = UserRepository();
  final _supabase = Supabase.instance.client; // tetap perlu buat cek currentUser.id
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _filterRole = 'Semua';
  final List<String> _roles = ['Semua', 'user', 'helpdesk', 'admin'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userRepo.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterRole == 'Semua') return _users;
    return _users.where((u) => u['role'] == _filterRole).toList();
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final currentUserId = _supabase.auth.currentUser!.id;

    if (user['id'] == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa menonaktifkan akun sendiri')),
      );
      return;
    }

    final newStatus = !(user['is_active'] ?? true);

    try {
      await _userRepo.toggleActiveStatus(userId: user['id'], isActive: newStatus);
      await _loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus
                ? '${user['full_name']} diaktifkan kembali'
                : '${user['full_name']} dinonaktifkan'),
            backgroundColor: newStatus ? AppTheme.success : AppTheme.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e')),
        );
      }
    }
  }

  void _showConfirmDialog(Map<String, dynamic> user) {
    final isActive = user['is_active'] ?? true;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isActive ? 'Nonaktifkan Pengguna' : 'Aktifkan Pengguna',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          isActive
              ? '${user['full_name']} tidak akan bisa login setelah dinonaktifkan. Lanjutkan?'
              : '${user['full_name']} akan bisa login kembali. Lanjutkan?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter(color: AppTheme.neutral)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? AppTheme.danger : AppTheme.success),
            onPressed: () {
              Navigator.pop(context);
              _toggleActive(user);
            },
            child: Text(isActive ? 'Nonaktifkan' : 'Aktifkan',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return 'Administrator';
      case 'helpdesk': return 'Helpdesk';
      default: return 'User';
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return AppTheme.danger;
      case 'helpdesk': return AppTheme.secondary;
      default: return AppTheme.primary;
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
        title: const Text('Kelola Pengguna'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _roles.length,
                      itemBuilder: (_, i) {
                        final isActive = _filterRole == _roles[i];
                        return GestureDetector(
                          onTap: () => setState(() => _filterRole = _roles[i]),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.primary : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive ? AppTheme.primary : const Color(0xFFD3D1C7),
                              ),
                            ),
                            child: Center(
                              child: Text(_roles[i] == 'Semua' ? 'Semua' : _roleLabel(_roles[i]),
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isActive ? Colors.white : AppTheme.neutral)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _filtered.isEmpty
                        ? Center(
                            child: Text('Tidak ada pengguna',
                                style: GoogleFonts.inter(color: AppTheme.neutral)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final u = _filtered[i];
                              final isActive = u['is_active'] ?? true;
                              final name = u['full_name'] ?? '';
                              final initial = name.isNotEmpty
                                  ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                  : '?';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: _roleColor(u['role'] ?? 'user').withOpacity(0.15),
                                      child: Text(initial,
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              color: _roleColor(u['role'] ?? 'user'))),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 2),
                                          Text(u['email'] ?? '',
                                              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.neutral)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _roleColor(u['role'] ?? 'user').withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(_roleLabel(u['role'] ?? 'user'),
                                                    style: GoogleFonts.inter(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: _roleColor(u['role'] ?? 'user'))),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? const Color(0xFFEAF3DE)
                                                      : const Color(0xFFFCEBEB),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(isActive ? 'Aktif' : 'Nonaktif',
                                                    style: GoogleFonts.inter(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: isActive ? AppTheme.success : AppTheme.danger)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: isActive,
                                      activeThumbColor: AppTheme.success,
                                      onChanged: (_) => _showConfirmDialog(u),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}