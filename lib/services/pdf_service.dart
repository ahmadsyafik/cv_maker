import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/education.dart';
import 'dart:convert';
import 'dart:io';
import '../models/experience.dart';
import '../models/skill.dart';
import '../state/cv_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Warna tema yang digunakan di kedua template
// ─────────────────────────────────────────────────────────────────────────────
const _kBlue = PdfColor.fromInt(0xFF185FA5);       // Blue 600
const _kBlueLight = PdfColor.fromInt(0xFFE6F1FB);  // Blue 50
const _kBlueDark = PdfColor.fromInt(0xFF0C447C);   // Blue 800
const _kBlueSidebar = PdfColor.fromInt(0xFF1A5FA8); // sidebar background
const _kGrey800 = PdfColor.fromInt(0xFF333333);
const _kGrey700 = PdfColor.fromInt(0xFF555555);
const _kGrey600 = PdfColor.fromInt(0xFF777777);
const _kGrey300 = PdfColor.fromInt(0xFFCCCCCC);
const _kGrey100 = PdfColor.fromInt(0xFFF4F4F4);
const _kWhite = PdfColors.white;
const _kBlack = PdfColor.fromInt(0xFF111111);

class PDFService {
  static late pw.Font _regularFont;
  static late pw.Font _boldFont;
  static late pw.Font _italicFont;
  static bool _fontsLoaded = false;

  // ───────────────────────── Font Loading ─────────────────────────
  static Future<void> _loadFontsFromAssets() async {
    try {
      final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      final italicData = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');

      _regularFont = pw.Font.ttf(regularData.buffer.asByteData());
      _boldFont = pw.Font.ttf(boldData.buffer.asByteData());
      _italicFont = pw.Font.ttf(italicData.buffer.asByteData());
      _fontsLoaded = true;
      debugPrint('Fonts loaded from assets successfully');
    } catch (e) {
      debugPrint('Error loading fonts from assets: $e');
      _useFallbackFonts();
    }
  }

  static void _useFallbackFonts() {
    _regularFont = pw.Font.helvetica();
    _boldFont = pw.Font.helveticaBold();
    _italicFont = pw.Font.helveticaOblique();
    _fontsLoaded = true;
  }

  static Future<void> initializeFonts() async {
    if (!_fontsLoaded) await _loadFontsFromAssets();
  }

  static Future<pw.ThemeData> getTheme() async {
    await initializeFonts();
    return pw.ThemeData.withFont(
      base: _regularFont,
      bold: _boldFont,
      italic: _italicFont,
    );
  }

  // ───────────────────────── Text Style Helper ─────────────────────────
  static pw.TextStyle ts({
    double fontSize = 10,
    pw.FontWeight? fontWeight,
    pw.FontStyle? fontStyle,
    PdfColor? color,
    double? letterSpacing,
    double? lineSpacing,
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
      letterSpacing: letterSpacing,
      lineSpacing: lineSpacing,
    );
  }

  // ───────────────────────── Profile Image ─────────────────────────
  static Future<pw.MemoryImage?> loadProfileImage(String? profileImage) async {
    if (profileImage == null || profileImage.isEmpty) return null;
    try {
      Uint8List? bytes;
      if (profileImage.startsWith('http://') || profileImage.startsWith('https://')) {
        final res = await http.get(Uri.parse(profileImage));
        if (res.statusCode == 200) bytes = Uint8List.fromList(res.bodyBytes);
      } else if (profileImage.startsWith('/') || profileImage.contains(':')) {
        final file = File(profileImage);
        if (await file.exists()) bytes = await file.readAsBytes();
      } else if (profileImage.contains(',')) {
        bytes = Uint8List.fromList(base64Decode(profileImage.split(',').last));
      }
      if (bytes != null) return pw.MemoryImage(bytes);
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
    return null;
  }

  // ───────────────────────── Public API ─────────────────────────
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
    final pdf = pw.Document(theme: await getTheme());
    final photo = await loadProfileImage(profileImage);

    try {
      if (template == CVTemplate.ats) {
        _buildATSTemplate(pdf, fullName, email, phone, address, linkedin,
            github, summary, educations, experiences, skills, photo);
      } else {
        _buildCreativeTemplate(pdf, fullName, email, phone, address, linkedin,
            github, summary, educations, experiences, skills, photo);
      }
      return await pdf.save();
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (e.toString().contains('exceed a page height')) {
        throw Exception('⚠️ Data CV terlalu panjang! Tidak muat dalam 1 halaman.\n\nSilakan kurangi:\nJumlah pengalaman kerja, Jumlah pendidikan, Jumlah keahlian\nAtau perpendek deskripsi');
      }
      rethrow;
    }
  }

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
    final bytes = await generatePDFBytes(
      fullName: fullName,
      email: email,
      phone: phone,
      address: address,
      linkedin: linkedin,
      github: github,
      summary: summary,
      educations: educations,
      experiences: experiences,
      skills: skills,
      template: template,
      profileImage: profileImage,
    );
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/cv_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TEMPLATE ATS — clean, single-column, ATS-friendly
  // ═══════════════════════════════════════════════════════════════════════════
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
      pw.MemoryImage? photo,
      ) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(44, 36, 44, 36),
        build: (ctx) => [
          // Header dengan alignment center
          pw.Center(
            child: pw.Column(
              children: [
                if (photo != null)
                  pw.Container(
                    width: 70,
                    height: 70,
                    margin: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
                  ),
                pw.Text(
                  fullName.toUpperCase(),
                  style: ts(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _kBlack, letterSpacing: 2.5),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 6),
                pw.Container(width: 44, height: 2.5, color: _kBlue),
                pw.SizedBox(height: 10),
                pw.Text(email, style: ts(fontSize: 10, color: _kGrey700), textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 2),
                pw.Text(
                  [phone, address].where((s) => s.isNotEmpty).join('  ·  '),
                  style: ts(fontSize: 10, color: _kGrey700),
                  textAlign: pw.TextAlign.center,
                ),
                if (linkedin.isNotEmpty || github.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    [linkedin, github].where((s) => s.isNotEmpty).join('  ·  '),
                    style: ts(fontSize: 10, color: _kBlue),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          if (summary.isNotEmpty) ...[
            _atsSectionHeader('PROFIL PROFESIONAL'),
            pw.Text(summary, style: ts(fontSize: 10.5, color: _kGrey800, lineSpacing: 1.3)),
            pw.SizedBox(height: 14),
          ],
          if (experiences.isNotEmpty) ...[
            _atsSectionHeader('PENGALAMAN KERJA'),
            ...experiences.map(_atsExperience),
            pw.SizedBox(height: 6),
          ],
          if (educations.isNotEmpty) ...[
            _atsSectionHeader('PENDIDIKAN'),
            ...educations.map(_atsEducation),
            pw.SizedBox(height: 6),
          ],
          if (skills.isNotEmpty) ...[
            _atsSectionHeader('KEAHLIAN'),
            pw.SizedBox(height: 2),
            pw.Wrap(
              spacing: 6,
              runSpacing: 5,
              children: skills.map((s) => _atsSkillChip(s.name)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── ATS: Section Header ──
  static pw.Widget _atsSectionHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(width: double.infinity, height: 0.75, color: _kGrey300),
        pw.SizedBox(height: 5),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(width: 3, height: 13, color: _kBlue),
            pw.SizedBox(width: 7),
            pw.Text(
              title,
              style: ts(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: _kBlack, letterSpacing: 1.2),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  // ── ATS: Experience Item ──
  static pw.Widget _atsExperience(Experience exp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(exp.position,
                    style: ts(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _kBlack)),
              ),
              pw.Text(
                '${exp.startYear} – ${exp.endYear}',
                style: ts(fontSize: 9.5, color: _kGrey600),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(exp.organization,
              style: ts(fontSize: 10.5, fontStyle: pw.FontStyle.italic, color: _kGrey700)),
          pw.SizedBox(height: 4),
          pw.Text(exp.description,
              style: ts(fontSize: 10, color: _kGrey800, lineSpacing: 1.2)),
        ],
      ),
    );
  }

  // ── ATS: Education Item ──
  static pw.Widget _atsEducation(Education edu) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(edu.university,
                    style: ts(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _kBlack)),
              ),
              pw.Text(
                '${edu.startYear} – ${edu.endYear}',
                style: ts(fontSize: 9.5, color: _kGrey600),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(edu.major,
              style: ts(fontSize: 10.5, fontStyle: pw.FontStyle.italic, color: _kGrey700)),
          if (edu.gpa != null) ...[
            pw.SizedBox(height: 1),
            pw.Text('IPK: ${edu.gpa}', style: ts(fontSize: 9.5, color: _kGrey600)),
          ],
        ],
      ),
    );
  }

  // ── ATS: Skill Chip ──
  static pw.Widget _atsSkillChip(String name) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _kGrey100,
        border: pw.Border.all(color: _kGrey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(name, style: ts(fontSize: 9.5, color: _kGrey800)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TEMPLATE CREATIVE — two-column with coloured sidebar
  // ═══════════════════════════════════════════════════════════════════════════
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
      pw.MemoryImage? photo,
      ) {

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Sidebar kiri ──
              pw.Container(
                width: 172,
                color: _kBlueSidebar,
                padding: const pw.EdgeInsets.fromLTRB(16, 28, 16, 28),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Avatar (tetap center)
                    pw.Center(
                      child: pw.Container(
                        width: 82,
                        height: 82,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: _kWhite,
                          border: pw.Border.all(color: _kWhite, width: 2.5),
                        ),
                        child: photo != null
                            ? pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover))
                            : pw.Center(
                          child: pw.Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                            style: ts(fontSize: 30, fontWeight: pw.FontWeight.bold, color: _kBlueSidebar),
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Center(
                      child: pw.Text(
                        fullName,
                        textAlign: pw.TextAlign.center,
                        style: ts(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _kWhite),
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    // Kontak (rata kiri)
                    _crSidebarSection('KONTAK'),
                    _crContactRow('Email', email),
                    _crContactRow('Telepon', phone),
                    _crContactRow('Alamat', address),
                    if (linkedin.isNotEmpty) _crContactRow('LinkedIn', linkedin),
                    if (github.isNotEmpty) _crContactRow('GitHub', github),
                    pw.SizedBox(height: 18),
                    // Skills (rata kiri)
                    _crSidebarSection('KEAHLIAN'),
                    ...skills.map((skill) => _crSkillItem(skill.name)),
                  ],
                ),
              ),
              // ── Kolom kanan ──
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(22, 28, 22, 28),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(fullName,
                          style: ts(fontSize: 26, fontWeight: pw.FontWeight.bold, color: _kBlue)),
                      pw.SizedBox(height: 3),
                      pw.Container(width: 48, height: 3, color: _kBlue),
                      pw.SizedBox(height: 18),
                      if (summary.isNotEmpty) ...[
                        _crRightSection('PROFIL'),
                        pw.Text(summary,
                            style: ts(fontSize: 10.5, color: _kGrey800, lineSpacing: 1.3)),
                        pw.SizedBox(height: 16),
                      ],
                      if (experiences.isNotEmpty) ...[
                        _crRightSection('PENGALAMAN'),
                        ...experiences.map(_crExperience),
                        pw.SizedBox(height: 8),
                      ],
                      if (educations.isNotEmpty) ...[
                        _crRightSection('PENDIDIKAN'),
                        ...educations.map(_crEducation),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Creative: Sidebar section header ──
  static pw.Widget _crSidebarSection(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: ts(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _kWhite, letterSpacing: 1.8),
        ),
        pw.SizedBox(height: 5),
        pw.Container(width: double.infinity, height: 0.5, color: const PdfColor(1, 1, 1, 0.4)),
        pw.SizedBox(height: 10),
      ],
    );
  }

  // ── Creative: Contact row (label kecil + nilai) - rata kiri ──
  static pw.Widget _crContactRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: ts(fontSize: 7.5, color: const PdfColor(1, 1, 1, 0.6), letterSpacing: 0.8),
          ),
          pw.SizedBox(height: 1),
          pw.Text(value, style: ts(fontSize: 9.5, color: _kWhite)),
        ],
      ),
    );
  }

  // ── Creative: Skill item ──
  static pw.Widget _crSkillItem(String name) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        '• $name',
        style: ts(fontSize: 9.5, color: _kWhite),
      ),
    );
  }

  // ── Creative: Right column section header ──
  static pw.Widget _crRightSection(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(width: 3, height: 13, color: _kBlue),
            pw.SizedBox(width: 7),
            pw.Text(
              title,
              style: ts(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _kBlue, letterSpacing: 1.2),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(width: double.infinity, height: 0.5, color: _kBlueLight),
        pw.SizedBox(height: 10),
      ],
    );
  }

  // ── Creative: Experience item ──
  static pw.Widget _crExperience(Experience exp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(exp.position,
                    style: ts(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _kBlack)),
              ),
              pw.SizedBox(width: 6),
              _crDateBadge('${exp.startYear} – ${exp.endYear}'),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(exp.organization,
              style: ts(fontSize: 10, fontStyle: pw.FontStyle.italic, color: _kGrey700)),
          pw.SizedBox(height: 4),
          pw.Text(exp.description,
              style: ts(fontSize: 9.5, color: _kGrey800, lineSpacing: 1.2)),
        ],
      ),
    );
  }

  // ── Creative: Education item ──
  static pw.Widget _crEducation(Education edu) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(edu.university,
                    style: ts(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _kBlack)),
              ),
              pw.SizedBox(width: 6),
              _crDateBadge('${edu.startYear} – ${edu.endYear}'),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(edu.major,
              style: ts(fontSize: 10, fontStyle: pw.FontStyle.italic, color: _kGrey700)),
          if (edu.gpa != null) ...[
            pw.SizedBox(height: 1),
            pw.Text('IPK: ${edu.gpa}', style: ts(fontSize: 9.5, color: _kGrey600)),
          ],
        ],
      ),
    );
  }

  // ── Creative: Date badge (kotak biru muda) ──
  static pw.Widget _crDateBadge(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: _kBlueLight,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(text, style: ts(fontSize: 8.5, color: _kBlueDark)),
    );
  }
}