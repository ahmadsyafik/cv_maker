import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
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

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  Future<void> _generatePreview() async {
    setState(() {
      _isLoading = true;
      _error = null;
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

      setState(() {
        _pdfBytes = pdfBytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview CV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generatePreview,
          ),
          Consumer<CVProvider>(
            builder: (context, cvProvider, child) {
              return PopupMenuButton<CVTemplate>(
                icon: const Icon(Icons.palette),
                onSelected: (template) {
                  cvProvider.setTemplate(template);
                  _generatePreview();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: CVTemplate.ats,
                    child: Text('ATS Friendly'),
                  ),
                  const PopupMenuItem(
                    value: CVTemplate.creative,
                    child: Text('Creative'),
                  ),
                  const PopupMenuItem(
                    value: CVTemplate.modern,
                    child: Text('Modern'),
                  ),
                  const PopupMenuItem(
                    value: CVTemplate.minimal,
                    child: Text('Minimal'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<CVProvider>(
        builder: (context, cvProvider, child) {
          if (_isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Membuat preview PDF...'),
                ],
              ),
            );
          }

          if (_error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _generatePreview,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (_pdfBytes == null) {
            return const Center(
              child: Text('Tidak ada data untuk ditampilkan'),
            );
          }

          return PDFView(
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
          );
        },
      ),
    );
  }
}