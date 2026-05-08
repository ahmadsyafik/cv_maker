import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart'; 
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
  File? _savedFile;

  // Fungsi baru: Request izin berdasarkan versi Android
  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    
    Permission targetPermission;
    
    if (sdkInt >= 33) { // Android 13+ (API 33+)
      // Untuk Android 13+, kita minta izin notifikasi saja
      // Izin storage tidak diperlukan karena pakai file_saver
      targetPermission = Permission.notification;
    } else if (sdkInt >= 29) { // Android 10-12 (API 29-32)
      // Di Android 10-12, kita tidak perlu izin storage untuk menyimpan ke Downloads
      // Tapi untuk kompatibilitas, tetap cek izin notifikasi
      targetPermission = Permission.notification;
    } else { // Android 9 ke bawah (API 28 ke bawah)
      targetPermission = Permission.storage;
    }
    
    // Minta izin
    final status = await targetPermission.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Izin Diperlukan'),
            content: Text('Mohon berikan izin ${targetPermission == Permission.storage ? 'storage' : 'notifikasi'} di pengaturan'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    
    return false;
  }

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
        actions: [
          if (_savedFile != null)
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: () => _openPDF(),
              tooltip: 'Buka PDF',
            ),
          if (_savedFile != null)
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
                // Card Progress (sama seperti sebelumnya)
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

                // Card Pilih Template (sama seperti sebelumnya)
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

                        // Tombol Generate & Buka Langsung
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating || !isDataComplete
                                ? null
                                : () => _generateAndOpenPDF(),
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
                                : const Icon(Icons.picture_as_pdf),
                            label: Text(
                              _isGenerating
                                  ? 'Membuat PDF...'
                                  : !isDataComplete
                                      ? 'Lengkapi Data Dulu'
                                      : 'Buat & Buka CV',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Tombol Share
                        if (_savedFile != null)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _sharePDF,
                              icon: const Icon(Icons.share),
                              label: const Text('Bagikan CV'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                if (_savedFile != null) ...[
                  const SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, size: 48, color: Colors.green),
                          const SizedBox(height: 8),
                          const Text(
                            'CV Berhasil Dibuat!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _openPDF,
                            icon: const Icon(Icons.visibility),
                            label: const Text('Buka CV Sekarang'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
          _savedFile = null;
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

  // Fungsi utama: Generate dan langsung buka PDF (DIREFACTOR)
  Future<void> _generateAndOpenPDF() async {
  // Simpan dependency sebelum async gap
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final cvProvider = context.read<CVProvider>();

  // Request permission
  final hasPermission = await _requestStoragePermission();

  // Cegah lanjut jika widget dispose / izin ditolak
  if (!mounted || !hasPermission) return;

  // Aktifkan loading
  setState(() {
    _isGenerating = true;
  });

  try {
    // Validasi kelengkapan CV
    if (cvProvider.cvProgress < 1.0) {
      throw Exception('Data CV belum lengkap');
    }

    // Generate PDF bytes
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
      profileImage:
          cvProvider.fotoCV.isNotEmpty ? cvProvider.fotoCV : null,
    );

    // Simpan PDF
    final savedFile = await _savePDFModern(
      pdfBytes,
      cvProvider.fullName,
    );

    // Pastikan widget masih aktif
    if (!mounted) return;

    // Update state
    setState(() {
      _savedFile = savedFile;
      _isGenerating = false;
    });

    // Buka PDF otomatis
    await _openPDF();

    // Pastikan widget masih aktif
    if (!mounted) return;

    // Success snackbar
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          'CV berhasil dibuat di:\n${savedFile.path}',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  } catch (e) {
    // Pastikan widget masih aktif
    if (!mounted) return;

    // Nonaktifkan loading
    setState(() {
      _isGenerating = false;
    });

    // Error snackbar
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Gagal membuat CV: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  // New Method: Save PDF compatible with all Android versions
  Future<File> _savePDFModern(Uint8List pdfBytes, String fullName) async {
    final fileName = 'CV_${fullName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    
    Directory saveDir;
    
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      if (sdkInt >= 29) { 
        // Android 10+ (API 29+)
        // Simpan di App-specific directory di External Storage
        // Tidak perlu izin WRITE_EXTERNAL_STORAGE
        final externalDir = await getExternalStorageDirectory();
        saveDir = Directory('${externalDir?.path}/CV_Maker');
        
        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }
        
        // Show Message File Location
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CV tersimpan di: ${saveDir.path}'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Android 9 ke bawah
        // Bisa pakai Downloads folder
        const downloadsPath = '/storage/emulated/0/Download';
        saveDir = Directory('$downloadsPath/CV_Maker');
        
        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }
      }
    } else {
      // iOS
      final tempDir = await getTemporaryDirectory();
      saveDir = Directory('${tempDir.path}/CV_Maker');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }
    }
    
    final file = File('${saveDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    
    return file;
  }

  /// old method - fallback
  // Future<File> _savePDF(Uint8List pdfBytes, String fullName) async {
  //   return await _savePDFModern(pdfBytes, fullName);
  // }

  // Buka PDF dengan aplikasi default
  Future<void> _openPDF() async {
    if (_savedFile == null) return;
    
    try {
      final result = await OpenFile.open(_savedFile!.path);
      
      if (result.type == ResultType.noAppToOpen) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada aplikasi pembaca PDF. Silakan install Adobe Acrobat atau Google PDF Viewer.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Share PDF
  Future<void> _sharePDF() async {
    if (_savedFile == null) return;

    try {
      final cvProvider = context.read<CVProvider>();
      await Share.shareXFiles(
        [XFile(_savedFile!.path)],
        text: 'CV - ${cvProvider.fullName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}