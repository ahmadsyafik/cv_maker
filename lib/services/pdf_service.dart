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

// ─── Warna Profesional (Palet Slate & Blue) ───────────────────────────────────
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
const _cGrey100 = PdfColor.fromInt(0xFFF1F5F9);

// ─── Font Singleton ──────────────────────────────────────────────────────────
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
  return pw.TextStyle(font: _regular, fontSize: size, color: color ?? _cGrey700, lineSpacing: 1.2);
}

pw.TextStyle _boldStyle({double size = 10, PdfColor? color}) {
  return pw.TextStyle(font: _bold, fontSize: size, color: color ?? _cBlack, lineSpacing: 1.2);
}

pw.TextStyle _italicStyle({double size = 10, PdfColor? color}) {
  return pw.TextStyle(font: _italic, fontSize: size, color: color ?? _cGrey600, lineSpacing: 1.2);
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
              if (photo != null) ...[
                pw.Container(
                  width: 90,
                  height: 90,
                  decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle),
                  child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
                ),
                pw.SizedBox(height: 12),
              ],
              pw.Text(name.toUpperCase(), style: _boldStyle(size: 22, color: _cSecondary), textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 12,
                runSpacing: 6,
                alignment: pw.WrapAlignment.center,
                children: [
                  if (phone.isNotEmpty) _contactText(phone),
                  if (email.isNotEmpty) _contactText(' |  $email'),
                  if (address.isNotEmpty) _contactText(' |  $address'),
                  if (linkedin.isNotEmpty) _contactText(' |  $linkedin'),
                  if (github.isNotEmpty) _contactText(' |  $github'),
                ],
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 20),
        pw.Container(height: 1, color: _cGrey300),
        pw.SizedBox(height: 20),
        
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Kolom Kiri (Lebih Sempit)
            pw.Expanded(
              flex: 4,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (summary.isNotEmpty) ...[
                    _atsSectionTitle('TENTANG SAYA'),
                    pw.SizedBox(height: 6),
                    pw.Text(summary, style: _regularStyle(size: 9.5), textAlign: pw.TextAlign.justify, softWrap: true),
                    pw.SizedBox(height: 20),
                  ],
                  if (skills.isNotEmpty) ...[
                    _atsSectionTitle('KETERAMPILAN'),
                    pw.SizedBox(height: 6),
                    ...skills.map((s) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 3.5),
                            child: pw.Container(width: 3, height: 3, decoration: const pw.BoxDecoration(color: _cPrimary, shape: pw.BoxShape.circle)),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Expanded(child: pw.Text(s.name, style: _regularStyle(size: 9.5), softWrap: true)),
                        ],
                      ),
                    )),
                    pw.SizedBox(height: 20),
                  ],
                  if (ach.isNotEmpty) ...[
                    _atsSectionTitle('PENCAPAIAN'),
                    pw.SizedBox(height: 6),
                    ...ach.map((a) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('• ${a.title}', style: _boldStyle(size: 9.5, color: _cPrimaryDark), softWrap: true),
                          if (a.description.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 8, top: 2),
                              child: pw.Text(a.description, style: _regularStyle(size: 9), textAlign: pw.TextAlign.justify, softWrap: true),
                            ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
            
            pw.SizedBox(width: 24),
            
            // Kolom Kanan (Lebih Lebar)
            pw.Expanded(
              flex: 6,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (exp.isNotEmpty) ...[
                    _atsSectionTitle('PENGALAMAN KERJA'),
                    pw.SizedBox(height: 8),
                    ...exp.map((e) => _atsExperienceCard(e)),
                    pw.SizedBox(height: 16),
                  ],
                  if (edu.isNotEmpty) ...[
                    _atsSectionTitle('PENDIDIKAN'),
                    pw.SizedBox(height: 8),
                    ...edu.map((e) => _atsEducationCard(e)),
                    pw.SizedBox(height: 16),
                  ],
                  if (pub.isNotEmpty) ...[
                    _atsSectionTitle('PUBLIKASI'),
                    pw.SizedBox(height: 8),
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

  // ==================== ATS TEMPLATE 2 (DENGAN FOTO PROFIL) ====================
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
        // Header dengan foto profil di kanan
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(name, style: _boldStyle(size: 22, color: _cPrimaryDark)),
                  pw.SizedBox(height: 6),
                  pw.Container(width: 60, height: 2.5, color: _cPrimary),
                  pw.SizedBox(height: 10),
                  pw.Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      if (phone.isNotEmpty) _ats2ContactItem(phone),
                      if (email.isNotEmpty) _ats2ContactItem('•  $email'),
                      if (address.isNotEmpty) _ats2ContactItem('•  $address'),
                      if (linkedin.isNotEmpty) _ats2ContactItem('•  $linkedin'),
                      if (github.isNotEmpty) _ats2ContactItem('•  $github'),
                    ],
                  ),
                ],
              ),
            ),
            if (photo != null)
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: _cPrimary, width: 2),
                ),
                child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
              ),
          ],
        ),
        
        pw.SizedBox(height: 20),
        pw.Container(height: 1, color: _cGrey200),
        pw.SizedBox(height: 20),
        
        if (summary.isNotEmpty) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _cGrey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(summary, style: _regularStyle(size: 10), textAlign: pw.TextAlign.justify, softWrap: true),
          ),
          pw.SizedBox(height: 20),
        ],
        
        if (exp.isNotEmpty) ...[
          _sectionHeaderAts2('PENGALAMAN KERJA'),
          pw.SizedBox(height: 10),
          ...exp.map((e) => _ats2ExperienceCard(e)),
          pw.SizedBox(height: 16),
        ],
        
        if (edu.isNotEmpty) ...[
          _sectionHeaderAts2('PENDIDIKAN'),
          pw.SizedBox(height: 10),
          ...edu.map((e) => _ats2EducationCard(e)),
          pw.SizedBox(height: 16),
        ],
        
        if (skills.isNotEmpty) ...[
          _sectionHeaderAts2('KETERAMPILAN'),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((s) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: pw.BoxDecoration(
                color: _cPrimaryLight,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(s.name, style: _boldStyle(size: 9, color: _cPrimaryDark)),
            )).toList(),
          ),
          pw.SizedBox(height: 20),
        ],
        
        if (ach.isNotEmpty) ...[
          _sectionHeaderAts2('PENCAPAIAN'),
          pw.SizedBox(height: 10),
          ...ach.map((a) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text('• ${a.title} ${a.description.isNotEmpty ? "- ${a.description}" : ""}', style: _regularStyle(size: 10), softWrap: true),
          )),
          pw.SizedBox(height: 16),
        ],
        
        if (pub.isNotEmpty) ...[
          _sectionHeaderAts2('PUBLIKASI'),
          pw.SizedBox(height: 10),
          ...pub.map((p) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text('• ${p.title} ${p.journal.isNotEmpty ? "(${p.journal})" : ""}', style: _regularStyle(size: 10), softWrap: true),
          )),
        ],
      ],
    ));
  }

// ==================== CREATIVE TEMPLATE 1 (FIXED COMPILER ERROR) ====================
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
      // Menggunakan pageTheme untuk menggambar background penuh lewat buildBackground
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        buildBackground: (context) => pw.Container(
          color: _cWhite, // Warna dasar halaman utama
          child: pw.Row(
            children: [
              pw.Container(
                width: 190,
                color: _cSecondary, // Warna sidebar kiri ditarik full dari atas sampai bawah kertas
              ),
            ],
          ),
        ),
      ),
      build: (context) => [
        pw.Partitions(
          children: [
            // Sidebar Kiri (Hanya Konten)
            pw.Partition(
              width: 190,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (photo != null) ...[
                      pw.Center(
                        child: pw.Container(
                          width: 90,
                          height: 90,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(color: _cPrimary, width: 2),
                          ),
                          child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
                        ),
                      ),
                      pw.SizedBox(height: 16),
                    ],
                    pw.Text(name, style: _boldStyle(size: 16, color: _cWhite), textAlign: pw.TextAlign.center),
                    pw.SizedBox(height: 8),
                    pw.Container(width: 40, height: 2, color: _cPrimary),
                    pw.SizedBox(height: 24),
                    
                    _creativeSidebarSection('KONTAK', [
                      if (phone.isNotEmpty) 'Telp: $phone',
                      if (email.isNotEmpty) 'Email: $email',
                      if (address.isNotEmpty) 'Lokasi: $address',
                      if (linkedin.isNotEmpty) 'LinkedIn: $linkedin',
                      if (github.isNotEmpty) 'GitHub: $github',
                    ]),
                    
                    if (skills.isNotEmpty) ...[
                      pw.SizedBox(height: 20),
                      _creativeSidebarSection('KETERAMPILAN', skills.map((s) => s.name).toList()),
                    ],
                    
                    if (ach.isNotEmpty) ...[
                      pw.SizedBox(height: 20),
                      _creativeSidebarSection('PENCAPAIAN', ach.map((a) => a.title).toList()),
                    ],
                  ],
                ),
              ),
            ),
            
            // Konten Utama Kanan
            pw.Partition(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(30),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (summary.isNotEmpty) ...[
                      _sectionHeaderCreative('TENTANG SAYA'),
                      pw.SizedBox(height: 10),
                      pw.Text(summary, style: _regularStyle(size: 10), textAlign: pw.TextAlign.justify, softWrap: true),
                      pw.SizedBox(height: 24),
                    ],
                    
                    if (exp.isNotEmpty) ...[
                      _sectionHeaderCreative('PENGALAMAN KERJA'),
                      pw.SizedBox(height: 12),
                      ...exp.map((e) => _creativeExperienceCard(e)),
                      pw.SizedBox(height: 16),
                    ],
                    
                    if (edu.isNotEmpty) ...[
                      _sectionHeaderCreative('PENDIDIKAN'),
                      pw.SizedBox(height: 12),
                      ...edu.map((e) => _creativeEducationCard(e)),
                      pw.SizedBox(height: 16),
                    ],
                    
                    if (pub.isNotEmpty) ...[
                      _sectionHeaderCreative('PUBLIKASI'),
                      pw.SizedBox(height: 12),
                      ...pub.map((p) => _publicationCard(p)),
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
      margin: const pw.EdgeInsets.all(35),
      build: (context) => [
        // Top Header Banner
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            gradient: const pw.LinearGradient(
              colors: [_cPrimaryDark, _cPrimary],
              begin: pw.Alignment.centerLeft,
              end: pw.Alignment.centerRight,
            ),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(name, style: _boldStyle(size: 22, color: _cWhite)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      summary.isNotEmpty ? '${summary.split('.').first}.' : 'Professional Profile',
                      style: _regularStyle(size: 9.5, color: _opacity(_cWhite, 0.95)),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              if (photo != null) ...[
                pw.SizedBox(width: 16),
                pw.Container(
                  width: 70,
                  height: 70,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: _cWhite, width: 2),
                  ),
                  child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
                ),
              ],
            ],
          ),
        ),
        
        pw.SizedBox(height: 16),
        
        // Contact Widget Box
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: pw.BoxDecoration(
              color: _cPrimaryLight,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Wrap(
              spacing: 14,
              runSpacing: 6,
              alignment: pw.WrapAlignment.center,
              children: [
                if (phone.isNotEmpty) pw.Text(phone, style: _boldStyle(size: 9, color: _cPrimaryDark)),
                if (email.isNotEmpty) pw.Text(email, style: _boldStyle(size: 9, color: _cPrimaryDark)),
                if (address.isNotEmpty) pw.Text(address, style: _boldStyle(size: 9, color: _cPrimaryDark)),
                if (linkedin.isNotEmpty) pw.Text(linkedin, style: _boldStyle(size: 9, color: _cPrimaryDark)),
                if (github.isNotEmpty) pw.Text(github, style: _boldStyle(size: 9, color: _cPrimaryDark)),
              ],
            ),
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        // Split Column Modern Layout
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left Column
            pw.Expanded(
              flex: 45,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (skills.isNotEmpty) ...[
                    _modernSectionBlue('KETERAMPILAN', children: [
                      pw.Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: skills.map((s) => _skillTagBlue(s.name)).toList(),
                      ),
                    ]),
                    pw.SizedBox(height: 20),
                  ],
                  if (ach.isNotEmpty) ...[
                    _modernSectionBlue('PENCAPAIAN', children: [
                      ...ach.map((a) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Text('• ${a.title}', style: _regularStyle(size: 9.5), softWrap: true),
                      )),
                    ]),
                  ],
                ],
              ),
            ),
            
            pw.SizedBox(width: 20),
            
            // Right Column
            pw.Expanded(
              flex: 55,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (exp.isNotEmpty) ...[
                    _modernSectionBlue('PENGALAMAN KERJA', children: [
                      ...exp.map((e) => _modernExperienceCardBlue(e)),
                    ]),
                    pw.SizedBox(height: 16),
                  ],
                  if (edu.isNotEmpty) ...[
                    _modernSectionBlue('PENDIDIKAN', children: [
                      ...edu.map((e) => _modernEducationCardBlue(e)),
                    ]),
                    pw.SizedBox(height: 16),
                  ],
                  if (pub.isNotEmpty) ...[
                    _modernSectionBlue('PUBLIKASI', children: [
                      ...pub.map((p) => _publicationCardBlue(p)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ));
  }

  // ==================== WIDGET PEMBANTU KECIL ====================
  
  static pw.Widget _contactText(String text) {
    return pw.Text(text, style: _regularStyle(size: 9.5, color: _cGrey600));
  }
  
  static pw.Widget _atsSectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: _boldStyle(size: 11, color: _cPrimaryDark)),
        pw.SizedBox(height: 3),
        pw.Container(height: 1, color: _cGrey300),
      ]
    );
  }
  
  static pw.Widget _sectionHeaderAts2(String title) {
    return pw.Row(
      children: [
        pw.Container(width: 3.5, height: 14, color: _cPrimary),
        pw.SizedBox(width: 6),
        pw.Text(title, style: _boldStyle(size: 12, color: _cSecondary)),
      ],
    );
  }

  static pw.Widget _sectionHeaderCreative(String title) {
    return pw.Row(
      children: [
        pw.Container(width: 4, height: 16, color: _cPrimary),
        pw.SizedBox(width: 8),
        pw.Text(title, style: _boldStyle(size: 12, color: _cSecondary)),
      ],
    );
  }
  
  static pw.Widget _ats2ContactItem(String text) {
    return pw.Text(text, style: _regularStyle(size: 9.5, color: _cGrey600));
  }
  
  static pw.Widget _atsExperienceCard(Experience e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text(e.position, style: _boldStyle(size: 10.5), softWrap: true)),
              pw.SizedBox(width: 8),
              pw.Text(e.endYear == "Sekarang" ? "Sekarang" : "${e.startYear} - ${e.endYear}", style: _regularStyle(size: 9, color: _cGrey500)),
            ],
          ),
          pw.Text(e.organization, style: _italicStyle(size: 9.5, color: _cPrimary)),
          if (e.description.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(e.description, style: _regularStyle(size: 9.5), textAlign: pw.TextAlign.justify, softWrap: true),
          ],
        ],
      ),
    );
  }
  
  static pw.Widget _atsEducationCard(Education e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text(e.university, style: _boldStyle(size: 10.5), softWrap: true)),
              pw.SizedBox(width: 8),
              pw.Text(e.endYear == "Sekarang" ? "Sekarang" : "${e.startYear} - ${e.endYear}", style: _regularStyle(size: 9, color: _cGrey500)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(e.major, style: _regularStyle(size: 10), softWrap: true)),
              if (e.gpa != null) pw.Text('IPK: ${e.gpa}', style: _boldStyle(size: 9, color: _cPrimaryDark)),
            ],
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _atsPublicationCard(Publication p) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p.title, style: _boldStyle(size: 10), softWrap: true),
          if (p.journal.isNotEmpty || p.year.isNotEmpty)
            pw.Text('${p.journal} · ${p.year}', style: _italicStyle(size: 9)),
        ],
      ),
    );
  }
  
  static pw.Widget _ats2ExperienceCard(Experience e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(e.position, style: _boldStyle(size: 10.5, color: _cPrimaryDark), softWrap: true)),
              pw.Text(e.endYear == "Sekarang" ? "Sekarang" : "${e.startYear} - ${e.endYear}", style: _regularStyle(size: 9, color: _cGrey500)),
            ],
          ),
          pw.Text(e.organization, style: _regularStyle(size: 9.5, color: _cGrey600), softWrap: true),
          if (e.description.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(e.description, style: _regularStyle(size: 9.5), textAlign: pw.TextAlign.justify, softWrap: true),
          ],
        ],
      ),
    );
  }
  
  static pw.Widget _ats2EducationCard(Education e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(e.university, style: _boldStyle(size: 10.5, color: _cPrimaryDark), softWrap: true)),
              pw.Text(e.endYear == "Sekarang" ? "Sekarang" : "${e.startYear} - ${e.endYear}", style: _regularStyle(size: 9, color: _cGrey500)),
            ],
          ),
          pw.Text(e.major, style: _regularStyle(size: 9.5, color: _cGrey600), softWrap: true),
        ],
      ),
    );
  }
  
  static pw.Widget _creativeSidebarSection(String title, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: _boldStyle(size: 10, color: _opacity(_cWhite, 0.75))),
        pw.SizedBox(height: 4),
        pw.Container(height: 1, color: _opacity(_cWhite, 0.2)),
        pw.SizedBox(height: 6),
        ...items.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Text(item, style: _regularStyle(size: 9, color: _cWhite), softWrap: true),
        )),
      ],
    );
  }
  
  static pw.Widget _creativeExperienceCard(Experience e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(e.position, style: _boldStyle(size: 10.5), softWrap: true)),
              pw.Text(e.endYear == "Sekarang" ? "Sekarang" : "${e.startYear} - ${e.endYear}", style: _regularStyle(size: 9, color: _cGrey500)),
            ],
          ),
          pw.Text(e.organization, style: _italicStyle(size: 9.5, color: _cPrimary), softWrap: true),
          if (e.description.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(e.description, style: _regularStyle(size: 9.5), textAlign: pw.TextAlign.justify, softWrap: true),
          ],
        ],
      ),
    );
  }
  
  static pw.Widget _creativeEducationCard(Education e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(e.university, style: _boldStyle(size: 10.5), softWrap: true)),
              pw.Text(e.endYear == "Sekarang" ? "Sekarang" : "${e.startYear} - ${e.endYear}", style: _regularStyle(size: 9, color: _cGrey500)),
            ],
          ),
          pw.Text(e.major, style: _regularStyle(size: 9.5), softWrap: true),
        ],
      ),
    );
  }
  
  static pw.Widget _publicationCard(Publication p) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p.title, style: _boldStyle(size: 10), softWrap: true),
          if (p.journal.isNotEmpty || p.year.isNotEmpty)
            pw.Text('${p.journal} · ${p.year}', style: _italicStyle(size: 9)),
        ],
      ),
    );
  }
  
  static pw.Widget _modernSectionBlue(String title, {required List<pw.Widget> children}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: _boldStyle(size: 11, color: _cPrimaryDark)),
        pw.SizedBox(height: 4),
        pw.Container(height: 2, width: 30, color: _cPrimary),
        pw.SizedBox(height: 10),
        ...children,
      ],
    );
  }
  
  static pw.Widget _skillTagBlue(String skill) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _cPrimaryLight,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(skill, style: _regularStyle(size: 9, color: _cPrimaryDark), softWrap: true),
    );
  }
  
  static pw.Widget _modernExperienceCardBlue(Experience e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(e.position, style: _boldStyle(size: 10.5), softWrap: true),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(e.organization, style: _italicStyle(size: 9, color: _cPrimary), softWrap: true)),
              pw.Text(e.endYear == "Sekarang" ? "Sekarang" : "${e.startYear} - ${e.endYear}", style: _regularStyle(size: 8.5, color: _cGrey500)),
            ],
          ),
          if (e.description.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(e.description, style: _regularStyle(size: 9), textAlign: pw.TextAlign.justify, softWrap: true),
          ],
        ],
      ),
    );
  }
  
  static pw.Widget _modernEducationCardBlue(Education e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(e.university, style: _boldStyle(size: 10.5), softWrap: true)),
              pw.Text(e.endYear == "Sekarang" ? "Sekarang" : "${e.startYear} - ${e.endYear}", style: _regularStyle(size: 8.5, color: _cGrey500)),
            ],
          ),
          pw.Text(e.major, style: _regularStyle(size: 9), softWrap: true),
        ],
      ),
    );
  }
  
  static pw.Widget _publicationCardBlue(Publication p) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p.title, style: _boldStyle(size: 10), softWrap: true),
          if (p.journal.isNotEmpty || p.year.isNotEmpty)
            pw.Text('${p.journal} · ${p.year}', style: _italicStyle(size: 9, color: _cGrey500)),
        ],
      ),
    );
  }
}