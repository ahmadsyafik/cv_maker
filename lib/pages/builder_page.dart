import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/cv_provider.dart';
import '../models/education.dart';
import '../models/experience.dart';
import '../models/skill.dart';
import '../models/achievement.dart';
import '../models/publication.dart';
import '../widgets/education_card.dart';
import '../widgets/experience_card.dart';
import '../widgets/skill_chip.dart';
import '../services/storage_service.dart';

const _kBlue = Color(0xFF1565C0);
const _kBg = Color(0xFFF5F7FA);

InputDecoration _inputDeco(String hint, {IconData? prefix}) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: prefix != null
          ? Icon(prefix, color: Colors.grey.shade400, size: 20)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );

Widget _primaryButton(String label, VoidCallback onPressed) => SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );

// ─── Year Picker Field ────────────────────────────────────────────────────────
class _YearPickerField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  const _YearPickerField({
    required this.controller,
    required this.hint,
    this.validator,
  });

  @override
  State<_YearPickerField> createState() => _YearPickerFieldState();
}

class _YearPickerFieldState extends State<_YearPickerField> {
  Future<void> _pickYear() async {
    final currentYear = DateTime.now().year;
    int selectedYear = int.tryParse(widget.controller.text) ?? currentYear;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pilih Tahun',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 280,
          height: 200,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return YearPicker(
                firstDate: DateTime(1950),
                lastDate: DateTime(currentYear + 5),
                selectedDate: DateTime(selectedYear),
                onChanged: (date) {
                  setDialogState(() => selectedYear = date.year);
                  widget.controller.text = date.year.toString();
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      onTap: _pickYear,
      style: GoogleFonts.poppins(fontSize: 14),
      validator: widget.validator,
      decoration: _inputDeco(widget.hint).copyWith(
        suffixIcon: const Icon(Icons.calendar_today_outlined,
            size: 18, color: Colors.grey),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BuilderPage
// ═══════════════════════════════════════════════════════════════════════════════
class BuilderPage extends StatefulWidget {
  const BuilderPage({super.key});

  @override
  State<BuilderPage> createState() => _BuilderPageState();
}

class _BuilderPageState extends State<BuilderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBlue,
        elevation: 0,
        centerTitle: true,
        title: Text('Buat CV',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
          tabs: const [
            Tab(text: 'Data Diri'),
            Tab(text: 'Pendidikan'),
            Tab(text: 'Pengalaman'),
            Tab(text: 'Skill'),
            Tab(text: 'Penghargaan'),
            Tab(text: 'Publikasi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PersonalDataTab(),
          EducationTab(),
          ExperienceTab(),
          SkillTab(),
          AchievementTab(),
          PublicationTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Tab 1 – Data Diri
// ═══════════════════════════════════════════════════════════════════════════════
class PersonalDataTab extends StatefulWidget {
  const PersonalDataTab({super.key});

  @override
  State<PersonalDataTab> createState() => _PersonalDataTabState();
}

class _PersonalDataTabState extends State<PersonalDataTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _linkedinController;
  late TextEditingController _githubController;
  late TextEditingController _summaryController;
  bool _isUploadingPhoto = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _summaryController = TextEditingController();
    _linkedinController = TextEditingController();
    _githubController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final cv = Provider.of<CVProvider>(context, listen: false);
      _nameController.text = cv.fullName;
      _emailController.text = cv.email;
      _phoneController.text = cv.phone;
      _addressController.text = cv.address;
      _summaryController.text = cv.summary;
      _linkedinController.text = cv.linkedin;
      _githubController.text = cv.github;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
  final storageService = StorageService();

  final imageFile = await storageService.pickImage(fromCamera: false);

  if (!mounted) return;
  if (imageFile == null) return;

  final messenger = ScaffoldMessenger.of(context);
  final cvProvider = context.read<CVProvider>();

  setState(() => _isUploadingPhoto = true);

  messenger.showSnackBar(
    const SnackBar(content: Text('Mengupload foto...')),
  );

  final url = await storageService.uploadCVPhoto(imageFile);

  if (!mounted) return;

  setState(() => _isUploadingPhoto = false);

  if (url != null) {
    cvProvider.updateCVPhoto(url);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Foto berhasil diupload!'),
        backgroundColor: Colors.green,
      ),
    );
  } else {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Gagal upload foto, coba lagi.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  String? _validateUrl(String? v) {
    if (v == null || v.isEmpty) return null;
    if (!v.startsWith('http://') && !v.startsWith('https://') && !v.startsWith('linkedin.com') && !v.startsWith('github.com')) {
      return 'Format URL tidak valid (contoh: https://linkedin.com/in/nama)';
    }
    return null;
  }

  void _savePersonalData() {
    if (_formKey.currentState!.validate()) {
      context.read<CVProvider>().updatePersonalData(
            fullName: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            address: _addressController.text,
            linkedin: _linkedinController.text,
            github: _githubController.text,
            summary: _summaryController.text,
          );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Data diri berhasil disimpan')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Consumer<CVProvider>(
                    builder: (context, cv, _) {
                      final String currentPhoto = cv.fotoCV;
                      return CircleAvatar(
                        key: ValueKey(currentPhoto),
                        radius: 50,
                        backgroundColor: const Color(0xFFE3F2FD),
                        backgroundImage: currentPhoto.isNotEmpty
                            ? NetworkImage(currentPhoto)
                            : null,
                        child: currentPhoto.isEmpty
                            ? const Icon(Icons.person, size: 48, color: _kBlue)
                            : null,
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingPhoto ? null : _pickImage,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                            color: _kBlue, shape: BoxShape.circle),
                        child: _isUploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.camera_alt,
                                color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: _inputDeco('Nama Lengkap', prefix: Icons.person_outline),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Nama lengkap wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              style: GoogleFonts.poppins(fontSize: 14),
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDeco('Email', prefix: Icons.email_outlined),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email wajib diisi';
                if (!v.contains('@')) return 'Email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              style: GoogleFonts.poppins(fontSize: 14),
              keyboardType: TextInputType.phone,
              decoration: _inputDeco('Nomor Telepon', prefix: Icons.phone_outlined),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              style: GoogleFonts.poppins(fontSize: 14),
              maxLines: 2,
              decoration: _inputDeco('Alamat', prefix: Icons.location_on_outlined),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _summaryController,
              style: GoogleFonts.poppins(fontSize: 14),
              maxLines: 3,
              decoration: _inputDeco('Ringkasan Profesional (Opsional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _linkedinController,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: _inputDeco('LinkedIn (Opsional)', prefix: Icons.link),
              validator: _validateUrl,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _githubController,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: _inputDeco('GitHub (Opsional)', prefix: Icons.code),
              validator: _validateUrl,
            ),
            const SizedBox(height: 24),
            _primaryButton('Simpan Data Diri', _savePersonalData),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Tab 2 – Pendidikan (unlimited, with edit fix)
// ═══════════════════════════════════════════════════════════════════════════════
class EducationTab extends StatefulWidget {
  const EducationTab({super.key});

  @override
  State<EducationTab> createState() => _EducationTabState();
}

class _EducationTabState extends State<EducationTab> {
  final _formKey = GlobalKey<FormState>();
  final _universityController = TextEditingController();
  final _majorController = TextEditingController();
  final _startYearController = TextEditingController();
  final _endYearController = TextEditingController();
  final _gpaController = TextEditingController();
  int? _editingIndex;

  @override
  void dispose() {
    _universityController.dispose();
    _majorController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _universityController.clear();
    _majorController.clear();
    _startYearController.clear();
    _endYearController.clear();
    _gpaController.clear();
    setState(() => _editingIndex = null);
  }

  void _startEdit(int index, Education edu) {
    _universityController.text = edu.university;
    _majorController.text = edu.major;
    _startYearController.text = edu.startYear;
    _endYearController.text = edu.endYear;
    _gpaController.text = edu.gpa?.toString() ?? '';
    setState(() => _editingIndex = index);
    // Scroll ke atas form
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final education = Education(
        university: _universityController.text,
        major: _majorController.text,
        startYear: _startYearController.text,
        endYear: _endYearController.text,
        gpa: _gpaController.text.isNotEmpty
            ? double.tryParse(_gpaController.text)
            : null,
      );
      if (_editingIndex != null) {
        context.read<CVProvider>().updateEducation(_editingIndex!, education);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pendidikan berhasil diperbarui')));
      } else {
        context.read<CVProvider>().addEducation(education);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pendidikan berhasil ditambahkan')));
      }
      _clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CVProvider>(
      builder: (context, cvProvider, child) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _editingIndex != null ? 'Edit Pendidikan' : 'Tambah Pendidikan',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          if (_editingIndex != null)
                            TextButton(
                              onPressed: _clearForm,
                              child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _universityController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('Nama Universitas'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _majorController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('Jurusan'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _YearPickerField(
                              controller: _startYearController,
                              hint: 'Tahun Mulai',
                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _YearPickerField(
                              controller: _endYearController,
                              hint: 'Tahun Selesai',
                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _gpaController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        decoration: _inputDeco('IPK (Opsional)'),
                      ),
                      const SizedBox(height: 16),
                      _primaryButton(
                        _editingIndex != null ? 'Simpan Perubahan' : 'Tambah Pendidikan',
                        _submitForm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: cvProvider.educations.isEmpty
                  ? _emptyState('Belum ada data pendidikan')
                  : const SizedBox.shrink(),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => EducationCard(
                    education: cvProvider.educations[index],
                    onEdit: () => _startEdit(index, cvProvider.educations[index]),
                    onDelete: () => cvProvider.removeEducation(index),
                  ),
                  childCount: cvProvider.educations.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Tab 3 – Pengalaman (unlimited, with edit fix)
// ═══════════════════════════════════════════════════════════════════════════════
class ExperienceTab extends StatefulWidget {
  const ExperienceTab({super.key});

  @override
  State<ExperienceTab> createState() => _ExperienceTabState();
}

class _ExperienceTabState extends State<ExperienceTab> {
  final _formKey = GlobalKey<FormState>();
  final _organizationController = TextEditingController();
  final _positionController = TextEditingController();
  final _startYearController = TextEditingController();
  final _endYearController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _editingIndex;

  @override
  void dispose() {
    _organizationController.dispose();
    _positionController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _organizationController.clear();
    _positionController.clear();
    _startYearController.clear();
    _endYearController.clear();
    _descriptionController.clear();
    setState(() => _editingIndex = null);
  }

  void _startEdit(int index, Experience exp) {
    _organizationController.text = exp.organization;
    _positionController.text = exp.position;
    _startYearController.text = exp.startYear;
    _endYearController.text = exp.endYear;
    _descriptionController.text = exp.description;
    setState(() => _editingIndex = index);
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final experience = Experience(
        organization: _organizationController.text,
        position: _positionController.text,
        startYear: _startYearController.text,
        endYear: _endYearController.text,
        description: _descriptionController.text,
      );
      if (_editingIndex != null) {
        context.read<CVProvider>().updateExperience(_editingIndex!, experience);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengalaman berhasil diperbarui')));
      } else {
        context.read<CVProvider>().addExperience(experience);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengalaman berhasil ditambahkan')));
      }
      _clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CVProvider>(
      builder: (context, cvProvider, child) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _editingIndex != null ? 'Edit Pengalaman' : 'Tambah Pengalaman',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          if (_editingIndex != null)
                            TextButton(
                              onPressed: _clearForm,
                              child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _organizationController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('Nama Organisasi/Perusahaan'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _positionController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('Posisi'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _YearPickerField(
                              controller: _startYearController,
                              hint: 'Tahun Mulai',
                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _YearPickerField(
                              controller: _endYearController,
                              hint: 'Tahun Selesai',
                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        maxLines: 3,
                        decoration: _inputDeco('Deskripsi'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      _primaryButton(
                        _editingIndex != null ? 'Simpan Perubahan' : 'Tambah Pengalaman',
                        _submitForm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: cvProvider.experiences.isEmpty
                  ? _emptyState('Belum ada data pengalaman')
                  : const SizedBox.shrink(),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ExperienceCard(
                    experience: cvProvider.experiences[index],
                    onEdit: () => _startEdit(index, cvProvider.experiences[index]),
                    onDelete: () => cvProvider.removeExperience(index),
                  ),
                  childCount: cvProvider.experiences.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Tab 4 – Skill
// ═══════════════════════════════════════════════════════════════════════════════
class SkillTab extends StatefulWidget {
  const SkillTab({super.key});

  @override
  State<SkillTab> createState() => _SkillTabState();
}

class _SkillTabState extends State<SkillTab> {
  final _skillController = TextEditingController();

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    if (_skillController.text.trim().isNotEmpty) {
      context.read<CVProvider>().addSkill(Skill(name: _skillController.text.trim()));
      _skillController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CVProvider>(
      builder: (context, cvProvider, child) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _skillController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('Tambah Skill'),
                        onSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: _kBlue,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _addSkill,
                        borderRadius: BorderRadius.circular(12),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.add, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: cvProvider.skills.isEmpty
                  ? _emptyState('Belum ada skill ditambahkan')
                  : const SizedBox.shrink(),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: cvProvider.skills.isEmpty
                  ? const SliverToBoxAdapter()
                  : SliverToBoxAdapter(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(
                          cvProvider.skills.length,
                          (index) => SkillChip(
                            label: cvProvider.skills[index].name,
                            onDelete: () => cvProvider.removeSkill(index),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Tab 5 – Achievement (Penghargaan)
// ═══════════════════════════════════════════════════════════════════════════════
class AchievementTab extends StatefulWidget {
  const AchievementTab({super.key});

  @override
  State<AchievementTab> createState() => _AchievementTabState();
}

class _AchievementTabState extends State<AchievementTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  int? _editingIndex;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _descController.clear();
    setState(() => _editingIndex = null);
  }

  void _startEdit(int index, Achievement a) {
    _titleController.text = a.title;
    _descController.text = a.description;
    setState(() => _editingIndex = index);
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final ach = Achievement(
          title: _titleController.text, description: _descController.text);
      if (_editingIndex != null) {
        context.read<CVProvider>().updateAchievement(_editingIndex!, ach);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Penghargaan berhasil diperbarui')));
      } else {
        context.read<CVProvider>().addAchievement(ach);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Penghargaan berhasil ditambahkan')));
      }
      _clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CVProvider>(
      builder: (context, cvProvider, child) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _editingIndex != null ? 'Edit Penghargaan' : 'Tambah Penghargaan',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          if (_editingIndex != null)
                            TextButton(
                                onPressed: _clearForm,
                                child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey))),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('Judul Penghargaan', prefix: Icons.emoji_events_outlined),
                        validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        maxLines: 2,
                        decoration: _inputDeco('Deskripsi (Opsional)'),
                      ),
                      const SizedBox(height: 16),
                      _primaryButton(
                          _editingIndex != null ? 'Simpan Perubahan' : 'Tambah Penghargaan',
                          _submit),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: cvProvider.achievements.isEmpty
                  ? _emptyState('Belum ada penghargaan')
                  : const SizedBox.shrink(),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final a = cvProvider.achievements[index];
                    return _ItemCard(
                      title: a.title,
                      subtitle: a.description,
                      icon: Icons.emoji_events_outlined,
                      iconColor: const Color(0xFFE65100),
                      iconBg: const Color(0xFFFFF3E0),
                      onEdit: () => _startEdit(index, a),
                      onDelete: () => cvProvider.removeAchievement(index),
                    );
                  },
                  childCount: cvProvider.achievements.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Tab 6 – Publikasi
// ═══════════════════════════════════════════════════════════════════════════════
class PublicationTab extends StatefulWidget {
  const PublicationTab({super.key});

  @override
  State<PublicationTab> createState() => _PublicationTabState();
}

class _PublicationTabState extends State<PublicationTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _journalController = TextEditingController();
  final _yearController = TextEditingController();
  final _urlController = TextEditingController();
  int? _editingIndex;

  @override
  void dispose() {
    _titleController.dispose();
    _journalController.dispose();
    _yearController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _journalController.clear();
    _yearController.clear();
    _urlController.clear();
    setState(() => _editingIndex = null);
  }

  void _startEdit(int index, Publication p) {
    _titleController.text = p.title;
    _journalController.text = p.journal;
    _yearController.text = p.year;
    _urlController.text = p.url;
    setState(() => _editingIndex = index);
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final pub = Publication(
        title: _titleController.text,
        journal: _journalController.text,
        year: _yearController.text,
        url: _urlController.text,
      );
      if (_editingIndex != null) {
        context.read<CVProvider>().updatePublication(_editingIndex!, pub);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publikasi berhasil diperbarui')));
      } else {
        context.read<CVProvider>().addPublication(pub);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publikasi berhasil ditambahkan')));
      }
      _clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CVProvider>(
      builder: (context, cvProvider, child) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _editingIndex != null ? 'Edit Publikasi' : 'Tambah Publikasi',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          if (_editingIndex != null)
                            TextButton(
                                onPressed: _clearForm,
                                child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey))),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('Judul Publikasi', prefix: Icons.article_outlined),
                        maxLines: 2,
                        validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _journalController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('Nama Jurnal/Konferensi (Opsional)'),
                      ),
                      const SizedBox(height: 12),
                      _YearPickerField(
                        controller: _yearController,
                        hint: 'Tahun Publikasi (Opsional)',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _urlController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('URL / DOI (Opsional)', prefix: Icons.link),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),
                      _primaryButton(
                          _editingIndex != null ? 'Simpan Perubahan' : 'Tambah Publikasi',
                          _submit),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: cvProvider.publications.isEmpty
                  ? _emptyState('Belum ada publikasi')
                  : const SizedBox.shrink(),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = cvProvider.publications[index];
                    return _ItemCard(
                      title: p.title,
                      subtitle: [p.journal, p.year].where((s) => s.isNotEmpty).join(' · '),
                      icon: Icons.article_outlined,
                      iconColor: const Color(0xFF6A1B9A),
                      iconBg: const Color(0xFFF3E5F5),
                      onEdit: () => _startEdit(index, p),
                      onDelete: () => cvProvider.removePublication(index),
                    );
                  },
                  childCount: cvProvider.publications.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Generic Item Card (Achievement & Publication) ────────────────────────────
class _ItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_outlined, size: 18, color: _kBlue),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _emptyState(String message) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
