import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBlue = Color(0xFF1565C0);

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faqs = [
    {
      'q': 'Bagaimana cara membuat CV?',
      'a':
          'Buka halaman "Buat CV", isi Data Diri, Pendidikan, Pengalaman, dan Skill secara berurutan, lalu simpan setiap bagian.',
    },
    {
      'q': 'Bagaimana cara mengekspor CV ke PDF?',
      'a':
          'Buka halaman "Ekspor", pilih template CV yang diinginkan (ATS Friendly atau Creative), lalu tekan tombol "Ekspor PDF".',
    },
    {
      'q': 'Apakah data saya tersimpan otomatis?',
      'a':
          'Ya, data CV Anda akan tersimpan ke akun Firebase Anda secara otomatis setiap kali Anda menekan tombol simpan.',
    },
    {
      'q': 'Apa perbedaan template ATS Friendly dan Creative?',
      'a':
          'ATS Friendly adalah template sederhana yang mudah terbaca oleh sistem rekrutmen otomatis. Creative adalah template bergaya dengan desain dua kolom dan aksen warna.',
    },
    {
      'q': 'Bagaimana cara menghapus data pendidikan / pengalaman?',
      'a':
          'Buka tab Pendidikan atau Pengalaman di halaman Buat CV, lalu tekan ikon tong sampah pada kartu data yang ingin dihapus.',
    },
    {
      'q': 'Bagaimana cara mengganti foto profil?',
      'a':
          'Buka halaman Profil, tekan ikon kamera pada foto profil, lalu pilih gambar dari galeri atau ambil foto baru.',
    },
  ];

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
          'Bantuan',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_center_outlined,
                      color: Colors.white, size: 40),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pusat Bantuan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Temukan jawaban atas pertanyaan Anda di sini',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Pertanyaan Umum (FAQ)',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(
              _faqs.length,
              (i) => _FaqCard(
                question: _faqs[i]['q']!,
                answer: _faqs[i]['a']!,
              ),
            ),

            const SizedBox(height: 20),

            // Contact
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Masih ada pertanyaan?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hubungi tim kami melalui email untuk mendapatkan bantuan lebih lanjut.',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, color: _kBlue, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'support@cvbuilder.id',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _kBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqCard({required this.question, required this.answer});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: _kBlue,
                    size: 22,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(
                  widget.answer,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
