import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBlue = Color(0xFF1565C0);

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _kBlue,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tentang Aplikasi',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Logo card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.description_rounded,
                        size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'CV Builder Mahasiswa',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versi 1.0.0',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.white60),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Deskripsi
            _infoCard(
              icon: Icons.info_outline,
              title: 'Tentang',
              content:
                  'CV Builder Mahasiswa adalah aplikasi mobile yang dirancang untuk membantu mahasiswa membuat CV profesional dengan mudah dan cepat. Cukup isi data diri, pendidikan, pengalaman, dan skill, lalu ekspor ke PDF siap pakai.',
            ),

            const SizedBox(height: 12),

            // Fitur
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_outline, color: _kBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Fitur Unggulan',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...[
                    'Buat CV dengan mudah & cepat',
                    'Template ATS Friendly & Creative',
                    'Ekspor ke PDF berkualitas tinggi',
                    'Simpan data ke cloud (Firebase)',
                    'Login dengan akun Google',
                  ].map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle,
                              color: _kBlue, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _infoCard(
              icon: Icons.people_outline,
              title: 'Tim Pengembang',
              content:
                  'Dikembangkan sebagai proyek Agile Sprint oleh Tim CV Builder — Universitas Jurusan Teknik Informatika. Proyek ini dikerjakan secara kolaboratif menggunakan metodologi Scrum.',
            ),

            const SizedBox(height: 12),

            _infoCard(
              icon: Icons.gavel_outlined,
              title: 'Lisensi',
              content: '© 2024 CV Builder Mahasiswa. Seluruh hak cipta dilindungi undang-undang.',
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _kBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
