import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../state/cv_provider.dart';
import '../providers/user_provider.dart';
import '../services/storage_service.dart';
import 'auth/landing_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          // Gunakan data dari UserProvider
          final displayName = userProvider.fullName.isNotEmpty
              ? userProvider.fullName
              : firebaseUser?.displayName ?? 'Nama Lengkap';
          final displayEmail = userProvider.email.isNotEmpty
              ? userProvider.email
              : firebaseUser?.email ?? 'email@example.com';
          final profileImage = userProvider.profileImage.isNotEmpty
              ? userProvider.profileImage
              : firebaseUser?.photoURL ?? '';

          return RefreshIndicator(
            onRefresh: () => userProvider.fetchUserData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header - Card dengan lebar penuh
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.blue.shade50,
                                  backgroundImage: profileImage.isNotEmpty
                                      ? NetworkImage(profileImage)
                                      : null,
                                  child: profileImage.isEmpty
                                      ? Icon(
                                    Icons.person,
                                    size: 55,
                                    color: Colors.blue.shade400,
                                  )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _pickAndUploadPhoto(context, userProvider),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1565C0),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayEmail,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Menu Profile - Card dengan lebar penuh
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildProfileMenuItem(
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            iconColor: Colors.blue,
                            onTap: () => _showEditProfileDialog(context, userProvider),
                          ),
                          const Divider(height: 0, indent: 60),
                          _buildProfileMenuItem(
                            icon: Icons.info_outline,
                            title: 'Tentang Aplikasi',
                            iconColor: Colors.purple,
                            onTap: () => _showAboutAppDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Informasi Akun - Card dengan lebar penuh (Data Dinamis dari Firebase)
                  _buildAccountInfoCard(),

                  const SizedBox(height: 20),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogoutDialog(context, userProvider),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text(
                        'Logout',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Widget untuk Informasi Akun dengan data dinamis dari Firebase
  Widget _buildAccountInfoCard() {
    return FutureBuilder<DocumentSnapshot>(
      future: _getUserDataFromFirestore(),
      builder: (context, snapshot) {
        String createdDate = 'Memuat...';
        String status = 'Aktif';
        
        if (snapshot.hasError) {
          createdDate = 'Gagal memuat';
        } else if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('createdAt')) {
            final createdAt = data['createdAt'] as Timestamp?;
            if (createdAt != null) {
              final date = createdAt.toDate();
              createdDate = '${date.day} ${_getMonthName(date.month)} ${date.year}';
            }
          }
          
          // Ambil status dari Firestore jika ada
          if (data != null && data.containsKey('status')) {
            status = data['status'];
          }
        }
        
        return SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Informasi Akun',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Terdaftar sejak', createdDate),
                  const SizedBox(height: 8),
                  _buildInfoRow('Status', status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Fungsi untuk mengambil data user dari Firestore
  Future<DocumentSnapshot> _getUserDataFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
    }
    throw Exception('User not logged in');
  }

  // Fungsi untuk mendapatkan nama bulan dalam Bahasa Indonesia
  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  Future<void> _pickAndUploadPhoto(
      BuildContext context, UserProvider userProvider) async {
    final storageService = StorageService();

    // Pilih sumber foto
    final source = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, false),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Ambil Foto'),
              onTap: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final imageFile = await storageService.pickImage(fromCamera: source);
    if (imageFile == null) return;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengupload foto...')),
    );

    final url = await storageService.uploadProfilePhoto(imageFile);

    if (url != null) {
      await userProvider.updateProfileImage(url);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal upload foto, coba lagi.')),
      );
    }
  }

  void _showEditProfileDialog(BuildContext context, UserProvider userProvider) {
    final nameController = TextEditingController(text: userProvider.fullName);
    final phoneController = TextEditingController(text: userProvider.phone);
    // Hapus emailController - email tidak bisa diubah dari sini

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                hintText: 'Masukkan nama lengkap Anda',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Nomor Telepon',
                hintText: 'Masukkan nomor telepon',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            // Hapus field email karena tidak perlu diupdate
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validasi input
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama lengkap tidak boleh kosong')),
                );
                return;
              }
              
              // Update hanya nama dan phone, email tidak diubah
              await userProvider.updateProfile(
                fullName: nameController.text.trim(),
                phone: phoneController.text.trim(),
                // Hapus parameter email
              );
              
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile berhasil diperbarui')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) async {
    // Get package info
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tentang Aplikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description,
              size: 60,
              color: Color(0xFF1565C0),
            ),
            const SizedBox(height: 16),
            const Text(
              'CV Maker Mahasiswa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versi $version ($buildNumber)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Aplikasi untuk membantu mahasiswa membuat CV profesional dengan mudah dan cepat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Fitur:\n• Pembuatan CV mudah\n• Berbagai template menarik\n• Preview CV sebelum download\n• Simpan dan bagikan CV',
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '© 2025 CV Maker Mahasiswa',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, UserProvider userProvider) {
    final cvProvider = context.read<CVProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      userProvider.reset();
                      cvProvider.resetAll();
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LandingPage()),
                            (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.all(16),
      ),
    );
  }
}