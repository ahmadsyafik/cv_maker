import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/cv_provider.dart';
import '../models/education.dart';
import '../models/experience.dart';
import '../models/skill.dart';
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );

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
    _tabController = TabController(length: 4, vsync: this);
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
        title: Text(
          'Buat CV',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400),
          tabs: const [
            Tab(text: 'Data Diri'),
            Tab(text: 'Pendidikan'),
            Tab(text: 'Pengalaman'),
            Tab(text: 'Skill'),
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
        ],
      ),
    );
  }
}

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
      _nameController.text = cv.fullName ?? '';
      _emailController.text = cv.email ?? '';
      _phoneController.text = cv.phone ?? '';
      _addressController.text = cv.address ?? '';
      _summaryController.text = cv.summary ?? '';
      _linkedinController.text = cv.linkedin ?? '';
      _githubController.text = cv.github ?? '';
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
    if (imageFile == null) return;

    if (!context.mounted) return;
    setState(() => _isUploadingPhoto = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengupload foto...')),
    );

    final url = await storageService.uploadCVPhoto(imageFile);

    if (!context.mounted) return;
    setState(() => _isUploadingPhoto = false);

    if (url != null) {
      context.read<CVProvider>().updateCVPhoto(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto berhasil diupload!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal upload foto, coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data diri berhasil disimpan')),
      );
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
                      final String currentPhoto = cv.fotoCV ?? '';
                      
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
                          color: _kBlue,
                          shape: BoxShape.circle,
                        ),
                        child: _isUploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
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
              decoration:
                  _inputDeco('Nama Lengkap', prefix: Icons.person_outline),
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
              decoration:
                  _inputDeco('Nomor Telepon', prefix: Icons.phone_outlined),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              style: GoogleFonts.poppins(fontSize: 14),
              maxLines: 3,
              decoration:
                  _inputDeco('Alamat', prefix: Icons.location_on_outlined),
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
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _githubController,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: _inputDeco('GitHub (Opsional)', prefix: Icons.code),
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

  @override
  void dispose() {
    _universityController.dispose();
    _majorController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  void _addEducation() {
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
      context.read<CVProvider>().addEducation(education);
      _universityController.clear();
      _majorController.clear();
      _startYearController.clear();
      _endYearController.clear();
      _gpaController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendidikan berhasil ditambahkan')),
      );
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tambah Pendidikan',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _universityController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('Nama Universitas'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Nama universitas wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _majorController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('Jurusan'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Jurusan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startYearController,
                              style: GoogleFonts.poppins(fontSize: 14),
                              keyboardType: TextInputType.number,
                              decoration: _inputDeco('Tahun Mulai'),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _endYearController,
                              style: GoogleFonts.poppins(fontSize: 14),
                              keyboardType: TextInputType.number,
                              decoration: _inputDeco('Tahun Selesai'),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _gpaController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco('IPK (Opsional)'),
                      ),
                      const SizedBox(height: 16),
                      _primaryButton('Tambah Pendidikan', _addEducation),
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
              padding: const EdgeInsets.all(16),
              sliver: cvProvider.educations.isEmpty
                  ? const SliverToBoxAdapter()
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return EducationCard(
                            education: cvProvider.educations[index],
                            onEdit: () {},
                            onDelete: () => cvProvider.removeEducation(index),
                          );
                        },
                        childCount: cvProvider.educations.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],
        );
      },
    );
  }
}

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

  @override
  void dispose() {
    _organizationController.dispose();
    _positionController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addExperience() {
    if (_formKey.currentState!.validate()) {
      final experience = Experience(
        organization: _organizationController.text,
        position: _positionController.text,
        startYear: _startYearController.text,
        endYear: _endYearController.text,
        description: _descriptionController.text,
      );
      context.read<CVProvider>().addExperience(experience);
      _organizationController.clear();
      _positionController.clear();
      _startYearController.clear();
      _endYearController.clear();
      _descriptionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengalaman berhasil ditambahkan')),
      );
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tambah Pengalaman',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _organizationController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('Nama Organisasi/Perusahaan'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Nama organisasi wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _positionController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('Posisi'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Posisi wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startYearController,
                              style: GoogleFonts.poppins(fontSize: 14),
                              keyboardType: TextInputType.number,
                              decoration: _inputDeco('Tahun Mulai'),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _endYearController,
                              style: GoogleFonts.poppins(fontSize: 14),
                              keyboardType: TextInputType.number,
                              decoration: _inputDeco('Tahun Selesai'),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Wajib diisi' : null,
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
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Deskripsi wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _primaryButton('Tambah Pengalaman', _addExperience),
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
              padding: const EdgeInsets.all(16),
              sliver: cvProvider.experiences.isEmpty
                  ? const SliverToBoxAdapter()
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ExperienceCard(
                            experience: cvProvider.experiences[index],
                            onEdit: () {},
                            onDelete: () => cvProvider.removeExperience(index),
                          );
                        },
                        childCount: cvProvider.experiences.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],
        );
      },
    );
  }
}

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
      context
          .read<CVProvider>()
          .addSkill(Skill(name: _skillController.text.trim()));
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
              padding: const EdgeInsets.all(16),
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
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],
        );
      },
    );
  }
}

Widget _emptyState(String message) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style:
                GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );