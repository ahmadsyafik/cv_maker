import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

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
  CVTemplate? _currentTemplate;

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  Future<void> _generatePreview() async {
    final cvProvider = context.read<CVProvider>();

    if (_currentTemplate == cvProvider.selectedTemplate && _pdfBytes != null) {
      return;
    }

    if (!mounted) return;

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
        profileImage: cvProvider.fotoCV.isNotEmpty ? cvProvider.fotoCV : null,
      );

      if (mounted) {
        setState(() {
          _pdfBytes = pdfBytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showTemplateSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Penting: biar bisa full height
      useSafeArea: true, // Menghindari notched area
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<CVProvider>(
          builder: (context, cvProvider, child) {
            return DraggableScrollableSheet(
              initialChildSize: 0.5, // Mulai dari 50% layar
              minChildSize: 0.4, // Minimal 40%
              maxChildSize: 0.9, // Maksimal 90%
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Pilih Template CV',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pilih desain CV yang kamu suka',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          shrinkWrap: true,
                          children: [
                            _buildBottomSheetTemplateItem(
                              context: context,
                              template: CVTemplate.ats,
                              label: 'ATS Friendly',
                              icon: Icons.description_outlined,
                              description: 'Template sederhana, mudah dibaca ATS',
                              isSelected: cvProvider.selectedTemplate == CVTemplate.ats,
                            ),
                            const SizedBox(height: 12),
                            _buildBottomSheetTemplateItem(
                              context: context,
                              template: CVTemplate.creative,
                              label: 'Creative',
                              icon: Icons.palette_outlined,
                              description: 'Template dengan desain kreatif dan warna',
                              isSelected: cvProvider.selectedTemplate == CVTemplate.creative,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetTemplateItem({
    required BuildContext context,
    required CVTemplate template,
    required String label,
    required IconData icon,
    required String description,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        context.read<CVProvider>().setTemplate(template);
        setState(() {
          _currentTemplate = null;
          _pdfBytes = null;
          _isLoading = true;
        });
        await _generatePreview();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0).withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
              ? Border.all(color: const Color(0xFF1565C0), width: 1.5) 
              : Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1565C0) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                color: Color(0xFF1565C0),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Pratinjau CV',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _showTemplateSelector,
          tooltip: 'Pilih Template',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _currentTemplate = null;
                _pdfBytes = null;
                _isLoading = true;
              });
              _generatePreview();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
              ),
              SizedBox(height: 16),
              Text(
                'Menyiapkan dokumen...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
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
              Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentTemplate = null;
                    _pdfBytes = null;
                    _isLoading = true;
                  });
                  _generatePreview();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada preview', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return PdfPreview(
      key: ValueKey(_currentTemplate),
      build: (format) => _pdfBytes!,
      useActions: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      loadingWidget: Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
          ),
        ),
      ),
      pdfPreviewPageDecoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 1),
        ],
      ),
      onError: (context, error) {
        debugPrint('PDF Preview Error: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Gagal memuat PDF: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentTemplate = null;
                    _pdfBytes = null;
                    _isLoading = true;
                  });
                  _generatePreview();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );
      },
    );
  }
}