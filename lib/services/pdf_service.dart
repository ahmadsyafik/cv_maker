import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/achievement.dart';
import '../models/education.dart';
import '../models/experience.dart';
import '../models/publication.dart';
import '../models/skill.dart';
import '../state/cv_provider.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _cBlue       = PdfColor.fromInt(0xFF1565C0);
const _cBlueDark   = PdfColor.fromInt(0xFF0D47A1);
const _cBlueMid    = PdfColor.fromInt(0xFF1976D2);
const _cBlueLight  = PdfColor.fromInt(0xFFE3F2FD);
const _cNavy       = PdfColor.fromInt(0xFF1B2B4B);
const _cNavyAccent = PdfColor.fromInt(0xFF2E6DA4);
const _cRed        = PdfColor.fromInt(0xFFC62828);
const _cRedDark    = PdfColor.fromInt(0xFF8B0000);
const _cWhite      = PdfColors.white;
const _cBlack      = PdfColor.fromInt(0xFF1A1A1A);
const _cGrey800    = PdfColor.fromInt(0xFF333333);
const _cGrey700    = PdfColor.fromInt(0xFF555555);
const _cGrey600    = PdfColor.fromInt(0xFF777777);
const _cGrey400    = PdfColor.fromInt(0xFFBDBDBD);
const _cGrey300    = PdfColor.fromInt(0xFFE0E0E0);
const _cGrey100    = PdfColor.fromInt(0xFFF5F5F5);

// ─── Font singletons ──────────────────────────────────────────────────────────
late pw.Font _regular;
late pw.Font _bold;
late pw.Font _italic;
bool _fontsReady = false;

Future<void> _loadFonts() async {
  if (_fontsReady) return;
  try {
    final r = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final b = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final i = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');
    _regular = pw.Font.ttf(r.buffer.asByteData());
    _bold    = pw.Font.ttf(b.buffer.asByteData());
    _italic  = pw.Font.ttf(i.buffer.asByteData());
  } catch (_) {
    _regular = pw.Font.helvetica();
    _bold    = pw.Font.helveticaBold();
    _italic  = pw.Font.helveticaOblique();
  }
  _fontsReady = true;
}

// ─── Text style helper ────────────────────────────────────────────────────────
pw.TextStyle _ts({
  double size = 10,
  bool bold = false,
  bool italic = false,
  PdfColor? color,
  double? spacing,
  double? lineH,
}) {
  return pw.TextStyle(
    font: bold ? _bold : italic ? _italic : _regular,
    fontSize: size,
    color: color,
    letterSpacing: spacing,
    lineSpacing: lineH,
  );
}

// Helper untuk opacity color
PdfColor _withOpacity(PdfColor color, double opacity) {
  return PdfColor(
    color.red,
    color.green,
    color.blue,
    opacity,
  );
}

// Helper untuk mendapatkan emoji dari nama icon
String _getIconEmoji(String iconName) {
  final emojiMap = {
    'house': '🏠',
    'user': '👤',
    'briefcase': '💼',
    'mail': '✉️',
    'phone': '📞',
    'map-pin': '📍',
    'link': '🔗',
    'code': '💻',
    'graduation-cap': '🎓',
    'trophy': '🏆',
    'star': '⭐',
    'settings': '⚙️',
    'book-open': '📖',
    'heart': '❤️',
    'calendar': '📅',
    'globe': '🌐',
  };
  return emojiMap[iconName] ?? '•';
}

// ─── Profile image loader ─────────────────────────────────────────────────────
Future<pw.MemoryImage?> _loadPhoto(String? src) async {
  if (src == null || src.isEmpty) return null;
  try {
    Uint8List? bytes;
    if (src.startsWith('http')) {
      final res = await http.get(Uri.parse(src));
      if (res.statusCode == 200) bytes = res.bodyBytes;
    } else if (src.contains(',')) {
      bytes = base64Decode(src.split(',').last);
    } else if (!kIsWeb) {
      final f = File(src);
      if (await f.exists()) bytes = await f.readAsBytes();
    }
    if (bytes != null) return pw.MemoryImage(bytes);
  } catch (e) {
    debugPrint('Photo load error: $e');
  }
  return null;
}

// ─── Public service class ────────────────────────────────────────────────────
class PDFService {

  static Future<void> initializeFonts() => _loadFonts();

  // ── Main PDF generator ──────────────────────────────────────────────────
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
    List<Achievement> achievements = const [],
    List<Publication> publications = const [],
    CVTemplate template = CVTemplate.ats,
    String? profileImage,
  }) async {
    await _loadFonts();
    final theme = pw.ThemeData.withFont(base: _regular, bold: _bold, italic: _italic);
    final doc   = pw.Document(theme: theme);
    final photo = await _loadPhoto(profileImage);

    switch (template) {
      case CVTemplate.ats:
        _buildATS1(doc, fullName, email, phone, address, linkedin, github,
            summary, educations, experiences, skills, achievements, publications, photo);
        break;
      case CVTemplate.ats2:
        _buildATS2(doc, fullName, email, phone, address, linkedin, github,
            summary, educations, experiences, skills, achievements, publications, photo);
        break;
      case CVTemplate.creative:
        _buildCreative1(doc, fullName, email, phone, address, linkedin, github,
            summary, educations, experiences, skills, achievements, publications, photo);
        break;
      case CVTemplate.creative2:
        _buildCreative2(doc, fullName, email, phone, address, linkedin, github,
            summary, educations, experiences, skills, achievements, publications, photo);
        break;
    }

    return doc.save();
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
    List<Achievement> achievements = const [],
    List<Publication> publications = const [],
    CVTemplate template = CVTemplate.ats,
    String? profileImage,
  }) async {
    final bytes = await generatePDFBytes(
      fullName: fullName, email: email, phone: phone, address: address,
      linkedin: linkedin, github: github, summary: summary,
      educations: educations, experiences: experiences, skills: skills,
      achievements: achievements, publications: publications,
      template: template, profileImage: profileImage,
    );
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/cv_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  // Helper untuk menampilkan icon
  static pw.Widget _buildIcon(String iconName, {double size = 10, PdfColor? color}) {
    return pw.Text(_getIconEmoji(iconName), 
        style: _ts(size: size, color: color ?? _cBlue));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ATS v1 — Clean professional with sidebar summary
  // ═══════════════════════════════════════════════════════════════════════════
  static void _buildATS1(
      pw.Document doc, String fullName, String email, String phone,
      String address, String linkedin, String github, String summary,
      List<Education> edu, List<Experience> exp,
      List<Skill> skills, List<Achievement> ach,
      List<Publication> pub, pw.MemoryImage? photo) {

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 35, 40, 35),
      build: (ctx) => [
        // Header dengan garis bawah
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (photo != null) ...[
                pw.Container(
                  width: 85, height: 85,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: _cBlue, width: 2),
                  ),
                  child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
                ),
                pw.SizedBox(width: 20),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(fullName,
                        style: _ts(size: 24, bold: true, color: _cBlueDark)),
                    pw.SizedBox(height: 4),
                    pw.Container(width: 50, height: 3, color: _cBlue),
                    pw.SizedBox(height: 10),
                    pw.Wrap(
                      spacing: 15,
                      runSpacing: 5,
                      children: [
                        if (phone.isNotEmpty) _infoChip('phone', phone),
                        if (email.isNotEmpty) _infoChip('mail', email),
                        if (address.isNotEmpty) _infoChip('map-pin', address),
                      ],
                    ),
                    if (linkedin.isNotEmpty || github.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Wrap(
                        spacing: 15,
                        children: [
                          if (linkedin.isNotEmpty) _infoChip('link', linkedin),
                          if (github.isNotEmpty) _infoChip('code', github),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Container(height: 1.5, color: _cBlue),
          pw.SizedBox(height: 20),
        ]),

        // 2 column layout untuk konten utama
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Kolom kiri (35%) - Summary & Skills
            pw.Expanded(
              flex: 35,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (summary.isNotEmpty) ...[
                    _sectionHeader('PROFILE SUMMARY', 'user'),
                    pw.Text(summary,
                        style: _ts(size: 10, color: _cGrey800, lineH: 1.5)),
                    pw.SizedBox(height: 16),
                  ],
                  if (skills.isNotEmpty) ...[
                    _sectionHeader('CORE SKILLS', 'settings'),
                    ...skills.take(8).map((s) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Row(children: [
                        pw.Container(
                          width: 4, height: 4,
                          margin: const pw.EdgeInsets.only(right: 8),
                          decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: _cBlue),
                        ),
                        pw.Expanded(
                          child: pw.Text(s.name,
                              style: _ts(size: 10, color: _cGrey700)),
                        ),
                      ]),
                    )).toList(),
                    pw.SizedBox(height: 16),
                  ],
                  if (ach.isNotEmpty) ...[
                    _sectionHeader('ACHIEVEMENTS', 'trophy'),
                    ...ach.take(3).map((a) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(children: [
                            _buildIcon('trophy', size: 10),
                            pw.SizedBox(width: 4),
                            pw.Expanded(
                              child: pw.Text(a.title,
                                  style: _ts(size: 10, bold: true, color: _cBlueDark)),
                            ),
                          ]),
                          if (a.description.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 14, top: 2),
                              child: pw.Text(a.description,
                                  style: _ts(size: 9, color: _cGrey600)),
                            ),
                        ],
                      ),
                    )).toList(),
                  ],
                ],
              ),
            ),
            
            pw.SizedBox(width: 25),
            
            // Kolom kanan (65%) - Experience & Education
            pw.Expanded(
              flex: 65,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (exp.isNotEmpty) ...[
                    _sectionHeader('WORK EXPERIENCE', 'briefcase'),
                    ...exp.take(3).map((e) => _experienceItem(e)),
                    pw.SizedBox(height: 16),
                  ],
                  if (edu.isNotEmpty) ...[
                    _sectionHeader('EDUCATION', 'graduation-cap'),
                    ...edu.take(2).map((e) => _educationItem(e)),
                    pw.SizedBox(height: 16),
                  ],
                  if (pub.isNotEmpty) ...[
                    _sectionHeader('PUBLICATIONS', 'book-open'),
                    ...pub.take(2).map((p) => _publicationItem(p)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Helper Widgets untuk ATS1
  // ═══════════════════════════════════════════════════════════════════════════
  
  static pw.Widget _infoChip(String iconName, String text) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        _buildIcon(iconName, size: 8),
        pw.SizedBox(width: 4),
        pw.Text(text, style: _ts(size: 9, color: _cGrey700)),
      ],
    );
  }

  static pw.Widget _sectionHeader(String title, String iconName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            _buildIcon(iconName, size: 10),
            pw.SizedBox(width: 6),
            pw.Text(title,
                style: _ts(size: 11, bold: true, color: _cBlueDark, spacing: 0.8)),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 1.5, width: 40, color: _cBlue),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _experienceItem(Experience e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(e.position,
                    style: _ts(size: 11, bold: true, color: _cBlack)),
              ),
              pw.Text('${e.startYear} - ${e.endYear}',
                  style: _ts(size: 9, color: _cGrey600)),
            ],
          ),
          pw.Text(e.organization,
              style: _ts(size: 10, italic: true, color: _cBlue)),
          pw.SizedBox(height: 6),
          if (e.description.isNotEmpty)
            pw.Text(e.description,
                style: _ts(size: 9.5, color: _cGrey700, lineH: 1.4)),
        ],
      ),
    );
  }

  static pw.Widget _educationItem(Education e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(e.university,
              style: _ts(size: 11, bold: true, color: _cBlack)),
          pw.Text(e.major, style: _ts(size: 10, color: _cGrey700)),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${e.startYear} - ${e.endYear}',
                  style: _ts(size: 9, color: _cGrey600)),
              if (e.gpa != null)
                pw.Text('GPA: ${e.gpa}',
                    style: _ts(size: 9, bold: true, color: _cBlue)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _publicationItem(Publication p) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p.title,
              style: _ts(size: 10.5, bold: true, color: _cBlack)),
          if (p.journal.isNotEmpty || p.year.isNotEmpty)
            pw.Text([p.journal, p.year].where((s) => s.isNotEmpty).join(' · '),
                style: _ts(size: 9.5, italic: true, color: _cGrey600)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ATS v2 — Modern two-column with colored sidebar
  // ═══════════════════════════════════════════════════════════════════════════
  static void _buildATS2(
      pw.Document doc, String fullName, String email, String phone,
      String address, String linkedin, String github, String summary,
      List<Education> edu, List<Experience> exp,
      List<Skill> skills, List<Achievement> ach,
      List<Publication> pub, pw.MemoryImage? photo) {

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Sidebar kiri - warna biru tua
            pw.Container(
              width: 140,
              color: _cNavy,
              padding: const pw.EdgeInsets.fromLTRB(16, 30, 16, 30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (photo != null) ...[
                    pw.Center(
                      child: pw.Container(
                        width: 80, height: 80,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: _cWhite, width: 2),
                        ),
                        child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
                      ),
                    ),
                    pw.SizedBox(height: 15),
                  ],
                  pw.Center(
                    child: pw.Text(fullName.split(' ').first,
                        textAlign: pw.TextAlign.center,
                        style: _ts(size: 14, bold: true, color: _cWhite)),
                  ),
                  pw.SizedBox(height: 20),
                  _sidebarSection('CONTACT', [
                    if (phone.isNotEmpty) 'phone: $phone',
                    if (email.isNotEmpty) 'mail: $email',
                    if (address.isNotEmpty) 'map-pin: $address',
                  ]),
                  if (skills.isNotEmpty) ...[
                    pw.SizedBox(height: 15),
                    _sidebarSection('SKILLS', skills.take(6).map((s) => s.name).toList()),
                  ],
                  if (ach.isNotEmpty) ...[
                    pw.SizedBox(height: 15),
                    _sidebarSection('HONORS', ach.take(3).map((a) => a.title).toList()),
                  ],
                ],
              ),
            ),
            
            // Konten kanan
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(25, 30, 25, 30),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(fullName,
                        style: _ts(size: 22, bold: true, color: _cNavy)),
                    pw.SizedBox(height: 4),
                    pw.Container(width: 45, height: 2, color: _cNavyAccent),
                    pw.SizedBox(height: 15),
                    
                    if (summary.isNotEmpty) ...[
                      pw.Text(summary,
                          style: _ts(size: 10, color: _cGrey700, lineH: 1.5)),
                      pw.SizedBox(height: 20),
                    ],
                    
                    if (exp.isNotEmpty) ...[
                      _rightSectionTitle('Professional Experience', 'briefcase'),
                      ...exp.take(2).map((e) => _rightExperienceItem(e)),
                      pw.SizedBox(height: 15),
                    ],
                    
                    if (edu.isNotEmpty) ...[
                      _rightSectionTitle('Education', 'graduation-cap'),
                      ...edu.take(1).map((e) => _rightEducationItem(e)),
                    ],
                    
                    if (linkedin.isNotEmpty || github.isNotEmpty) ...[
                      pw.SizedBox(height: 15),
                      pw.Wrap(
                        spacing: 15,
                        children: [
                          if (linkedin.isNotEmpty) 
                            _infoChip('link', linkedin),
                          if (github.isNotEmpty) 
                            _infoChip('code', github),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ));
  }

  static pw.Widget _sidebarSection(String title, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: _ts(size: 9, bold: true, color: _cWhite, spacing: 1.2)),
        pw.SizedBox(height: 6),
        pw.Container(height: 1, color: _withOpacity(_cWhite, 0.3)),
        pw.SizedBox(height: 8),
        ...items.map((item) {
          // Parse icon dari string
          String displayText = item;
          String iconName = 'circle';
          if (item.startsWith('phone:')) {
            iconName = 'phone';
            displayText = item.substring(6);
          } else if (item.startsWith('mail:')) {
            iconName = 'mail';
            displayText = item.substring(5);
          } else if (item.startsWith('map-pin:')) {
            iconName = 'map-pin';
            displayText = item.substring(8);
          }
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              children: [
                _buildIcon(iconName, size: 7, color: _cWhite),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Text(displayText,
                      style: _ts(size: 8.5, color: _withOpacity(_cWhite, 0.9))),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _rightSectionTitle(String title, String iconName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            _buildIcon(iconName, size: 10),
            pw.SizedBox(width: 6),
            pw.Text(title,
                style: _ts(size: 12, bold: true, color: _cNavy)),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Container(height: 1, color: _cGrey300),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _rightExperienceItem(Experience e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(e.position,
                  style: _ts(size: 10.5, bold: true, color: _cBlack)),
              pw.Text('${e.startYear} - ${e.endYear}',
                  style: _ts(size: 9, color: _cGrey600)),
            ],
          ),
          pw.Text(e.organization,
              style: _ts(size: 9.5, italic: true, color: _cNavy)),
          pw.SizedBox(height: 4),
          if (e.description.isNotEmpty)
            pw.Text(e.description,
                style: _ts(size: 9, color: _cGrey700, lineH: 1.4)),
        ],
      ),
    );
  }

  static pw.Widget _rightEducationItem(Education e) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(e.university,
            style: _ts(size: 10.5, bold: true, color: _cBlack)),
        pw.Text(e.major, style: _ts(size: 9.5, color: _cGrey700)),
        pw.Text('${e.startYear} - ${e.endYear}',
            style: _ts(size: 9, color: _cGrey600)),
        if (e.gpa != null)
          pw.Text('GPA: ${e.gpa}', style: _ts(size: 9, color: _cNavy)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Creative v1 — Minimalist elegant
  // ═══════════════════════════════════════════════════════════════════════════
  static void _buildCreative1(
      pw.Document doc, String fullName, String email, String phone,
      String address, String linkedin, String github, String summary,
      List<Education> edu, List<Experience> exp,
      List<Skill> skills, List<Achievement> ach,
      List<Publication> pub, pw.MemoryImage? photo) {

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(35),
      build: (ctx) => [
        // Header dengan foto
        pw.Center(
          child: pw.Column(
            children: [
              if (photo != null) ...[
                pw.Container(
                  width: 100, height: 100,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    boxShadow: [
                      pw.BoxShadow(
                        color: _cGrey400, 
                        blurRadius: 8, 
                        offset: const PdfPoint(0, 4),
                      ),
                    ],
                  ),
                  child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
                ),
                pw.SizedBox(height: 15),
              ],
              pw.Text(fullName,
                  style: _ts(size: 26, bold: true, color: _cBlueDark, spacing: 1)),
              pw.SizedBox(height: 5),
              pw.Container(width: 60, height: 2, color: _cBlue),
              pw.SizedBox(height: 12),
              pw.Wrap(
                spacing: 20,
                alignment: pw.WrapAlignment.center,
                children: [
                  if (phone.isNotEmpty) _creativeContact('phone', phone),
                  if (email.isNotEmpty) _creativeContact('mail', email),
                  if (address.isNotEmpty) _creativeContact('map-pin', address),
                  if (linkedin.isNotEmpty) _creativeContact('link', linkedin),
                ],
              ),
              pw.SizedBox(height: 25),
            ],
          ),
        ),
        
        if (summary.isNotEmpty) ...[
          _creativeSection('About Me', 'user', [
            pw.Container(
              child: pw.Text(summary,
                  style: _ts(size: 10.5, color: _cGrey700, lineH: 1.6),
                  textAlign: pw.TextAlign.center),
            ),
          ]),
          pw.SizedBox(height: 20),
        ],
        
        // 2 column untuk skills, experience, education
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 45,
              child: pw.Column(
                children: [
                  if (skills.isNotEmpty)
                    _creativeSection('Core Competencies', 'settings', 
                      skills.take(6).map((s) => _creativeBullet(s.name)).toList()),
                  if (ach.isNotEmpty)
                    _creativeSection('Key Achievements', 'trophy',
                      ach.take(3).map((a) => _creativeBullet(a.title)).toList()),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 55,
              child: pw.Column(
                children: [
                  if (exp.isNotEmpty)
                    _creativeSection('Experience', 'briefcase',
                      exp.take(2).map((e) => _creativeExperience(e)).toList()),
                  if (edu.isNotEmpty)
                    _creativeSection('Education', 'graduation-cap',
                      edu.take(1).map((e) => _creativeEducation(e)).toList()),
                ],
              ),
            ),
          ],
        ),
      ],
    ));
  }

  static pw.Widget _creativeContact(String iconName, String text) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        _buildIcon(iconName, size: 10),
        pw.SizedBox(width: 5),
        pw.Text(text, style: _ts(size: 9.5, color: _cGrey700)),
      ],
    );
  }

  static pw.Widget _creativeSection(String title, String iconName, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            _buildIcon(iconName, size: 10),
            pw.SizedBox(width: 6),
            pw.Text(title,
                style: _ts(size: 12, bold: true, color: _cBlueDark)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 1, color: _cBlueLight),
        pw.SizedBox(height: 10),
        ...children,
        pw.SizedBox(height: 15),
      ],
    );
  }

  static pw.Widget _creativeBullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('▹ ', style: _ts(size: 10, color: _cBlue)),
          pw.Expanded(
            child: pw.Text(text,
                style: _ts(size: 10, color: _cGrey700)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _creativeExperience(Experience e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(e.position,
              style: _ts(size: 11, bold: true, color: _cBlack)),
          pw.Text(e.organization,
              style: _ts(size: 9.5, italic: true, color: _cBlue)),
          pw.Text('${e.startYear} - ${e.endYear}',
              style: _ts(size: 9, color: _cGrey600)),
          if (e.description.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(e.description,
                style: _ts(size: 9.5, color: _cGrey700, lineH: 1.4)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _creativeEducation(Education e) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(e.university,
            style: _ts(size: 11, bold: true, color: _cBlack)),
        pw.Text(e.major, style: _ts(size: 10, color: _cGrey700)),
        pw.Text('${e.startYear} - ${e.endYear}',
            style: _ts(size: 9, color: _cGrey600)),
        if (e.gpa != null)
          pw.Text('GPA: ${e.gpa}', style: _ts(size: 9, color: _cBlue)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Creative v2 — Colorful and modern
  // ═══════════════════════════════════════════════════════════════════════════
  static void _buildCreative2(
      pw.Document doc, String fullName, String email, String phone,
      String address, String linkedin, String github, String summary,
      List<Education> edu, List<Experience> exp,
      List<Skill> skills, List<Achievement> ach,
      List<Publication> pub, pw.MemoryImage? photo) {

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (ctx) => [
        // Header dengan warna
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [_cBlueDark, _cBlue],
              begin: pw.Alignment.centerLeft,
              end: pw.Alignment.centerRight,
            ),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Row(
            children: [
              if (photo != null) ...[
                pw.Container(
                  width: 70, height: 70,
                  decoration: const pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: _cWhite,
                  ),
                  child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
                ),
                pw.SizedBox(width: 15),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(fullName,
                        style: _ts(size: 22, bold: true, color: _cWhite)),
                    pw.SizedBox(height: 5),
                    pw.Text(summary.isNotEmpty ? summary.split('.').first : '',
                        style: _ts(size: 10, color: _withOpacity(_cWhite, 0.9))),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        
        // Contact info bar
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: pw.BoxDecoration(
            color: _cGrey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Wrap(
            spacing: 20,
            runSpacing: 5,
            alignment: pw.WrapAlignment.center,
            children: [
              if (phone.isNotEmpty) _modernContact('phone', phone),
              if (email.isNotEmpty) _modernContact('mail', email),
              if (address.isNotEmpty) _modernContact('map-pin', address),
              if (linkedin.isNotEmpty) _modernContact('link', linkedin),
              if (github.isNotEmpty) _modernContact('code', github),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        
        // Main content 2 columns
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 50,
              child: pw.Column(
                children: [
                  if (exp.isNotEmpty) ...[
                    _modernSection('briefcase', 'Work Experience',
                      exp.take(2).map((e) => _modernExperience(e)).toList()),
                  ],
                  if (skills.isNotEmpty) ...[
                    _modernSection('settings', 'Skills',
                      [_modernSkillTags(skills.take(8).toList())]),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 50,
              child: pw.Column(
                children: [
                  if (edu.isNotEmpty) ...[
                    _modernSection('graduation-cap', 'Education',
                      edu.take(2).map((e) => _modernEducation(e)).toList()),
                  ],
                  if (ach.isNotEmpty) ...[
                    _modernSection('trophy', 'Awards',
                      ach.take(3).map((a) => _modernAchievement(a)).toList()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ));
  }

  static pw.Widget _modernContact(String iconName, String text) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        _buildIcon(iconName, size: 9),
        pw.SizedBox(width: 4),
        pw.Text(text, style: _ts(size: 9, color: _cGrey700)),
      ],
    );
  }

  static pw.Widget _modernSection(String iconName, String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            _buildIcon(iconName, size: 10),
            pw.SizedBox(width: 6),
            pw.Text(title,
                style: _ts(size: 12, bold: true, color: _cBlueDark)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 2, width: 35, color: _cBlue),
        pw.SizedBox(height: 10),
        ...children,
        pw.SizedBox(height: 15),
      ],
    );
  }

  static pw.Widget _modernExperience(Experience e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(e.position,
              style: _ts(size: 11, bold: true, color: _cBlack)),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(e.organization,
                  style: _ts(size: 9.5, color: _cBlue)),
              pw.Text('${e.startYear} - ${e.endYear}',
                  style: _ts(size: 9, color: _cGrey600)),
            ],
          ),
          if (e.description.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(e.description,
                style: _ts(size: 9.5, color: _cGrey700, lineH: 1.4)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _modernSkillTags(List<Skill> skills) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 6,
      children: skills.map((s) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: pw.BoxDecoration(
          color: _cBlueLight,
          borderRadius: pw.BorderRadius.circular(15),
        ),
        child: pw.Text(s.name,
            style: _ts(size: 9, color: _cBlueDark)),
      )).toList(),
    );
  }

  static pw.Widget _modernEducation(Education e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(e.university,
              style: _ts(size: 10.5, bold: true, color: _cBlack)),
          pw.Text(e.major, style: _ts(size: 9.5, color: _cGrey700)),
          pw.Text('${e.startYear} - ${e.endYear}',
              style: _ts(size: 9, color: _cGrey600)),
        ],
      ),
    );
  }

  static pw.Widget _modernAchievement(Achievement a) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('⭐ ', style: _ts(size: 9, color: _cBlue)),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(a.title,
                    style: _ts(size: 10, bold: true, color: _cBlack)),
                if (a.description.isNotEmpty)
                  pw.Text(a.description,
                      style: _ts(size: 9, color: _cGrey600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}