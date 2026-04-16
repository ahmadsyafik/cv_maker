import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../state/cv_provider.dart';
import '../services/pdf_service.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _error;
  CVTemplate? _currentTemplate; // Track current template

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  Future<void> _generatePreview() async {
    final cvProvider = context.read<CVProvider>();
    
    // Only regenerate if template changed or first time
    if (_currentTemplate == cvProvider.selectedTemplate && _pdfBytes != null) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
      _currentTemplate = cvProvider.selectedTemplate;
    });

    try {
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
        profileImage: cvProvider.profileImage.isNotEmpty ? cvProvider.profileImage : null,
      );

      if (mounted) {
        setState(() {
          _pdfBytes = pdfBytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Preview CV'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _currentTemplate = null; // Force refresh
                _generatePreview();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Template Selector
          Container(
            height: 110,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Consumer<CVProvider>(
              builder: (context, cvProvider, child) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildTemplateItem(
                      context,
                      template: CVTemplate.ats,
                      label: 'ATS Friendly',
                      icon: Icons.description_outlined,
                      isSelected: cvProvider.selectedTemplate == CVTemplate.ats,
                    ),
                    _buildTemplateItem(
                      context,
                      template: CVTemplate.creative,
                      label: 'Creative',
                      icon: Icons.palette_outlined,
                      isSelected: cvProvider.selectedTemplate == CVTemplate.creative,
                    ),
                    _buildTemplateItem(
                      context,
                      template: CVTemplate.modern,
                      label: 'Modern',
                      icon: Icons.grid_view_rounded,
                      isSelected: cvProvider.selectedTemplate == CVTemplate.modern,
                    ),
                    _buildTemplateItem(
                      context,
                      template: CVTemplate.minimal,
                      label: 'Minimal',
                      icon: Icons.short_text_rounded,
                      isSelected: cvProvider.selectedTemplate == CVTemplate.minimal,
                    ),
                  ],
                );
              },
            ),
          ),

          // PDF Previewer
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateItem(
    BuildContext context, {
    required CVTemplate template,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        // Update provider
        context.read<CVProvider>().setTemplate(template);
        
        // Force regenerate preview dengan template baru
        setState(() {
          _currentTemplate = null;
          _isLoading = true;
        });
        
        // Generate preview baru
        await _generatePreview();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 16),
            Text('Menyiapkan dokumen...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red[300], size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentTemplate = null;
                    _generatePreview();
                  });
                }, 
                child: const Text('Coba Lagi')
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes == null) {
      return const Center(
        child: Text('Tidak ada preview'),
      );
    }

    // PERUBAHAN: Tambahkan key dengan ValueKey untuk memaksa refresh
    return PdfPreview(
      key: ValueKey(_currentTemplate), // <<< INI YANG PENTING!
      build: (format) => _pdfBytes!,
      useActions: true,
      canChangePageFormat: true,
      canChangeOrientation: true,
      canDebug: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      loadingWidget: const CircularProgressIndicator(),
      pdfPreviewPageDecoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 1),
        ],
      ),
      onError: (context, error) {
        print('PDF Preview Error: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Gagal memuat PDF: ${error.toString()}'),
              ElevatedButton(
                onPressed: _generatePreview,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );
      },
    );
  }
}