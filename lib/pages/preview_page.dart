import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../services/pdf_service.dart';
import '../state/cv_provider.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  Uint8List? _pdfBytes;
  bool _isLoading = false;
  String? _error;

  // Fingerprint tracks last-generated state so we only re-generate when data changes
  String _lastFingerprint = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryGenerate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Triggered when Provider data changes
    final cv = context.read<CVProvider>();
    final fp = _fingerprint(cv);
    if (fp != _lastFingerprint && !_isLoading) {
      _tryGenerate();
    }
  }

  String _fingerprint(CVProvider cv) =>
      '${cv.fullName}|${cv.email}|${cv.phone}|${cv.address}|${cv.summary}|'
      '${cv.linkedin}|${cv.github}|${cv.fotoCV}|'
      '${cv.selectedTemplate.name}|'
      '${cv.educations.length}|${cv.experiences.length}|'
      '${cv.skills.length}|${cv.achievements.length}|${cv.publications.length}';

  Future<void> _tryGenerate() async {
    if (!mounted) return;
    final cv = context.read<CVProvider>();
    final fp = _fingerprint(cv);
    if (fp == _lastFingerprint && _pdfBytes != null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bytes = await PDFService.generatePDFBytes(
        fullName: cv.fullName,
        email: cv.email,
        phone: cv.phone,
        address: cv.address,
        linkedin: cv.linkedin,
        github: cv.github,
        summary: cv.summary,
        educations: cv.educations,
        experiences: cv.experiences,
        skills: cv.skills,
        achievements: cv.achievements,
        publications: cv.publications,
        template: cv.selectedTemplate,
        profileImage: cv.fotoCV.isNotEmpty ? cv.fotoCV : null,
      );
      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _lastFingerprint = fp;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _forceRefresh() {
    setState(() {
      _lastFingerprint = '';
      _pdfBytes = null;
    });
    _tryGenerate();
  }

  void _showTemplateSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer<CVProvider>(
        builder: (ctx, cvProvider, _) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollCtrl) => Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
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
                const SizedBox(height: 16),
                const Text('Pilih Template CV',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Pilih desain CV yang kamu suka',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    children: [
                      _templateTile(
                          ctx,
                          cvProvider,
                          CVTemplate.ats,
                          'ATS Friendly v1',
                          Icons.description_outlined,
                          'Single-column bersih, foto kiri atas'),
                      const SizedBox(height: 10),
                      _templateTile(
                          ctx,
                          cvProvider,
                          CVTemplate.ats2,
                          'ATS Friendly v2',
                          Icons.article_outlined,
                          'Header navy gelap, layout profesional'),
                      const SizedBox(height: 10),
                      _templateTile(
                          ctx,
                          cvProvider,
                          CVTemplate.creative,
                          'Creative v1',
                          Icons.palette_outlined,
                          'Sidebar biru, dua kolom elegan'),
                      const SizedBox(height: 10),
                      _templateTile(
                          ctx,
                          cvProvider,
                          CVTemplate.creative2,
                          'Creative v2',
                          Icons.brush_outlined,
                          'Header merah, dua kolom modern'),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _templateTile(BuildContext ctx, CVProvider cvProvider,
      CVTemplate template, String label, IconData icon, String desc) {
    final selected = cvProvider.selectedTemplate == template;
    return GestureDetector(
      onTap: () {
        cvProvider.setTemplate(template);
        Navigator.pop(ctx);
        _forceRefresh();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1565C0) : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                    selected ? const Color(0xFF1565C0) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? Colors.white : Colors.grey.shade600,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? const Color(0xFF1565C0)
                              : Colors.black87)),
                  Text(desc,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF1565C0), size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to CVProvider to trigger didChangeDependencies
    context.watch<CVProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text('Pratinjau CV',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.layers_outlined),
          tooltip: 'Pilih Template',
          onPressed: _showTemplateSelector,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Perbarui',
            onPressed: _forceRefresh,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
            ),
            SizedBox(height: 16),
            Text('Menyiapkan dokumen CV...',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
              const SizedBox(height: 12),
              const Text('Gagal memuat pratinjau',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _forceRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Belum ada data CV',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _forceRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Pratinjau'),
            ),
          ],
        ),
      );
    }

    // Render PDF — PdfPreview dari package printing supports pinch-zoom natively
    // dan cross-platform (web, Android, iOS)
    return PdfPreview(
      // Key berubah hanya kalau bytes baru supaya tidak reload terus
      key: ValueKey(_lastFingerprint),
      build: (format) => _pdfBytes!,
      useActions: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      allowSharing: false,
      allowPrinting: false,
      initialPageFormat: PdfPageFormat.a4,
      maxPageWidth: 900,
      // Enable zoom
      scrollViewDecoration: BoxDecoration(color: Colors.grey.shade300),
      pdfPreviewPageDecoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      onError: (context, error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
