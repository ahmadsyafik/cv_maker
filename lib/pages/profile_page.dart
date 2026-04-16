import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: profileImage.isNotEmpty
                                  ? NetworkImage("${profileImage}&t=${DateTime.now().millisecondsSinceEpoch}")
                                  : null,
                              child: profileImage.isEmpty
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
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
                                  onPressed: () =>
                                      _pickAndUploadPhoto(context, userProvider),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayEmail,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Profile Menu
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildProfileMenuItem(
                        icon: Icons.person_outline,
                        title: 'Edit Profil',
                        onTap: () => _showEditProfileDialog(context, userProvider),
                      ),
                      const Divider(height: 0),
                      _buildProfileMenuItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifikasi',
                        trailing: Switch(
                          value: true,
                          onChanged: (value) {},
                          activeThumbColor: Colors.blue,
                        ),
                        onTap: () {},
                      ),
                      const Divider(height: 0),
                      _buildProfileMenuItem(
                        icon: Icons.lock_outline,
                        title: 'Privasi & Keamanan',
                        onTap: () {},
                      ),
                      const Divider(height: 0),
                      _buildProfileMenuItem(
                        icon: Icons.help_outline,
                        title: 'Bantuan',
                        onTap: () {},
                      ),
                      const Divider(height: 0),
                      _buildProfileMenuItem(
                        icon: Icons.info_outline,
                        title: 'Tentang Aplikasi',
                        onTap: () => _showAboutDialog(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, userProvider),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(
      BuildContext context, UserProvider userProvider) async {
    final storageService = StorageService();

    // Pilih sumber foto
    final source = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Pilih dari Galeri'),
            onTap: () => Navigator.pop(context, false),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Ambil Foto'),
            onTap: () => Navigator.pop(context, true),
          ),
        ],
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

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProvider userProvider) {
    final nameController = TextEditingController(text: userProvider.fullName);
    final emailController = TextEditingController(text: userProvider.email);
    final phoneController = TextEditingController(text: userProvider.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await userProvider.updateProfile(
                fullName: nameController.text,
                email: emailController.text,
                phone: phoneController.text,
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil berhasil diperbarui')),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengaturan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Bahasa'),
              trailing: const Text('Indonesia'),
              onTap: () {},
            ),
            ListTile(
              title: const Text('Ukuran Font'),
              trailing: DropdownButton<String>(
                value: 'Medium',
                items: const [
                  DropdownMenuItem(value: 'Kecil', child: Text('Kecil')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'Besar', child: Text('Besar')),
                ],
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'CV Builder Mahasiswa',
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(size: 50),
      applicationLegalese: '© 2024 CV Builder Mahasiswa',
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Aplikasi untuk membantu mahasiswa membuat CV profesional dengan mudah.',
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, UserProvider userProvider) {
    final cvProvider = context.read<CVProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              userProvider.reset();  // Reset UserProvider
              cvProvider.resetAll(); // Reset CVProvider
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
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}