import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/achievement.dart';
import '../models/education.dart';
import '../models/experience.dart';
import '../models/publication.dart';
import '../models/skill.dart';
import '../state/cv_provider.dart';

// ─── Warna ───────────────────────────────────────────────────────────────────
const _cPrimary = PdfColor.fromInt(0xFF2563EB);
const _cPrimaryDark = PdfColor.fromInt(0xFF1E40AF);
const _cPrimaryLight = PdfColor.fromInt(0xFFDBEAFE);
const _cSecondary = PdfColor.fromInt(0xFF1E293B);
const _cWhite = PdfColors.white;
const _cBlack = PdfColor.fromInt(0xFF0F172A);
const _cGrey700 = PdfColor.fromInt(0xFF334155);
const _cGrey600 = PdfColor.fromInt(0xFF475569);
const _cGrey500 = PdfColor.fromInt(0xFF64748B);
const _cGrey300 = PdfColor.fromInt(0xFFCBD5E1);
const _cGrey200 = PdfColor.fromInt(0xFFE2E8F0);

// ─── Font singleton
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
    _bold = pw.Font.ttf(b.buffer.asByteData());
    _italic = pw.Font.ttf(i.buffer.asByteData());
  } catch (_) {
    _regular = pw.Font.helvetica();
    _bold = pw.Font.helveticaBold();
    _italic = pw.Font.helveticaOblique();
  }
  _fontsReady = true;
}

pw.TextStyle _regularStyle({double size = 10, PdfColor? color}) {
  return pw.TextStyle(font: _regular, fontSize: size, color: color ?? _cGrey700);
}

pw.TextStyle _boldStyle({double size = 10, PdfColor? color}) {
  return pw.TextStyle(font: _bold, fontSize: size, color: color ?? _cBlack);
}

pw.TextStyle _italicStyle({double size = 10, PdfColor? color}) {
  return pw.TextStyle(font: _italic, fontSize: size, color: color ?? _cGrey600);
}

PdfColor _opacity(PdfColor color, double opacity) {
  return PdfColor(color.red, color.green, color.blue, opacity);
}

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
    debugPrint('Gagal memuat foto: $e');
  }
  return null;
}

class PDFService {
  static Future<void> initializeFonts() => _loadFonts();

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
    final doc = pw.Document();
    final photo = await _loadPhoto(profileImage);

    switch (template) {
      case CVTemplate.ats:
        _buildAtsTemplate(doc, fullName, email, phone, address, linkedin, github,
            summary, educations, experiences, skills, achievements, publications, photo);
        break;
      case CVTemplate.ats2:
        _buildAts2Template(doc, fullName, email, phone, address, linkedin, github,
            summary, educations, experiences, skills, achievements, publications, photo);
        break;
      case CVTemplate.creative:
        _buildCreativeTemplate(doc, fullName, email, phone, address, linkedin, github,
            summary, educations, experiences, skills, achievements, publications, photo);
        break;
      case CVTemplate.creative2:
        _buildCreative2Template(doc, fullName, email, phone, address, linkedin, github,
            summary, educations, experiences, skills, achievements, publications, photo);
        break;
    }

    return doc.save();
  }

  // ==================== ATS TEMPLATE 1 ====================
  static void _buildAtsTemplate(
      pw.Document doc,
      String name,
      String email,
      String phone,
      String address,
      String linkedin,
      String github,
      String summary,
      List<Education> edu,
      List<Experience> exp,
      List<Skill> skills,
      List<Achievement> ach,
      List<Publication> pub,
      pw.MemoryImage? photo) {
    
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Center(
          child: pw.Column(
            children: [
              if (photo != null)
                pw.Container(
                  width: 100,
                  height: 100,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: _cPrimary, width: 2),
                  ),
                  child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
                ),
              pw.SizedBox(height: 16),
              pw.Text(name.toUpperCase(), style: _boldStyle(size: 24, color: _cSecondary)),
              pw.SizedBox(height: 8),
              pw.Container(width: 60, height: 2, color: _cPrimary),
              pw.SizedBox(height: 16),
              pw.Wrap(
                spacing: 20,
                runSpacing: 8,
                alignment: pw.WrapAlignment.center,
                children: [
                  if (phone.isNotEmpty) _contactText(phone),
                  if (email.isNotEmpty) _contactText(email),
                  if (address.isNotEmpty) _contactText(address),
                  if (linkedin.isNotEmpty) _contactText(linkedin),
                  if (github.isNotEmpty) _contactText(github),
                ],
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 30),
        pw.Container(height: 1, color: _cGrey300),
        pw.SizedBox(height: 30),
        
        // Menggunakan MultiPage agar bisa multiple pages
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 35,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (summary.isNotEmpty) ...[
                    _atsSectionTitle('TENTANG SAYA'),
                    pw.SizedBox(height: 8),
                    pw.Text(summary, style: _regularStyle(size: 10), textAlign: pw.TextAlign.justify),
                    pw.SizedBox(height: 20),
                  ],
                  if (skills.isNotEmpty) ...[
                    _atsSectionTitle('KETERAMPILAN'),
                    pw.SizedBox(height: 8),
                    ...skills.map((s) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Row(
                        children: [
                          pw.Container(width: 4, height: 4, color: _cPrimary),
                          pw.SizedBox(width: 8),
                          pw.Expanded(child: pw.Text(s.name, style: _regularStyle(size: 9.5))),
                        ],
                      ),
                    )),
                    pw.SizedBox(height: 20),
                  ],
                  if (ach.isNotEmpty) ...[
                    _atsSectionTitle('PENCAPAIAN'),
                    pw.SizedBox(height: 8),
                    ...ach.map((a) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('• ${a.title}', style: _boldStyle(size: 10, color: _cPrimary)),
                          if (a.description.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 12, top: 2),
                              child: pw.Text(a.description, style: _regularStyle(size: 9)),
                            ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
            
            pw.SizedBox(width: 30),
            
            pw.Expanded(
              flex: 65,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (exp.isNotEmpty) ...[
                    _atsSectionTitle('PENGALAMAN KERJA'),
                    pw.SizedBox(height: 12),
                    ...exp.map((e) => _atsExperienceCard(e)),
                    pw.SizedBox(height: 20),
                  ],
                  if (edu.isNotEmpty) ...[
                    _atsSectionTitle('PENDIDIKAN'),
                    pw.SizedBox(height: 12),
                    ...edu.map((e) => _atsEducationCard(e)),
                    pw.SizedBox(height: 20),
                  ],
                  if (pub.isNotEmpty) ...[
                    _atsSectionTitle('PUBLIKASI'),
                    pw.SizedBox(height: 12),
                    ...pub.map((p) => _atsPublicationCard(p)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ));
  }

  // ==================== ATS TEMPLATE 2 ====================
  static void _buildAts2Template(
      pw.Document doc,
      String name,
      String email,
      String phone,
      String address,
      String linkedin,
      String github,
      String summary,
      List<Education> edu,
      List<Experience> exp,
      List<Skill> skills,
      List<Achievement> ach,
      List<Publication> pub,
      pw.MemoryImage? photo) {
    
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Text(name, style: _boldStyle(size: 22, color: _cPrimaryDark)),
        pw.SizedBox(height: 4),
        pw.Text('CURRICULUM VITAE', style: _regularStyle(size: 10, color: _cGrey500)),
        pw.SizedBox(height: 16),
        pw.Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            if (phone.isNotEmpty) _contactText(phone),
            if (email.isNotEmpty) _contactText(email),
            if (address.isNotEmpty) _contactText(address),
            if (linkedin.isNotEmpty) _contactText(linkedin),
            if (github.isNotEmpty) _contactText(github),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Container(height: 1, color: _cGrey200),
        pw.SizedBox(height: 24),
        
        if (summary.isNotEmpty) ...[
          pw.Text(summary, style: _regularStyle(size: 10.5), textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 24),
        ],
        
        if (exp.isNotEmpty) ...[
          pw.Text('PENGALAMAN KERJA', style: _boldStyle(size: 12, color: _cSecondary)),
          pw.SizedBox(height: 12),
          ...exp.map((e) => _ats2ExperienceCard(e)),
          pw.SizedBox(height: 24),
        ],
        
        if (edu.isNotEmpty) ...[
          pw.Text('PENDIDIKAN', style: _boldStyle(size: 12, color: _cSecondary)),
          pw.SizedBox(height: 12),
          ...edu.map((e) => _ats2EducationCard(e)),
          pw.SizedBox(height: 24),
        ],
        
        if (skills.isNotEmpty) ...[
          pw.Text('KETERAMPILAN', style: _boldStyle(size: 12, color: _cSecondary)),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: skills.map((s) => pw.Text('• ${s.name}', style: _regularStyle(size: 9.5))).toList(),
          ),
          pw.SizedBox(height: 24),
        ],
        
        if (ach.isNotEmpty) ...[
          pw.Text('PENCAPAIAN', style: _boldStyle(size: 12, color: _cSecondary)),
          pw.SizedBox(height: 8),
          ...ach.map((a) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text('• ${a.title}', style: _regularStyle(size: 9.5)),
          )),
          pw.SizedBox(height: 24),
        ],
        
        if (pub.isNotEmpty) ...[
          pw.Text('PUBLIKASI', style: _boldStyle(size: 12, color: _cSecondary)),
          pw.SizedBox(height: 8),
          ...pub.map((p) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text('• ${p.title}', style: _regularStyle(size: 9.5)),
          )),
        ],
      ],
    ));
  }

  // ==================== CREATIVE TEMPLATE 1 ====================
  static void _buildCreativeTemplate(
      pw.Document doc,
      String name,
      String email,
      String phone,
      String address,
      String linkedin,
      String github,
      String summary,
      List<Education> edu,
      List<Experience> exp,
      List<Skill> skills,
      List<Achievement> ach,
      List<Publication> pub,
      pw.MemoryImage? photo) {
    
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Sidebar kiri - width fixed
            pw.SizedBox(
              width: 170,
              child: pw.Container(
                color: _cSecondary,
                padding: const pw.EdgeInsets.all(24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (photo != null) ...[
                      pw.Center(
                        child: pw.Container(
                          width: 100,
                          height: 100,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(color: _cWhite, width: 2),
                          ),
                          child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
                        ),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                    pw.Center(
                      child: pw.Text(name, style: _boldStyle(size: 14, color: _cWhite), textAlign: pw.TextAlign.center),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Center(
                      child: pw.Container(width: 40, height: 2, color: _opacity(_cWhite, 0.5)),
                    ),
                    pw.SizedBox(height: 24),
                    _creativeSidebarSection('KONTAK', [
                      if (phone.isNotEmpty) phone,
                      if (email.isNotEmpty) email,
                      if (address.isNotEmpty) address,
                      if (linkedin.isNotEmpty) linkedin,
                      if (github.isNotEmpty) github,
                    ]),
                    pw.SizedBox(height: 20),
                    if (skills.isNotEmpty)
                      _creativeSidebarSection('KETERAMPILAN', skills.map((s) => s.name).toList()),
                    pw.SizedBox(height: 20),
                    if (ach.isNotEmpty)
                      _creativeSidebarSection('PENCAPAIAN', ach.map((a) => a.title).toList()),
                  ],
                ),
              ),
            ),
            
            // Main Content
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(30),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (summary.isNotEmpty) ...[
                      pw.Text(summary, style: _regularStyle(size: 10.5), textAlign: pw.TextAlign.justify),
                      pw.SizedBox(height: 24),
                    ],
                    if (exp.isNotEmpty) ...[
                      pw.Text('PENGALAMAN KERJA', style: _boldStyle(size: 12, color: _cPrimaryDark)),
                      pw.SizedBox(height: 12),
                      ...exp.map((e) => _creativeExperienceCard(e)),
                      pw.SizedBox(height: 20),
                    ],
                    if (edu.isNotEmpty) ...[
                      pw.Text('PENDIDIKAN', style: _boldStyle(size: 12, color: _cPrimaryDark)),
                      pw.SizedBox(height: 12),
                      ...edu.map((e) => _creativeEducationCard(e)),
                      pw.SizedBox(height: 20),
                    ],
                    if (pub.isNotEmpty) ...[
                      pw.Text('PUBLIKASI', style: _boldStyle(size: 12, color: _cPrimaryDark)),
                      pw.SizedBox(height: 12),
                      ...pub.map((p) => _atsPublicationCard(p)),
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

  // ==================== CREATIVE TEMPLATE 2 ====================
  static void _buildCreative2Template(
      pw.Document doc,
      String name,
      String email,
      String phone,
      String address,
      String linkedin,
      String github,
      String summary,
      List<Education> edu,
      List<Experience> exp,
      List<Skill> skills,
      List<Achievement> ach,
      List<Publication> pub,
      pw.MemoryImage? photo) {
    
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Sidebar kiri dengan gradien
            pw.SizedBox(
              width: 170,
              child: pw.Container(
                decoration: const pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [_cPrimaryDark, _cPrimary],
                    begin: pw.Alignment.topCenter,
                    end: pw.Alignment.bottomCenter,
                  ),
                ),
                padding: const pw.EdgeInsets.all(24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (photo != null) ...[
                      pw.Container(
                        width: 110,
                        height: 110,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: _cWhite, width: 3),
                        ),
                        child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
                      ),
                      pw.SizedBox(height: 16),
                    ],
                    pw.Text(name, style: _boldStyle(size: 14, color: _cWhite), textAlign: pw.TextAlign.center),
                    pw.SizedBox(height: 8),
                    pw.Container(width: 40, height: 2, color: _opacity(_cWhite, 0.5)),
                    pw.SizedBox(height: 24),
                    _creative2SidebarSection('KONTAK', [
                      if (phone.isNotEmpty) phone,
                      if (email.isNotEmpty) email,
                      if (address.isNotEmpty) address,
                      if (linkedin.isNotEmpty) linkedin,
                      if (github.isNotEmpty) github,
                    ]),
                    pw.SizedBox(height: 24),
                    if (skills.isNotEmpty)
                      _creative2SidebarSection('KETERAMPILAN', skills.map((s) => s.name).toList()),
                    pw.SizedBox(height: 24),
                    if (ach.isNotEmpty)
                      _creative2SidebarSection('PENCAPAIAN', ach.map((a) => a.title).toList()),
                  ],
                ),
              ),
            ),
            
            // Main Content
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(30),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(width: 4, height: 24, color: _cPrimary),
                        pw.SizedBox(width: 8),
                        pw.Text('PROFIL', style: _boldStyle(size: 14, color: _cSecondary)),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    if (summary.isNotEmpty) ...[
                      pw.Text(summary, style: _regularStyle(size: 10.5), textAlign: pw.TextAlign.justify),
                      pw.SizedBox(height: 28),
                    ],
                    
                    if (exp.isNotEmpty) ...[
                      pw.Row(
                        children: [
                          pw.Container(width: 4, height: 20, color: _cPrimary),
                          pw.SizedBox(width: 8),
                          pw.Text('PENGALAMAN KERJA', style: _boldStyle(size: 13, color: _cSecondary)),
                        ],
                      ),
                      pw.SizedBox(height: 16),
                      ...exp.map((e) => _creative2ExperienceCard(e)),
                      pw.SizedBox(height: 28),
                    ],
                    
                    if (edu.isNotEmpty) ...[
                      pw.Row(
                        children: [
                          pw.Container(width: 4, height: 20, color: _cPrimary),
                          pw.SizedBox(width: 8),
                          pw.Text('PENDIDIKAN', style: _boldStyle(size: 13, color: _cSecondary)),
                        ],
                      ),
                      pw.SizedBox(height: 16),
                      ...edu.map((e) => _creative2EducationCard(e)),
                      pw.SizedBox(height: 28),
                    ],
                    
                    if (pub.isNotEmpty) ...[
                      pw.Row(
                        children: [
                          pw.Container(width: 4, height: 20, color: _cPrimary),
                          pw.SizedBox(width: 8),
                          pw.Text('PUBLIKASI', style: _boldStyle(size: 13, color: _cSecondary)),
                        ],
                      ),
                      pw.SizedBox(height: 16),
                      ...pub.map((p) => _creative2PublicationCard(p)),
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

  // ==================== WIDGET PEMBANTU ====================
  
  static pw.Widget _contactText(String text) {
    return pw.Text(text, style: _regularStyle(size: 9, color: _cGrey600));
  }
  
  static pw.Widget _atsSectionTitle(String title) {
    return pw.Text(title, style: _boldStyle(size: 11, color: _cPrimaryDark));
  }
  
  static pw.Widget _atsExperienceCard(Experience e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(e.position, style: _boldStyle(size: 11))),
              pw.Text('${e.startYear} - ${e.endYear}', style: _regularStyle(size: 9, color: _cGrey500)),
            ],
          ),
          pw.Text(e.organization, style: _italicStyle(size: 10, color: _cPrimary)),
          pw.SizedBox(height: 6),
          if (e.description.isNotEmpty)
            pw.Text(e.description, style: _regularStyle(size: 9.5), textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 4),
          pw.Container(height: 1, color: _cGrey200),
        ],
      ),
    );
  }
  
  static pw.Widget _atsEducationCard(Education e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(e.university, style: _boldStyle(size: 11)),
          pw.Text(e.major, style: _regularStyle(size: 10)),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${e.startYear} - ${e.endYear}', style: _regularStyle(size: 9, color: _cGrey500)),
              if (e.gpa != null) pw.Text('IPK: ${e.gpa}', style: _boldStyle(size: 9, color: _cPrimary)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Container(height: 1, color: _cGrey200),
        ],
      ),
    );
  }
  
  static pw.Widget _atsPublicationCard(Publication p) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p.title, style: _boldStyle(size: 10.5)),
          if (p.journal.isNotEmpty || p.year.isNotEmpty)
            pw.Text([p.journal, p.year].where((s) => s.isNotEmpty).join(' · '),
                style: _italicStyle(size: 9.5)),
          pw.SizedBox(height: 4),
          pw.Container(height: 1, color: _cGrey200),
        ],
      ),
    );
  }
  
  static pw.Widget _ats2ExperienceCard(Experience e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(e.position, style: _boldStyle(size: 11)),
          pw.Text('${e.organization} | ${e.startYear} - ${e.endYear}', 
              style: _regularStyle(size: 9.5, color: _cGrey600)),
          if (e.description.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(e.description, style: _regularStyle(size: 9.5)),
          ],
        ],
      ),
    );
  }
  
  static pw.Widget _ats2EducationCard(Education e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text('${e.university} - ${e.major} (${e.startYear}-${e.endYear})',
          style: _regularStyle(size: 10)),
    );
  }
  
  static pw.Widget _creativeSidebarSection(String title, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: _boldStyle(size: 10, color: _opacity(_cWhite, 0.8))),
        pw.SizedBox(height: 6),
        pw.Container(height: 1, color: _opacity(_cWhite, 0.3)),
        pw.SizedBox(height: 8),
        ...items.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(item, style: _regularStyle(size: 9, color: _cWhite)),
        )),
      ],
    );
  }
  
  static pw.Widget _creativeExperienceCard(Experience e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(e.position, style: _boldStyle(size: 11)),
          pw.Text(e.organization, style: _italicStyle(size: 10, color: _cPrimary)),
          pw.Text('${e.startYear} - ${e.endYear}', style: _regularStyle(size: 9, color: _cGrey500)),
          if (e.description.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(e.description, style: _regularStyle(size: 9.5)),
          ],
          pw.SizedBox(height: 4),
          pw.Container(height: 1, color: _cGrey200),
        ],
      ),
    );
  }
  
  static pw.Widget _creativeEducationCard(Education e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(e.university, style: _boldStyle(size: 11)),
          pw.Text(e.major, style: _regularStyle(size: 10)),
          pw.Text('${e.startYear} - ${e.endYear}', style: _regularStyle(size: 9, color: _cGrey500)),
          pw.SizedBox(height: 4),
          pw.Container(height: 1, color: _cGrey200),
        ],
      ),
    );
  }
  
  static pw.Widget _creative2SidebarSection(String title, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: _boldStyle(size: 10, color: _opacity(_cWhite, 0.8))),
        pw.SizedBox(height: 6),
        pw.Container(height: 1, color: _opacity(_cWhite, 0.3)),
        pw.SizedBox(height: 8),
        ...items.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(item, style: _regularStyle(size: 9, color: _cWhite)),
        )),
      ],
    );
  }
  
  static pw.Widget _creative2ExperienceCard(Experience e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(e.position, style: _boldStyle(size: 11))),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: _cPrimaryLight,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text('${e.startYear} - ${e.endYear}', style: _regularStyle(size: 8.5, color: _cPrimaryDark)),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(e.organization, style: _italicStyle(size: 10, color: _cPrimary)),
          if (e.description.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(e.description, style: _regularStyle(size: 9.5)),
          ],
          pw.SizedBox(height: 8),
          pw.Container(height: 1, color: _cGrey200),
        ],
      ),
    );
  }
  
  static pw.Widget _creative2EducationCard(Education e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(e.university, style: _boldStyle(size: 11)),
          pw.Text(e.major, style: _regularStyle(size: 10)),
          pw.Text('${e.startYear} - ${e.endYear}', style: _regularStyle(size: 9, color: _cGrey500)),
          pw.SizedBox(height: 8),
          pw.Container(height: 1, color: _cGrey200),
        ],
      ),
    );
  }
  
  static pw.Widget _creative2PublicationCard(Publication p) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p.title, style: _boldStyle(size: 10.5)),
          if (p.journal.isNotEmpty || p.year.isNotEmpty)
            pw.Text([p.journal, p.year].where((s) => s.isNotEmpty).join(' · '),
                style: _italicStyle(size: 9.5)),
          pw.SizedBox(height: 6),
          pw.Container(height: 1, color: _cGrey200),
        ],
      ),
    );
  }
}