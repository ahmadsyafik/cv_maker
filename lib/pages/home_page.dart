import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../state/cv_provider.dart';
import '../providers/user_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Beranda',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Consumer2<UserProvider, CVProvider>(
        builder: (context, userProvider, cvProvider, child) {
          // DATA USER (untuk profile card)
          final displayName = userProvider.fullName.isNotEmpty
              ? userProvider.fullName
              : firebaseUser?.displayName ?? 'Nama Lengkap';
          final displayEmail = userProvider.email.isNotEmpty
              ? userProvider.email
              : firebaseUser?.email ?? 'email@example.com';
          final profileImage = userProvider.profileImage.isNotEmpty
              ? userProvider.profileImage
              : firebaseUser?.photoURL ?? '';

          // DATA CV (untuk progress dan statistik)
          final cvProgress = cvProvider.cvProgress;
          final eduCount = cvProvider.educations.length;
          final expCount = cvProvider.experiences.length;
          final skillCount = cvProvider.skills.length;

          // Progress value dan teks
          final double displayProgress = cvProgress;
          final String progressText = '${(cvProgress * 100).toStringAsFixed(0)}% Selesai';

          return RefreshIndicator(
            onRefresh: () async {
              // Hanya refresh user data, karena CVProvider mungkin sudah otomatis load
              await userProvider.fetchUserData();
              // Jika perlu refresh CV, panggil method yang tersedia
              // Misalnya: await cvProvider.loadInitialData();
              // Atau cvProvider.resetAll() dll sesuai dengan method yang ada
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Profile Image dengan CachedNetworkImage
                        _buildProfileImage(profileImage),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayEmail,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress CV Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progres CV',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: displayProgress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF1565C0),
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          progressText,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Statistik CV',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Pendidikan',
                          value: eduCount.toString(),
                          icon: Icons.school,
                          iconColor: const Color(0xFF1565C0),
                          iconBg: const Color(0xFFE3F2FD),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Pengalaman',
                          value: expCount.toString(),
                          icon: Icons.work_outline,
                          iconColor: const Color(0xFF2E7D32),
                          iconBg: const Color(0xFFE8F5E9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Skill',
                          value: skillCount.toString(),
                          icon: Icons.star_outline,
                          iconColor: const Color(0xFFE65100),
                          iconBg: const Color(0xFFFFF3E0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Items',
                          value: (eduCount + expCount + skillCount).toString(),
                          icon: Icons.folder_outlined,
                          iconColor: const Color(0xFF6A1B9A),
                          iconBg: const Color(0xFFF3E5F5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget untuk profile image dengan CachedNetworkImage
  Widget _buildProfileImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundColor: const Color(0xFFE3F2FD),
        child: const Icon(
          Icons.person,
          size: 32,
          color: Color(0xFF1565C0),
        ),
      );
    }

    return CircleAvatar(
      radius: 32,
      backgroundColor: const Color(0xFFE3F2FD),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: 64,
          height: 64,
          placeholder: (context, url) => const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
              ),
            ),
          ),
          errorWidget: (context, url, error) => const Icon(
            Icons.person,
            size: 32,
            color: Color(0xFF1565C0),
          ),
          cacheKey: imageUrl,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}