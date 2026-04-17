import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Downlaod CV',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadPDF(),
              tooltip: 'Download PDF',
            ),
          if (_pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _sharePDF(),
              tooltip: 'Share PDF',
            ),
        ],
      ),
      body: Consumer<CVProvider>(
        builder: (context, cvProvider, child) {
          final isDataComplete = cvProvider.cvProgress >= 1.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Card Progress Kelengkapan Data
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white, // Background putih
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDataComplete ? Colors.green.shade50 : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isDataComplete ? Icons.check_circle : Icons.info_outline,
                                color: isDataComplete ? Colors.green : Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Pastikan data CV Anda sudah lengkap 100% sebelum download',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: cvProvider.cvProgress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDataComplete ? Colors.green : Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kelengkapan Data',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: isDataComplete ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '${(cvProvider.cvProgress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDataComplete ? Colors.green : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        if (!isDataComplete) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50, // Abu-abu sangat muda
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Data belum lengkap. Silakan lengkapi data CV Anda terlebih dahulu di halaman sebelumnya.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Card Pilih Template
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white, // Background putih
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.palette, size: 60, color: Colors.blue),
                        const SizedBox(height: 16),
                        const Text(
                          'Pilih Template CV',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

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

                        const SizedBox(height: 24),

                        // Tombol Generate & Download
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating || !isDataComplete
                                ? null
                                : () => _generateAndDownloadPDF(context),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: isDataComplete ? const Color(0xFF1565C0) : Colors.grey,
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
                                : const Icon(Icons.download),
                            label: Text(
                              _isGenerating
                                  ? 'Membuat PDF...'
                                  : !isDataComplete
                                  ? 'Data Belum Lengkap'
                                  : 'Generate & Download PDF',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Informasi tambahan
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white, // Background putih
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_open, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lokasi Penyimpanan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Platform.isAndroid
                                    ? 'Download/CV/'
                                    : 'Folder CV',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
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
          _pdfPath = null;
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
          color: isSelected ? Colors.blue.shade50 : Colors.white, // Putih jika tidak selected
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey.shade600),
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
                      color: isSelected ? Colors.blue : Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndDownloadPDF(BuildContext context) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final cvProvider = context.read<CVProvider>();

      // Validasi ulang data lengkap
      if (cvProvider.cvProgress < 1.0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data CV belum lengkap. Silakan lengkapi data terlebih dahulu.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isGenerating = false;
        });
        return;
      }

      // Generate PDF
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
        profileImage: cvProvider.fotoCV.isNotEmpty ? cvProvider.fotoCV : null,
      );

      // Simpan ke temporary untuk share
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_cv.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      setState(() {
        _pdfBytes = pdfBytes;
        _pdfPath = tempFile.path;
        _isGenerating = false;
      });

      // Langsung download setelah generate
      await _downloadPDF();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF berhasil dibuat dan disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadPDF() async {
    if (_pdfPath == null || _pdfBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada file PDF untuk di-download'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final cvProvider = context.read<CVProvider>();
      final fileName = 'CV_${cvProvider.fullName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Untuk Android, gunakan getExternalStorageDirectory
      Directory? downloadDir;

      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir == null) {
          throw Exception('Tidak dapat mengakses storage eksternal');
        }

        // Path: /storage/emulated/0/Download/CV
        final basePath = externalDir.path.split('/Android/').first;
        downloadDir = Directory('$basePath/Download/CV');
      } else {
        // Untuk iOS atau platform lain
        final tempDir = await getTemporaryDirectory();
        downloadDir = Directory('${tempDir.path}/CV');
      }

      // Buat folder jika belum ada
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Simpan file
      final savedFile = File('${downloadDir.path}/$fileName');
      await savedFile.writeAsBytes(_pdfBytes!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF berhasil disimpan di:\n${downloadDir.path}/$fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal download: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _sharePDF() async {
    if (_pdfPath == null) return;

    try {
      final cvProvider = context.read<CVProvider>();
      final fullName = cvProvider.fullName;

      await Share.shareXFiles(
        [XFile(_pdfPath!)],
        text: 'CV - $fullName',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal share PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}