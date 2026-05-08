import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
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
const _cRed        = PdfColor.fromInt(0xFF8B1A1A);
const _cRedDark    = PdfColor.fromInt(0xFF6B1212);
const _cWhite      = PdfColors.white;
const _cBlack      = PdfColor.fromInt(0xFF111111);
const _cGrey800    = PdfColor.fromInt(0xFF333333);
const _cGrey700    = PdfColor.fromInt(0xFF555555);
const _cGrey600    = PdfColor.fromInt(0xFF777777);
const _cGrey300    = PdfColor.fromInt(0xFFCCCCCC);

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

  // ═══════════════════════════════════════════════════════════════════════════
  //  ATS v1 — Single column clean, foto kiri atas, garis pembatas section
  //  Referensi: CV Belinda / CV Pius
  // ═══════════════════════════════════════════════════════════════════════════
  static void _buildATS1(
      pw.Document doc, String fullName, String email, String phone,
      String address, String linkedin, String github, String summary,
      List<Education> edu, List<Experience> exp,
      List<Skill> skills, List<Achievement> ach,
      List<Publication> pub, pw.MemoryImage? photo) {

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 40, 48, 40),
      build: (ctx) => [

        // ── Header ────────────────────────────────────────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (photo != null) ...[
            pw.Container(
              width: 88, height: 108,
              child: pw.Image(photo, fit: pw.BoxFit.cover),
            ),
            pw.SizedBox(width: 18),
          ],
          pw.Expanded(child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (photo != null) pw.SizedBox(height: 8),
              pw.Text(fullName.toUpperCase(),
                  style: _ts(size: 22, bold: true, color: _cBlack, spacing: 1.2)),
              pw.SizedBox(height: 6),
              pw.Container(height: 1.5, color: _cGrey300),
              pw.SizedBox(height: 8),
              if (phone.isNotEmpty || address.isNotEmpty)
                pw.Text([phone, address].where((s) => s.isNotEmpty).join('     '),
                    style: _ts(size: 10, color: _cGrey700)),
              if (email.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(email, style: _ts(size: 10, color: _cGrey700)),
              ],
              if (linkedin.isNotEmpty || github.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text([linkedin, github].where((s) => s.isNotEmpty).join('   |   '),
                    style: _ts(size: 9.5, color: _cBlue)),
              ],
            ],
          )),
        ]),

        pw.SizedBox(height: 14),
        pw.Container(height: 2, color: _cBlack),
        pw.SizedBox(height: 14),

        // ── Summary ───────────────────────────────────────────────────────
        if (summary.isNotEmpty) ...[
          _ats1Header('ABOUT ME'),
          pw.Text(summary, style: _ts(size: 10.5, color: _cGrey800, lineH: 2)),
          pw.SizedBox(height: 12),
          pw.Container(height: 1, color: _cGrey300),
          pw.SizedBox(height: 14),
        ],

        // ── Experience ────────────────────────────────────────────────────
        if (exp.isNotEmpty) ...[
          _ats1Header('ORGANIZATIONAL EXPERIENCE'),
          ...exp.map((e) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Expanded(child: pw.Text(e.organization,
                    style: _ts(size: 11, bold: true, color: _cBlack))),
                pw.Text('${e.startYear} – ${e.endYear}',
                    style: _ts(size: 9.5, color: _cGrey600)),
              ]),
              pw.Text(e.position, style: _ts(size: 10.5, italic: true, color: _cGrey700)),
              if (e.description.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                ...e.description.split('\n').map((line) => line.trim().isEmpty
                    ? pw.SizedBox(height: 2)
                    : pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          pw.Text('•  ', style: _ts(size: 10.5)),
                          pw.Expanded(child: pw.Text(line.trim(),
                              style: _ts(size: 10.5, color: _cGrey800, lineH: 1.4))),
                        ]))),
              ],
            ]),
          )),
          pw.Container(height: 1, color: _cGrey300),
          pw.SizedBox(height: 14),
        ],

        // ── Skills ────────────────────────────────────────────────────────
        if (skills.isNotEmpty) ...[
          _ats1Header('SKILLS'),
          pw.Wrap(
            spacing: 8, runSpacing: 6,
            children: skills.map((s) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _cGrey300, width: 0.8),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(s.name, style: _ts(size: 9.5, color: _cGrey800)),
            )).toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Container(height: 1, color: _cGrey300),
          pw.SizedBox(height: 14),
        ],

        // ── Achievements ──────────────────────────────────────────────────
        if (ach.isNotEmpty) ...[
          _ats1Header('ACHIEVEMENTS'),
          ...ach.map((a) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('•  ', style: _ts(size: 10.5)),
              pw.Expanded(child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(a.title, style: _ts(size: 10.5, bold: true, color: _cBlack)),
                  if (a.description.isNotEmpty)
                    pw.Text(a.description, style: _ts(size: 10, color: _cGrey700)),
                ],
              )),
            ]),
          )),
          pw.SizedBox(height: 12),
          pw.Container(height: 1, color: _cGrey300),
          pw.SizedBox(height: 14),
        ],

        // ── Education ─────────────────────────────────────────────────────
        if (edu.isNotEmpty) ...[
          _ats1Header('EDUCATION'),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: edu.map((e) => pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 12),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(e.university, style: _ts(size: 10.5, bold: true)),
                  pw.Text(e.major, style: _ts(size: 10, italic: true, color: _cGrey700)),
                  pw.Text('${e.startYear} – ${e.endYear}', style: _ts(size: 9.5, color: _cGrey600)),
                  if (e.gpa != null)
                    pw.Text('GPA: ${e.gpa}', style: _ts(size: 9.5, color: _cGrey600)),
                ]),
              ),
            )).toList(),
          ),
          pw.SizedBox(height: 14),
        ],

        // ── Publications ──────────────────────────────────────────────────
        if (pub.isNotEmpty) ...[
          pw.Container(height: 1, color: _cGrey300),
          pw.SizedBox(height: 12),
          _ats1Header('PUBLICATION'),
          ...pub.map((p) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(p.title, style: _ts(size: 10.5, bold: true)),
              if (p.journal.isNotEmpty || p.year.isNotEmpty)
                pw.Text([p.journal, p.year].where((s) => s.isNotEmpty).join(' – '),
                    style: _ts(size: 9.5, italic: true, color: _cGrey700)),
              if (p.url.isNotEmpty)
                pw.Text(p.url, style: _ts(size: 9, color: _cBlue)),
            ]),
          )),
        ],
      ],
    ));
  }

  static pw.Widget _ats1Header(String t) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(t, style: _ts(size: 12, bold: true, color: _cBlack, spacing: 0.5)),
      pw.SizedBox(height: 8),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  //  ATS v2 — Dark navy header band, classic two-column contact row
  //  Referensi: CV Pius Hari Purba
  // ═══════════════════════════════════════════════════════════════════════════
  static void _buildATS2(
      pw.Document doc, String fullName, String email, String phone,
      String address, String linkedin, String github, String summary,
      List<Education> edu, List<Experience> exp,
      List<Skill> skills, List<Achievement> ach,
      List<Publication> pub, pw.MemoryImage? photo) {

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 0, 40, 36),
      build: (ctx) => [

        // ── Navy header ───────────────────────────────────────────────────
        pw.Container(
          color: _cNavy,
          padding: const pw.EdgeInsets.fromLTRB(16, 24, 16, 20),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            if (photo != null) ...[
              pw.Container(
                width: 80, height: 80,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: _cWhite, width: 2.5),
                ),
                child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
              ),
              pw.SizedBox(width: 18),
            ],
            pw.Expanded(child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(fullName.toUpperCase(),
                    style: _ts(size: 22, bold: true, color: _cWhite, spacing: 1.5)),
                pw.SizedBox(height: 5),
                pw.Container(width: 180, height: 1.5, color: _cNavyAccent),
                pw.SizedBox(height: 8),
                pw.Row(children: [
                  if (phone.isNotEmpty)
                    pw.Expanded(child: pw.Text(phone, style: _ts(size: 9.5, color: _cWhite))),
                  if (email.isNotEmpty)
                    pw.Expanded(child: pw.Text(email, style: _ts(size: 9.5, color: _cWhite))),
                ]),
                if (address.isNotEmpty || linkedin.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(children: [
                    if (address.isNotEmpty)
                      pw.Expanded(child: pw.Text(address, style: _ts(size: 9.5, color: _cWhite))),
                    if (linkedin.isNotEmpty)
                      pw.Expanded(child: pw.Text(linkedin, style: _ts(size: 9.5, color: _cWhite))),
                  ]),
                ],
              ],
            )),
          ]),
        ),

        pw.SizedBox(height: 18),

        // ── Summary ───────────────────────────────────────────────────────
        if (summary.isNotEmpty) ...[
          _ats2Header('ABOUT ME'),
          pw.Text(summary, style: _ts(size: 10.5, color: _cGrey800, lineH: 1.8)),
          pw.SizedBox(height: 16),
        ],

        // ── Experience section heading ─────────────────────────────────────
        if (exp.isNotEmpty) ...[
          _ats2Header('EXPERIENCE - WORKSHOP, SKILL, ACHIEVEMENT'),
          pw.Text('Experiences', style: _ts(size: 10.5, bold: true)),
          pw.SizedBox(height: 6),
          ...exp.map((e) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('• ', style: _ts(size: 10.5)),
              pw.Expanded(child: pw.Text(
                '${e.position} – ${e.organization} (${e.startYear}–${e.endYear})',
                style: _ts(size: 10.5, color: _cGrey800),
              )),
            ]),
          )),
          pw.SizedBox(height: 12),
        ],

        // ── Skills ────────────────────────────────────────────────────────
        if (skills.isNotEmpty) ...[
          pw.Text('Skill', style: _ts(size: 10.5, bold: true)),
          pw.SizedBox(height: 4),
          ...List.generate(skills.length, (i) => pw.Text(
            '${i + 1}.   ${skills[i].name}',
            style: _ts(size: 10.5, color: _cGrey800),
          )),
          pw.SizedBox(height: 16),
        ],

        // ── Achievements ──────────────────────────────────────────────────
        if (ach.isNotEmpty) ...[
          pw.Text('Achievements', style: _ts(size: 10.5, bold: true)),
          pw.SizedBox(height: 5),
          ...ach.map((a) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('• ', style: _ts(size: 10.5)),
              pw.Expanded(child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(a.title, style: _ts(size: 10.5, color: _cGrey800)),
                  if (a.description.isNotEmpty)
                    pw.Text(a.description, style: _ts(size: 10, color: _cGrey700)),
                ],
              )),
            ]),
          )),
          pw.SizedBox(height: 16),
        ],

        // ── Education ─────────────────────────────────────────────────────
        if (edu.isNotEmpty) ...[
          pw.Container(height: 1.5, color: _cBlack),
          pw.SizedBox(height: 12),
          _ats2Header('EDUCATION'),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: edu.map((e) => pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 12),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(e.university, style: _ts(size: 10.5, bold: true)),
                  pw.Text(e.major, style: _ts(size: 10, color: _cGrey700)),
                  pw.Text('${e.startYear} – ${e.endYear}', style: _ts(size: 9.5, color: _cGrey600)),
                  if (e.gpa != null)
                    pw.Text('GPA: ${e.gpa}', style: _ts(size: 9.5, color: _cGrey600)),
                ]),
              ),
            )).toList(),
          ),
          pw.SizedBox(height: 16),
        ],

        // ── Publications ──────────────────────────────────────────────────
        if (pub.isNotEmpty) ...[
          pw.Container(height: 1.5, color: _cBlack),
          pw.SizedBox(height: 12),
          _ats2Header('PUBLICATION'),
          ...pub.map((p) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(p.title, style: _ts(size: 10.5, bold: true)),
              if (p.journal.isNotEmpty || p.year.isNotEmpty)
                pw.Text([p.journal, p.year].where((s) => s.isNotEmpty).join(' – '),
                    style: _ts(size: 9.5, italic: true, color: _cGrey700)),
              if (p.url.isNotEmpty)
                pw.Text(p.url, style: _ts(size: 9, color: _cBlue)),
            ]),
          )),
        ],
      ],
    ));
  }

  static pw.Widget _ats2Header(String t) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(t, style: _ts(size: 12, bold: true, color: _cBlack, spacing: 0.8)),
      pw.SizedBox(height: 4),
      pw.Container(height: 1.5, color: _cGrey300),
      pw.SizedBox(height: 10),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  //  Creative v1 — Blue sidebar left, white content right
  //  Referensi: existing sidebar biru
  // ═══════════════════════════════════════════════════════════════════════════
  static void _buildCreative1(
      pw.Document doc, String fullName, String email, String phone,
      String address, String linkedin, String github, String summary,
      List<Education> edu, List<Experience> exp,
      List<Skill> skills, List<Achievement> ach,
      List<Publication> pub, pw.MemoryImage? photo) {

    const double sideW = 175.0;

    // Split content into pages manually via MultiPage with fixed two-column Row
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Sidebar ────────────────────────────────────────────────
            pw.ConstrainedBox(
              constraints: const pw.BoxConstraints(maxWidth: sideW),
              child: pw.Container(
                width: sideW,
                color: _cBlue,
                padding: const pw.EdgeInsets.fromLTRB(16, 28, 16, 28),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(child: pw.Container(
                      width: 84, height: 84,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: _cWhite,
                        border: pw.Border.all(color: _cWhite, width: 2.5),
                      ),
                      child: photo != null
                          ? pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover))
                          : pw.Center(child: pw.Text(
                              fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                              style: _ts(size: 32, bold: true, color: _cBlue))),
                    )),
                    pw.SizedBox(height: 10),
                    pw.Center(child: pw.Text(fullName,
                        textAlign: pw.TextAlign.center,
                        style: _ts(size: 11.5, bold: true, color: _cWhite))),

                    pw.SizedBox(height: 22),
                    _cr1SideSection('KONTAK'),
                    if (email.isNotEmpty)    _cr1Contact('Email', email),
                    if (phone.isNotEmpty)    _cr1Contact('Telepon', phone),
                    if (address.isNotEmpty)  _cr1Contact('Alamat', address),
                    if (linkedin.isNotEmpty) _cr1Contact('LinkedIn', linkedin),
                    if (github.isNotEmpty)   _cr1Contact('GitHub', github),

                    if (skills.isNotEmpty) ...[
                      pw.SizedBox(height: 20),
                      _cr1SideSection('KEAHLIAN'),
                      ...skills.map((s) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Text('• ${s.name}',
                            style: _ts(size: 9.5, color: _cWhite)),
                      )),
                    ],

                    if (ach.isNotEmpty) ...[
                      pw.SizedBox(height: 20),
                      _cr1SideSection('PENGHARGAAN'),
                      ...ach.map((a) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 7),
                        child: pw.Text('• ${a.title}',
                            style: _ts(size: 9.5, color: _cWhite)),
                      )),
                    ],
                  ],
                ),
              ),
            ),

            // ── Right column ───────────────────────────────────────────
            pw.Expanded(child: pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(22, 28, 22, 28),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(fullName,
                      style: _ts(size: 24, bold: true, color: _cBlueDark)),
                  pw.SizedBox(height: 3),
                  pw.Container(width: 46, height: 3, color: _cBlue),
                  pw.SizedBox(height: 20),

                  if (summary.isNotEmpty) ...[
                    _cr1RightSection('PROFIL'),
                    pw.Text(summary, style: _ts(size: 10.5, color: _cGrey800, lineH: 1.6)),
                    pw.SizedBox(height: 16),
                  ],

                  if (exp.isNotEmpty) ...[
                    _cr1RightSection('PENGALAMAN'),
                    ...exp.map((e) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 13),
                      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                          pw.Expanded(child: pw.Text(e.position,
                              style: _ts(size: 11, bold: true, color: _cBlack))),
                          pw.SizedBox(width: 6),
                          _cr1Badge('${e.startYear}–${e.endYear}'),
                        ]),
                        pw.Text(e.organization,
                            style: _ts(size: 10, italic: true, color: _cGrey700)),
                        if (e.description.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(e.description,
                              style: _ts(size: 9.5, color: _cGrey800, lineH: 1.4)),
                        ],
                      ]),
                    )),
                    pw.SizedBox(height: 6),
                  ],

                  if (edu.isNotEmpty) ...[
                    _cr1RightSection('PENDIDIKAN'),
                    ...edu.map((e) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                          pw.Expanded(child: pw.Text(e.university,
                              style: _ts(size: 11, bold: true, color: _cBlack))),
                          pw.SizedBox(width: 6),
                          _cr1Badge('${e.startYear}–${e.endYear}'),
                        ]),
                        pw.Text(e.major,
                            style: _ts(size: 10, italic: true, color: _cGrey700)),
                        if (e.gpa != null)
                          pw.Text('IPK: ${e.gpa}', style: _ts(size: 9.5, color: _cGrey600)),
                      ]),
                    )),
                    pw.SizedBox(height: 6),
                  ],

                  if (pub.isNotEmpty) ...[
                    _cr1RightSection('PUBLIKASI'),
                    ...pub.map((p) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text(p.title, style: _ts(size: 10.5, bold: true)),
                        if (p.journal.isNotEmpty || p.year.isNotEmpty)
                          pw.Text([p.journal, p.year].where((s) => s.isNotEmpty).join(' – '),
                              style: _ts(size: 9.5, italic: true, color: _cGrey700)),
                        if (p.url.isNotEmpty)
                          pw.Text(p.url, style: _ts(size: 9, color: _cBlue)),
                      ]),
                    )),
                  ],
                ],
              ),
            )),
          ],
        ),
      ],
    ));
  }

  static pw.Widget _cr1SideSection(String t) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(t, style: _ts(size: 8.5, bold: true, color: _cWhite, spacing: 1.5)),
      pw.SizedBox(height: 5),
      pw.Container(height: 0.5, color: const PdfColor(1, 1, 1, 0.35)),
      pw.SizedBox(height: 10),
    ],
  );

  static pw.Widget _cr1Contact(String label, String value) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 9),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label.toUpperCase(),
          style: _ts(size: 7.5, color: const PdfColor(1, 1, 1, 0.55), spacing: 0.8)),
      pw.SizedBox(height: 1.5),
      pw.Text(value, style: _ts(size: 9.5, color: _cWhite)),
    ]),
  );

  static pw.Widget _cr1RightSection(String t) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(children: [
        pw.Container(width: 3, height: 13, color: _cBlue),
        pw.SizedBox(width: 7),
        pw.Text(t, style: _ts(size: 11, bold: true, color: _cBlueMid, spacing: 0.8)),
      ]),
      pw.SizedBox(height: 5),
      pw.Container(height: 0.5, color: _cBlueLight),
      pw.SizedBox(height: 10),
    ],
  );

  static pw.Widget _cr1Badge(String t) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
    decoration: pw.BoxDecoration(
      color: _cBlueLight, borderRadius: pw.BorderRadius.circular(3),
    ),
    child: pw.Text(t, style: _ts(size: 8.5, color: _cBlueDark)),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  //  Creative v2 — Red/cream two-column, referensi Rachelle & Juliana
  //  Contact strip top, header box photo+name+summary, body 2-col
  // ═══════════════════════════════════════════════════════════════════════════
  static void _buildCreative2(
      pw.Document doc, String fullName, String email, String phone,
      String address, String linkedin, String github, String summary,
      List<Education> edu, List<Experience> exp,
      List<Skill> skills, List<Achievement> ach,
      List<Publication> pub, pw.MemoryImage? photo) {

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 20, 28, 28),
      build: (ctx) => [

        // ── Contact strip ─────────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: pw.BoxDecoration(
            color: _cRed, borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              if (phone.isNotEmpty)
                pw.Text(phone,   style: _ts(size: 9.5, color: _cWhite)),
              if (email.isNotEmpty)
                pw.Text(email,   style: _ts(size: 9.5, color: _cWhite)),
              if (address.isNotEmpty)
                pw.Text(address, style: _ts(size: 9.5, color: _cWhite)),
            ],
          ),
        ),
        pw.SizedBox(height: 13),

        // ── Header box ────────────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _cGrey300, width: 0.8),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            if (photo != null) ...[
              pw.Container(
                width: 90, height: 90,
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _cRed, width: 2),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 6, verticalRadius: 6,
                  child: pw.Image(photo, fit: pw.BoxFit.cover),
                ),
              ),
              pw.SizedBox(width: 16),
            ],
            pw.Expanded(child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Hi! I\'m', style: _ts(size: 13, color: _cGrey700)),
                pw.Text(fullName,
                    style: _ts(size: 22, bold: true, color: _cBlack)),
                pw.SizedBox(height: 8),
                if (summary.isNotEmpty)
                  pw.Text(summary,
                      style: _ts(size: 10, color: _cGrey700, lineH: 1.6)),
              ],
            )),
          ]),
        ),
        pw.SizedBox(height: 15),

        // ── Body: 2 columns ───────────────────────────────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [

          // Left — experience + publications + skills box
          pw.Expanded(flex: 55, child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (exp.isNotEmpty) ...[
                _cr2Section('WORK EXPERIENCE'),
                ...exp.map((e) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 13),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                      pw.Container(width: 7, height: 7,
                          decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: _cRed)),
                      pw.SizedBox(width: 6),
                      pw.Expanded(child: pw.Text(
                        '${e.organization} | ${e.startYear} – ${e.endYear}',
                        style: _ts(size: 10, bold: true, color: _cRedDark),
                      )),
                    ]),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 13, top: 3),
                      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text(e.position,
                            style: _ts(size: 10, bold: true, color: _cRedDark)),
                        pw.SizedBox(height: 4),
                        if (e.description.isNotEmpty)
                          ...e.description.split('\n').map((line) => line.trim().isEmpty
                              ? pw.SizedBox(height: 2)
                              : pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                  pw.Text('• ', style: _ts(size: 10)),
                                  pw.Expanded(child: pw.Text(line.trim(),
                                      style: _ts(size: 10, color: _cGrey800, lineH: 1.4))),
                                ])),
                      ]),
                    ),
                  ]),
                )),
                pw.SizedBox(height: 6),
              ],

              if (pub.isNotEmpty) ...[
                _cr2Section('PUBLICATION'),
                ...pub.map((p) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(p.title, style: _ts(size: 10, bold: true)),
                    if (p.journal.isNotEmpty || p.year.isNotEmpty)
                      pw.Text([p.journal, p.year].where((s) => s.isNotEmpty).join(' – '),
                          style: _ts(size: 9.5, italic: true, color: _cGrey700)),
                    if (p.url.isNotEmpty)
                      pw.Text(p.url, style: _ts(size: 9, color: _cRed)),
                  ]),
                )),
                pw.SizedBox(height: 8),
              ],

              // Soft Skills box
              if (skills.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _cRed, width: 1.5),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: _cRed, borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text('Soft Skills',
                          style: _ts(size: 10, bold: true, color: _cWhite)),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Wrap(
                      spacing: 18, runSpacing: 6,
                      children: skills.map((s) => pw.Text(s.name,
                          style: _ts(size: 9.5, color: _cGrey700))).toList(),
                    ),
                  ]),
                ),
              ],
            ],
          )),

          pw.SizedBox(width: 16),

          // Right — education + achievements + links
          pw.Expanded(flex: 45, child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (edu.isNotEmpty) ...[
                _cr2Section('EDUCATION'),
                ...edu.map((e) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 11),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('• ${e.startYear} | ${e.university}',
                        style: _ts(size: 10, bold: true, color: _cRedDark)),
                    pw.Text(e.major, style: _ts(size: 9.5, color: _cGrey700)),
                    if (e.gpa != null)
                      pw.Text('GPA: ${e.gpa}', style: _ts(size: 9.5, color: _cGrey600)),
                  ]),
                )),
                pw.SizedBox(height: 8),
              ],

              if (ach.isNotEmpty) ...[
                _cr2Section('AWARDS RECEIVED'),
                ...ach.map((a) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 9),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(a.title, style: _ts(size: 10, bold: true, color: _cRedDark)),
                    if (a.description.isNotEmpty)
                      pw.Text(a.description, style: _ts(size: 9.5, color: _cGrey700)),
                  ]),
                )),
                pw.SizedBox(height: 8),
              ],

              if (linkedin.isNotEmpty || github.isNotEmpty) ...[
                _cr2Section('LINKS'),
                if (linkedin.isNotEmpty)
                  pw.Text(linkedin, style: _ts(size: 9.5, color: _cRed)),
                if (github.isNotEmpty)
                  pw.Text(github, style: _ts(size: 9.5, color: _cRed)),
              ],
            ],
          )),
        ]),
      ],
    ));
  }

  static pw.Widget _cr2Section(String t) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(t, style: _ts(size: 11.5, bold: true, color: _cRed, spacing: 0.5)),
      pw.SizedBox(height: 4),
      pw.Container(height: 1, color: _cRed),
      pw.SizedBox(height: 9),
    ],
  );
}
