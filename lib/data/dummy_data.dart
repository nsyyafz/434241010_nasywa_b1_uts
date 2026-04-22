import '../models/ticket_model.dart';

class DummyData {
  static List<Ticket> tickets = [
    Ticket(
      id: 'TKT-001',
      title: 'Printer lantai 2 error',
      description: 'Printer tidak bisa terhubung ke jaringan kantor sejak pagi. Sudah dicoba restart tapi tidak berhasil.',
      status: 'In Progress',
      priority: 'Medium',
      category: 'Hardware',
      date: '21 Apr 2026',
      assignee: 'Helpdesk IT',
      comments: [
        Comment(author: 'Helpdesk IT', message: 'Sedang kami cek ya kak', time: '10:30', isHelpdesk: true),
        Comment(author: 'Nasywa', message: 'Baik, terima kasih', time: '10:35', isHelpdesk: false),
        Comment(author: 'Helpdesk IT', message: 'Sudah diperbaiki, mohon dicek kembali', time: '11:00', isHelpdesk: true),
      ],
    ),
    Ticket(
      id: 'TKT-002',
      title: 'Akses sistem ditolak',
      description: 'Login ke sistem kepegawaian selalu gagal sejak kemarin sore.',
      status: 'Open',
      priority: 'High',
      category: 'Software',
      date: '20 Apr 2026',
      assignee: '-',
      comments: [],
    ),
    Ticket(
      id: 'TKT-003',
      title: 'Website down',
      description: 'Website tidak bisa diakses dari jaringan luar kantor.',
      status: 'Closed',
      priority: 'High',
      category: 'Jaringan',
      date: '18 Apr 2026',
      assignee: 'Helpdesk IT',
      comments: [
        Comment(author: 'Helpdesk IT', message: 'Sudah diperbaiki', time: '09:00', isHelpdesk: true),
      ],
    ),
    Ticket(
      id: 'TKT-004',
      title: 'Email tidak masuk',
      description: 'Sudah 2 hari tidak menerima email masuk sama sekali.',
      status: 'Pending',
      priority: 'Low',
      category: 'Lainnya',
      date: '17 Apr 2026',
      assignee: '-',
      comments: [],
    ),
    Ticket(
      id: 'TKT-005',
      title: 'Keyboard rusak',
      description: 'Beberapa tombol keyboard tidak berfungsi.',
      status: 'Rejected',
      priority: 'Low',
      category: 'Hardware',
      date: '15 Apr 2026',
      assignee: '-',
      comments: [],
    ),
  ];
}