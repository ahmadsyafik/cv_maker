import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:downloadsfolder/downloadsfolder.dart';
import 'dart:io';
import '../state/cv_provider.dart';
import '../services/pdf_service.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  bool _isGenerating = false;
  Uint8List? _pdfBytes;
  String? _pdfPath;
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekspor CV'),
        actions: [
          if (_pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadPDF(context),
              tooltip: 'Download PDF',
            ),
          if (_pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _sharePDF(context),
              tooltip: 'Bagikan PDF',
            ),
        ],
      ),
      body: Consumer<CVProvider>(
        builder: (context, cvProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Template Selection Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.palette,
                          size: 60,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Pilih Template CV',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Template Options
                        _buildTemplateOption(
                          context,
                          'ATS Friendly',
                          'Template sederhana yang mudah dibaca ATS',
                          Icons.description,
                          CVTemplate.ats,
                          cvProvider.selectedTemplate == CVTemplate.ats,
                        ),
                        const SizedBox(height: 8),
                        _buildTemplateOption(
                          context,
                          'Creative',
                          'Template dengan desain kreatif dan warna',
                          Icons.palette,
                          CVTemplate.creative,
                          cvProvider.selectedTemplate == CVTemplate.creative,
                        ),
                        const SizedBox(height: 8),
                        _buildTemplateOption(
                          context,
                          'Modern',
                          'Template dua kolom dengan tampilan modern',
                          Icons.dashboard,
                          CVTemplate.modern,
                          cvProvider.selectedTemplate == CVTemplate.modern,
                        ),
                        const SizedBox(height: 8),
                        _buildTemplateOption(
                          context,
                          'Minimal',
                          'Template minimalis dengan fokus pada konten',
                          Icons.horizontal_split,
                          CVTemplate.minimal,
                          cvProvider.selectedTemplate == CVTemplate.minimal,
                        ),

                        const SizedBox(height: 20),

                        // Generate PDF Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating ? null : () => _generatePDF(context),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            icon: _isGenerating
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(Icons.picture_as_pdf),
                            label: Text(
                              _isGenerating ? 'Membuat PDF...' : 'Generate PDF',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),

                        if (_pdfBytes != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showPreview = !_showPreview;
                                    });
                                  },
                                  icon: Icon(_showPreview ? Icons.visibility_off : Icons.visibility),
                                  label: Text(_showPreview ? 'Sembunyikan Pratinjau' : 'Lihat Pratinjau'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // PDF Preview
                if (_showPreview && _pdfBytes != null)
                  Container(
                    height: 500,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: PDFView(
                      pdfData: _pdfBytes,
                      swipeHorizontal: true,
                      autoSpacing: true,
                      pageFling: true,
                      onError: (error) {
                        debugPrint('PDF Error: $error');
                      },
                      onPageError: (page, error) {
                        debugPrint('Page $page error: $error');
                      },
                    ),
                  ),

                // Progress Card
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Pastikan data CV Anda sudah lengkap sebelum generate PDF',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: cvProvider.cvProgress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kelengkapan Data',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Text(
                              '${(cvProvider.cvProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemplateOption(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      CVTemplate template,
      bool isSelected,
      ) {
    return InkWell(
      onTap: () {
        context.read<CVProvider>().setTemplate(template);
        setState(() {
          _pdfBytes = null;
          _showPreview = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.shade50 : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue : null,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePDF(BuildContext context) async {
    setState(() {
      _isGenerating = true;
      _pdfBytes = null;
    });

    try {
      final cvProvider = context.read<CVProvider>();

      final pdfBytes = await PDFService.generatePDFBytes(
        fullName: cvProvider.fullName,
        email: cvProvider.email,
        phone: cvProvider.phone,
        address: cvProvider.address,
        linkedin: cvProvider.linkedin,
        github: cvProvider.github,
        summary: cvProvider.summary,
        educations: cvProvider.educations,
        experiences: cvProvider.experiences,
        skills: cvProvider.skills,
        template: cvProvider.selectedTemplate,
        profileImage: cvProvider.profileImage.isNotEmpty
            ? cvProvider.profileImage
            : null,
      );

      // Simpan ke file temporary untuk preview
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_cv_preview.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      setState(() {
        _pdfBytes = pdfBytes;
        _pdfPath = tempFile.path;
        _isGenerating = false;
        _showPreview = true;
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF berhasil dibuat!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadPDF(BuildContext context) async {
    // Cek ketersediaan file
    if (_pdfPath == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada file PDF untuk di-download'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_pdfBytes == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data PDF kosong'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (!context.mounted) return;
      final cvProvider = context.read<CVProvider>();
      final fileName = 'CV_${cvProvider.fullName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Ambil path folder Downloads
      Directory downloadDir = await getDownloadDirectory();

      // Buat folder CV jika belum ada (opsional, bisa langsung di Downloads)
      final cvFolder = Directory('${downloadDir.path}/CV_Mahasiswa');
      if (!await cvFolder.exists()) {
        await cvFolder.create();
      }

      // Simpan file di Downloads/CV_Mahasiswa/
      final savedFile = File('${cvFolder.path}/$fileName');
      await savedFile.writeAsBytes(_pdfBytes!);

      if (!context.mounted) return;

      // Tampilkan notifikasi sukses (TANPA tombol buka)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF berhasil di-download ke: Downloads/CV_Mahasiswa/$fileName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4), // Cukup 4 detik
        ),
      );

    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal download: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _sharePDF(BuildContext context) async {
    if (_pdfPath == null) return;

    try {
      final fullName = context.read<CVProvider>().fullName;

      await Share.shareXFiles(
        [XFile(_pdfPath!)],
        text: 'CV - $fullName',
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}