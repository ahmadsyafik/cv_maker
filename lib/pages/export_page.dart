import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Download CV',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<CVProvider>(
        builder: (context, cvProvider, child) {
          final isDataComplete = cvProvider.cvProgress >= 1.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Card Progress
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
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
                                'Pastikan data CV Anda sudah lengkap 100%',
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Card Template
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
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
                          'ATS Friendly v1',
                          'Clean single-column, foto pojok kiri',
                          Icons.description,
                          CVTemplate.ats,
                          cvProvider.selectedTemplate == CVTemplate.ats,
                        ),
                        const SizedBox(height: 8),
                        _buildTemplateOption(
                          context,
                          'ATS Friendly v2',
                          'Header navy gelap, layout profesional',
                          Icons.article,
                          CVTemplate.ats2,
                          cvProvider.selectedTemplate == CVTemplate.ats2,
                        ),
                        const SizedBox(height: 8),
                        _buildTemplateOption(
                          context,
                          'Creative v1',
                          'Sidebar biru, dua kolom elegan',
                          Icons.palette,
                          CVTemplate.creative,
                          cvProvider.selectedTemplate == CVTemplate.creative,
                        ),
                        const SizedBox(height: 8),
                        _buildTemplateOption(
                          context,
                          'Creative v2',
                          'Header merah, dua kolom modern',
                          Icons.brush,
                          CVTemplate.creative2,
                          cvProvider.selectedTemplate == CVTemplate.creative2,
                        ),

                        const SizedBox(height: 24),

                        // Tombol Simpan CV
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating || !isDataComplete
                                ? null
                                : () => _saveCV(cvProvider),
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
                                : const Icon(Icons.save),
                            label: Text(
                              _isGenerating
                                  ? 'Membuat PDF...'
                                  : !isDataComplete
                                      ? 'Lengkapi Data Dulu'
                                      : 'Simpan CV',
                              style: const TextStyle(fontSize: 16),
                            ),
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
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.shade50 : Colors.white,
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

  // ==================== FUNGSI SIMPAN CV ====================
  
  Future<void> _saveCV(CVProvider cvProvider) async {
    setState(() {
      _isGenerating = true;
    });

    try {
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
        achievements: cvProvider.achievements,
        publications: cvProvider.publications,
        template: cvProvider.selectedTemplate,
        profileImage: cvProvider.fotoCV.isNotEmpty ? cvProvider.fotoCV : null,
      );

      // Buka file picker untuk pilih lokasi simpan
      String? outputPath = await FilePicker.saveFile(
        dialogTitle: 'Simpan CV',
        fileName: 'CV_${cvProvider.fullName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: pdfBytes,
      );

      if (!mounted) return;

      if (outputPath != null) {
        setState(() {
          _isGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ CV berhasil disimpan'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penyimpanan dibatalkan'),
            backgroundColor: Colors.orange,
          ),
        );
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal menyimpan CV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}