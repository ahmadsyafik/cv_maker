import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cv_provider.dart';
import '../models/education.dart';
import '../models/experience.dart';
import '../models/skill.dart';
import '../widgets/education_card.dart';
import '../widgets/experience_card.dart';
import '../widgets/skill_chip.dart';

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
      appBar: AppBar(
        title: const Text('Builder CV'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
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

  @override
  void initState() {
    super.initState();
    final cvProvider = context.read<CVProvider>();
    _nameController = TextEditingController(text: cvProvider.fullName);
    _emailController = TextEditingController(text: cvProvider.email);
    _phoneController = TextEditingController(text: cvProvider.phone);
    _addressController = TextEditingController(text: cvProvider.address);
    _linkedinController = TextEditingController(text: cvProvider.linkedin);
    _githubController = TextEditingController(text: cvProvider.github);
    _summaryController = TextEditingController(text: cvProvider.summary);
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

  void _pickImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur upload foto akan segera hadir')),
    );
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
            // Profile Image
            Center(
              child: Stack(
                children: [
                  Consumer<CVProvider>(
                    builder: (context, cvProvider, child) {
                      return CircleAvatar(
                        radius: 50,
                        backgroundImage: cvProvider.profileImage.isNotEmpty
                            ? FileImage(File(cvProvider.profileImage))
                            : null,
                        child: cvProvider.profileImage.isEmpty
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama lengkap wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email wajib diisi';
                }
                if (!value.contains('@')) {
                  return 'Email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _summaryController,
              decoration: const InputDecoration(
                labelText: 'Ringkasan Profesional (Opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.summarize),
                hintText: 'Contoh: Lulusan baru yang antusias dengan pengalaman magang di...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _linkedinController,
              decoration: const InputDecoration(
                labelText: 'LinkedIn (Opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _githubController,
              decoration: const InputDecoration(
                labelText: 'GitHub (Opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePersonalData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Simpan Data Diri'),
              ),
            ),
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

      // Clear form
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
        return Column(
          children: [
            // Form Input
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tambah Pendidikan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _universityController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Universitas',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama universitas wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _majorController,
                      decoration: const InputDecoration(
                        labelText: 'Jurusan',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jurusan wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startYearController,
                            decoration: const InputDecoration(
                              labelText: 'Tahun Mulai',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tahun mulai wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _endYearController,
                            decoration: const InputDecoration(
                              labelText: 'Tahun Selesai',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tahun selesai wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _gpaController,
                      decoration: const InputDecoration(
                        labelText: 'IPK (Opsional)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addEducation,
                        child: const Text('Tambah Pendidikan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // List of Education
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cvProvider.educations.length,
                itemBuilder: (context, index) {
                  final education = cvProvider.educations[index];
                  return EducationCard(
                    education: education,
                    onEdit: () {
                      // Implement edit functionality
                    },
                    onDelete: () {
                      cvProvider.removeEducation(index);
                    },
                  );
                },
              ),
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

      // Clear form
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
        return Column(
          children: [
            // Form Input
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tambah Pengalaman',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _organizationController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Organisasi/Perusahaan',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama organisasi wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _positionController,
                      decoration: const InputDecoration(
                        labelText: 'Posisi',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Posisi wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startYearController,
                            decoration: const InputDecoration(
                              labelText: 'Tahun Mulai',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tahun mulai wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _endYearController,
                            decoration: const InputDecoration(
                              labelText: 'Tahun Selesai',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tahun selesai wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Deskripsi wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addExperience,
                        child: const Text('Tambah Pengalaman'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // List of Experiences
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cvProvider.experiences.length,
                itemBuilder: (context, index) {
                  final experience = cvProvider.experiences[index];
                  return ExperienceCard(
                    experience: experience,
                    onEdit: () {
                      // Implement edit functionality
                    },
                    onDelete: () {
                      cvProvider.removeExperience(index);
                    },
                  );
                },
              ),
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
    if (_skillController.text.isNotEmpty) {
      final skill = Skill(name: _skillController.text);
      context.read<CVProvider>().addSkill(skill);
      _skillController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CVProvider>(
      builder: (context, cvProvider, child) {
        return Column(
          children: [
            // Input Skill
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skillController,
                      decoration: InputDecoration(
                        labelText: 'Tambahkan Skill',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _addSkill,
                    mini: true,
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),

            // Skills List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    cvProvider.skills.length,
                        (index) => SkillChip(
                      label: cvProvider.skills[index].name,
                      onDelete: () {
                        cvProvider.removeSkill(index);
                      },
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