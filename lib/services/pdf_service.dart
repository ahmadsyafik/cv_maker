import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/education.dart';
import '../models/experience.dart';
import '../models/skill.dart';
import '../state/cv_provider.dart';

class PDFService {
  static late pw.Font _regularFont;
  static late pw.Font _boldFont;
  static late pw.Font _italicFont;
  static bool _fontsLoaded = false;

  // Load fonts dari assets (fallback)
  static Future<void> _loadFontsFromAssets() async {
    try {
      final regularFontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      final italicFontData = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');

      _regularFont = pw.Font.ttf(regularFontData.buffer.asByteData());
      _boldFont = pw.Font.ttf(boldFontData.buffer.asByteData());
      _italicFont = pw.Font.ttf(italicFontData.buffer.asByteData());

      _fontsLoaded = true;
      debugPrint('Fonts loaded from assets successfully');
    } catch (e) {
      debugPrint('Error loading fonts from assets: $e');
      // Fallback ke Helvetica
      _useFallbackFonts();
    }
  }

  // Fallback ke Helvetica
  static void _useFallbackFonts() {
    _regularFont = pw.Font.helvetica();
    _boldFont = pw.Font.helveticaBold();
    _italicFont = pw.Font.helveticaOblique();
    _fontsLoaded = true;
  }

  // Initialize fonts
  static Future<void> initializeFonts() async {
    if (!_fontsLoaded) {
      await _loadFontsFromAssets();
    }
  }

  // Get theme data
  static Future<pw.ThemeData> getTheme() async {
    await initializeFonts();
    return pw.ThemeData.withFont(
      base: _regularFont,
      bold: _boldFont,
      italic: _italicFont,
    );
  }

  // Text style helper
  static pw.TextStyle textStyle({
    double fontSize = 11,
    pw.FontWeight? fontWeight,
    pw.FontStyle? fontStyle,
    PdfColor? color,
  }) {
    pw.Font font = _regularFont;

    if (fontWeight == pw.FontWeight.bold) {
      font = _boldFont;
    } else if (fontStyle == pw.FontStyle.italic) {
      font = _italicFont;
    }

    return pw.TextStyle(
      font: font,
      fontSize: fontSize,
      color: color,
    );
  }

  // Generate PDF File
  static Future<File> generateCV({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String linkedin,
    required String github,
    required String summary,
    required List<Education> educations,
    required List<Experience> experiences,
    required List<Skill> skills,
    CVTemplate template = CVTemplate.ats,
    String? profileImage,
  }) async {
    await initializeFonts();

    final pdf = pw.Document(
      theme: await getTheme(),
    );

    switch (template) {
      case CVTemplate.ats:
        _buildATSTemplate(pdf, fullName, email, phone, address, linkedin,
            github, summary, educations, experiences, skills, profileImage);
        break;
      case CVTemplate.creative:
        _buildCreativeTemplate(pdf, fullName, email, phone, address, linkedin,
            github, summary, educations, experiences, skills, profileImage);
        break;
      case CVTemplate.modern:
        _buildModernTemplate(pdf, fullName, email, phone, address, linkedin,
            github, summary, educations, experiences, skills, profileImage);
        break;
      case CVTemplate.minimal:
        _buildMinimalTemplate(pdf, fullName, email, phone, address, linkedin,
            github, summary, educations, experiences, skills, profileImage);
        break;
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/cv_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Generate PDF Bytes untuk preview
  static Future<Uint8List> generatePDFBytes({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String linkedin,
    required String github,
    required String summary,
    required List<Education> educations,
    required List<Experience> experiences,
    required List<Skill> skills,
    CVTemplate template = CVTemplate.ats,
    String? profileImage,
  }) async {
    await initializeFonts();

    final pdf = pw.Document(
      theme: await getTheme(),
    );

    switch (template) {
      case CVTemplate.ats:
        _buildATSTemplate(pdf, fullName, email, phone, address, linkedin,
            github, summary, educations, experiences, skills, profileImage);
        break;
      case CVTemplate.creative:
        _buildCreativeTemplate(pdf, fullName, email, phone, address, linkedin,
            github, summary, educations, experiences, skills, profileImage);
        break;
      case CVTemplate.modern:
        _buildModernTemplate(pdf, fullName, email, phone, address, linkedin,
            github, summary, educations, experiences, skills, profileImage);
        break;
      case CVTemplate.minimal:
        _buildMinimalTemplate(pdf, fullName, email, phone, address, linkedin,
            github, summary, educations, experiences, skills, profileImage);
        break;
    }

    return await pdf.save();
  }

  // ============= TEMPLATE ATS =============
  static void _buildATSTemplate(
      pw.Document pdf,
      String fullName,
      String email,
      String phone,
      String address,
      String linkedin,
      String github,
      String summary,
      List<Education> educations,
      List<Experience> experiences,
      List<Skill> skills,
      String? profileImage,
      ) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    fullName.toUpperCase(),
                    style: textStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ).copyWith(letterSpacing: 2),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    email,
                    style: textStyle(fontSize: 11),
                  ),
                  pw.Text(
                    '$phone | $address',
                    style: textStyle(fontSize: 11),
                  ),
                  if (linkedin.isNotEmpty || github.isNotEmpty)
                    pw.Text(
                      [linkedin, github].where((s) => s.isNotEmpty).join(' | '),
                      style: textStyle(fontSize: 11),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Summary
            if (summary.isNotEmpty) ...[
              _buildATSSection('PROFESSIONAL SUMMARY'),
              pw.SizedBox(height: 4),
              pw.Text(summary, style: textStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
            ],

            // Education
            if (educations.isNotEmpty) ...[
              _buildATSSection('EDUCATION'),
              ...educations.map((edu) => _buildATSEducation(edu)),
              pw.SizedBox(height: 16),
            ],

            // Experience
            if (experiences.isNotEmpty) ...[
              _buildATSSection('WORK EXPERIENCE'),
              ...experiences.map((exp) => _buildATSExperience(exp)),
              pw.SizedBox(height: 16),
            ],

            // Skills
            if (skills.isNotEmpty) ...[
              _buildATSSection('SKILLS'),
              pw.Wrap(
                spacing: 8,
                runSpacing: 4,
                children: skills.map((skill) =>
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(skill.name, style: textStyle(fontSize: 10)),
                    ),
                ).toList(),
              ),
            ],
          ];
        },
      ),
    );
  }

  static pw.Widget _buildATSSection(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          height: 1,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: textStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ).copyWith(letterSpacing: 1),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildATSEducation(Education edu) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                edu.university,
                style: textStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              ),
              pw.Text(
                '${edu.startYear} - ${edu.endYear}',
                style: textStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Text(edu.major, style: textStyle(fontSize: 11)),
          if (edu.gpa != null)
            pw.Text('IPK: ${edu.gpa}', style: textStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildATSExperience(Experience exp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                exp.position,
                style: textStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              ),
              pw.Text(
                '${exp.startYear} - ${exp.endYear}',
                style: textStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Text(exp.organization,
              style: textStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 4),
          pw.Text(exp.description, style: textStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // ============= TEMPLATE CREATIVE =============
  static void _buildCreativeTemplate(
      pw.Document pdf,
      String fullName,
      String email,
      String phone,
      String address,
      String linkedin,
      String github,
      String summary,
      List<Education> educations,
      List<Experience> experiences,
      List<Skill> skills,
      String? profileImage,
      ) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column
                pw.Container(
                  width: 180,
                  color: PdfColors.blue700,
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Profile Image or Initial
                      pw.Container(
                        width: 100,
                        height: 100,
                        decoration: const pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColors.white,
                        ),
                        child: profileImage != null && profileImage.isNotEmpty
                            ? pw.ClipOval(
                          child: pw.Image(
                            pw.MemoryImage(
                              File(profileImage).readAsBytesSync(),
                            ),
                            fit: pw.BoxFit.cover,
                          ),
                        )
                            : pw.Center(
                          child: pw.Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                            style: textStyle(
                              fontSize: 40,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 20),

                      // Contact Info
                      pw.Text(
                        'KONTAK',
                        style: textStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ).copyWith(letterSpacing: 2),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(height: 2, color: PdfColors.white),
                      pw.SizedBox(height: 10),

                      _buildCreativeContact('📞', phone, isWhite: true),
                      _buildCreativeContact('✉️', email, isWhite: true),
                      _buildCreativeContact('📍', address, isWhite: true),
                      if (linkedin.isNotEmpty)
                        _buildCreativeContact('🔗', linkedin, isWhite: true),
                      if (github.isNotEmpty)
                        _buildCreativeContact('💻', github, isWhite: true),

                      pw.SizedBox(height: 20),

                      // Skills
                      pw.Text(
                        'SKILLS',
                        style: textStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ).copyWith(letterSpacing: 2),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(height: 2, color: PdfColors.white),
                      pw.SizedBox(height: 10),
                      ...skills.map((skill) =>
                          pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 8),
                            child: pw.Text(
                              '• ${skill.name}',
                              style: textStyle(color: PdfColors.white, fontSize: 11),
                            ),
                          ),
                      ),
                    ],
                  ),
                ),

                // Right Column
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          fullName,
                          style: textStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          width: 60,
                          height: 3,
                          color: PdfColors.blue700,
                        ),

                        // Summary
                        if (summary.isNotEmpty) ...[
                          pw.SizedBox(height: 20),
                          pw.Text(
                            'PROFIL',
                            style: textStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(summary, style: textStyle(fontSize: 11)),
                        ],

                        // Education
                        if (educations.isNotEmpty) ...[
                          pw.SizedBox(height: 20),
                          pw.Text(
                            'PENDIDIKAN',
                            style: textStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          ...educations.map((edu) =>
                              pw.Container(
                                margin: const pw.EdgeInsets.only(bottom: 12),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      edu.university,
                                      style: textStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    pw.Text(edu.major, style: textStyle(fontSize: 11)),
                                    pw.Text(
                                      '${edu.startYear} - ${edu.endYear}',
                                      style: textStyle(
                                        fontSize: 10,
                                        color: PdfColors.grey600,
                                      ),
                                    ),
                                    if (edu.gpa != null)
                                      pw.Text('IPK: ${edu.gpa}',
                                          style: textStyle(fontSize: 10)),
                                  ],
                                ),
                              ),
                          ),
                        ],

                        // Experience
                        if (experiences.isNotEmpty) ...[
                          pw.SizedBox(height: 20),
                          pw.Text(
                            'PENGALAMAN',
                            style: textStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          ...experiences.map((exp) =>
                              pw.Container(
                                margin: const pw.EdgeInsets.only(bottom: 12),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      exp.position,
                                      style: textStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    pw.Text(
                                      exp.organization,
                                      style: textStyle(
                                        fontSize: 11,
                                        fontStyle: pw.FontStyle.italic,
                                      ),
                                    ),
                                    pw.Text(
                                      '${exp.startYear} - ${exp.endYear}',
                                      style: textStyle(
                                        fontSize: 10,
                                        color: PdfColors.grey600,
                                      ),
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Text(exp.description,
                                        style: textStyle(fontSize: 10)),
                                  ],
                                ),
                              ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );
  }

  static pw.Widget _buildCreativeContact(String icon, String text, {bool isWhite = false}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Text(icon, style: textStyle(
            color: isWhite ? PdfColors.white : PdfColors.black,
            fontSize: 12,
          )),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              text,
              style: textStyle(
                color: isWhite ? PdfColors.white : PdfColors.black,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============= TEMPLATE MODERN =============
  static void _buildModernTemplate(
      pw.Document pdf,
      String fullName,
      String email,
      String phone,
      String address,
      String linkedin,
      String github,
      String summary,
      List<Education> educations,
      List<Experience> experiences,
      List<Skill> skills,
      String? profileImage,
      ) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header with name
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 2),
                ),
              ),
              child: pw.Row(
                children: [
                  if (profileImage != null && profileImage.isNotEmpty)
                    pw.Container(
                      width: 70,
                      height: 70,
                      margin: const pw.EdgeInsets.only(right: 16),
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        image: pw.DecorationImage(
                          image: pw.MemoryImage(
                            File(profileImage).readAsBytesSync(),
                          ),
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          fullName,
                          style: textStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          email,
                          style: textStyle(fontSize: 11, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Two column layout
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildModernSection('CONTACT'),
                      pw.SizedBox(height: 8),
                      _buildModernInfo('Phone', phone),
                      _buildModernInfo('Email', email),
                      _buildModernInfo('Address', address),
                      if (linkedin.isNotEmpty) _buildModernInfo('LinkedIn', linkedin),
                      if (github.isNotEmpty) _buildModernInfo('GitHub', github),

                      pw.SizedBox(height: 20),

                      _buildModernSection('SKILLS'),
                      pw.SizedBox(height: 8),
                      ...skills.map((skill) =>
                          pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 6),
                            child: pw.Row(
                              children: [
                                pw.Container(
                                  width: 6,
                                  height: 6,
                                  margin: const pw.EdgeInsets.only(right: 8),
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColors.blueGrey400,
                                    shape: pw.BoxShape.circle,
                                  ),
                                ),
                                pw.Text(skill.name, style: textStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(width: 20),

                // Right Column
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Summary
                      if (summary.isNotEmpty) ...[
                        _buildModernSection('PROFILE'),
                        pw.SizedBox(height: 4),
                        pw.Text(summary, style: textStyle(fontSize: 10)),
                        pw.SizedBox(height: 16),
                      ],

                      // Education
                      if (educations.isNotEmpty) ...[
                        _buildModernSection('EDUCATION'),
                        pw.SizedBox(height: 8),
                        ...educations.map((edu) => _buildModernEducation(edu)),
                        pw.SizedBox(height: 16),
                      ],

                      // Experience
                      if (experiences.isNotEmpty) ...[
                        _buildModernSection('EXPERIENCE'),
                        pw.SizedBox(height: 8),
                        ...experiences.map((exp) => _buildModernExperience(exp)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );
  }

  static pw.Widget _buildModernSection(String title) {
    return pw.Text(
      title,
      style: textStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey800,
      ).copyWith(letterSpacing: 1),
    );
  }

  static pw.Widget _buildModernInfo(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Container(
            width: 70,
            child: pw.Text(
              label,
              style: textStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: textStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildModernEducation(Education edu) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            edu.university,
            style: textStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.Text(
            edu.major,
            style: textStyle(fontSize: 10),
          ),
          pw.Text(
            '${edu.startYear} - ${edu.endYear}',
            style: textStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildModernExperience(Experience exp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            exp.position,
            style: textStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.Text(
            exp.organization,
            style: textStyle(
              fontSize: 10,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.Text(
            '${exp.startYear} - ${exp.endYear}',
            style: textStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            exp.description,
            style: textStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ============= TEMPLATE MINIMAL =============
  static void _buildMinimalTemplate(
      pw.Document pdf,
      String fullName,
      String email,
      String phone,
      String address,
      String linkedin,
      String github,
      String summary,
      List<Education> educations,
      List<Experience> experiences,
      List<Skill> skills,
      String? profileImage,
      ) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            // Simple Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    fullName,
                    style: textStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    email,
                    style: textStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    phone,
                    style: textStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  if (address.isNotEmpty)
                    pw.Text(
                      address,
                      style: textStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // Summary
            if (summary.isNotEmpty) ...[
              _buildMinimalSection(summary),
              pw.SizedBox(height: 16),
            ],

            // Education
            if (educations.isNotEmpty) ...[
              _buildMinimalSection('Education', isTitle: true),
              pw.SizedBox(height: 8),
              ...educations.map((edu) => _buildMinimalEducation(edu)),
              pw.SizedBox(height: 16),
            ],

            // Experience
            if (experiences.isNotEmpty) ...[
              _buildMinimalSection('Experience', isTitle: true),
              pw.SizedBox(height: 8),
              ...experiences.map((exp) => _buildMinimalExperience(exp)),
              pw.SizedBox(height: 16),
            ],

            // Skills
            if (skills.isNotEmpty) ...[
              _buildMinimalSection('Skills', isTitle: true),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 12,
                runSpacing: 8,
                children: skills.map((skill) =>
                    pw.Text(
                      '• ${skill.name}',
                      style: textStyle(fontSize: 10),
                    ),
                ).toList(),
              ),
            ],
          ];
        },
      ),
    );
  }

  static pw.Widget _buildMinimalSection(String content, {bool isTitle = false}) {
    if (isTitle) {
      return pw.Text(
        content.toUpperCase(),
        style: textStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ).copyWith(letterSpacing: 1),
      );
    }
    return pw.Text(
      content,
      style: textStyle(fontSize: 10).copyWith(height: 1.5),
    );
  }

  static pw.Widget _buildMinimalEducation(Education edu) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            edu.university,
            style: textStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            edu.major,
            style: textStyle(fontSize: 10),
          ),
          pw.Text(
            '${edu.startYear} - ${edu.endYear}',
            style: textStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMinimalExperience(Experience exp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            exp.position,
            style: textStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            exp.organization,
            style: textStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
          ),
          pw.Text(
            '${exp.startYear} - ${exp.endYear}',
            style: textStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            exp.description,
            style: textStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }
}