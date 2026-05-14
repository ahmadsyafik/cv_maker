import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../state/cv_provider.dart';
import '../providers/user_provider.dart';
import '../services/storage_service.dart';
import 'auth/landing_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
          final firebaseUser = FirebaseAuth.instance.currentUser;
          
          if (firebaseUser == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                  (route) => false,
                );
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          final displayName = userProvider.fullName.isNotEmpty
              ? userProvider.fullName
              : firebaseUser.displayName ?? 'Nama Lengkap';
          final displayEmail = userProvider.email.isNotEmpty
              ? userProvider.email
              : firebaseUser.email ?? 'email@example.com';
          final profileImage = userProvider.profileImage.isNotEmpty
              ? userProvider.profileImage
              : firebaseUser.photoURL ?? '';

          return RefreshIndicator(
            onRefresh: () => userProvider.fetchUserData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                                _buildProfileImage(profileImage),
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
                            icon: Icons.lock_outline,
                            title: 'Ganti Password',
                            iconColor: Colors.orange,
                            onTap: () => _showChangePasswordDialog(context),
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
                  _buildAccountInfoCard(firebaseUser.uid),
                  const SizedBox(height: 20),
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

  Widget _buildProfileImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: 55,
        backgroundColor: Colors.blue.shade50,
        child: Icon(
          Icons.person,
          size: 55,
          color: Colors.blue.shade400,
        ),
      );
    }

    return CircleAvatar(
      radius: 55,
      backgroundColor: Colors.blue.shade50,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: 110,
          height: 110,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
            ),
          ),
          errorWidget: (context, url, error) => Icon(
            Icons.person,
            size: 55,
            color: Colors.blue.shade400,
          ),
          cacheKey: imageUrl,
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
      ),
    );
  }

  Widget _buildAccountInfoCard(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String createdDate = 'Tidak tersedia';
        String status = 'Aktif';
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('createdAt')) {
            final createdAt = data['createdAt'] as Timestamp?;
            if (createdAt != null) {
              final date = createdAt.toDate();
              createdDate = '${date.day} ${_getMonthName(date.month)} ${date.year}';
            }
          }
          
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
                  _buildInfoRow('Status', status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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

    if (context.mounted) { 
      showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Material(
          color: Colors.transparent,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
          ),
        ),
      ),
    );
    }

    try {
      final imageFile = await storageService.pickImage(fromCamera: source);
      
      if (imageFile == null) {
        if (context.mounted) Navigator.pop(context);
        return;
      }

      final url = await storageService.uploadProfilePhoto(imageFile);

      if (context.mounted) Navigator.pop(context);

      if (url != null) {
        await userProvider.updateProfileImage(url);
        await CachedNetworkImage.evictFromCache(url);
        
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        
        await userProvider.fetchUserData();
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal upload foto, coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== TASK #6: GANTI PASSWORD DENGAN KONFIRMASI ====================
  // ==================== TASK #6: GANTI PASSWORD DENGAN KONFIRMASI ====================
void _showChangePasswordDialog(BuildContext context) {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final currentPasswordFocusNode = FocusNode();
  final newPasswordFocusNode = FocusNode();
  final confirmPasswordFocusNode = FocusNode();
  
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;
  bool _isLoading = false;
  
  // Error messages untuk masing-masing field
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  
  showDialog(
    context: context,
    barrierDismissible: !_isLoading,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        // Auto focus ke field yang bermasalah
        if (_currentPasswordError != null && !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FocusScope.of(context).requestFocus(currentPasswordFocusNode);
          });
        } else if (_newPasswordError != null && !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FocusScope.of(context).requestFocus(newPasswordFocusNode);
          });
        } else if (_confirmPasswordError != null && !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FocusScope.of(context).requestFocus(confirmPasswordFocusNode);
          });
        }
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ganti Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Password Saat Ini
                TextField(
                  controller: currentPasswordController,
                  focusNode: currentPasswordFocusNode,
                  obscureText: obscureCurrent,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password Saat Ini',
                    hintText: 'Masukkan password lama',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _currentPasswordError,
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                  onChanged: (_) {
                    if (_currentPasswordError != null) {
                      setDialogState(() => _currentPasswordError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Password Baru
                TextField(
                  controller: newPasswordController,
                  focusNode: newPasswordFocusNode,
                  obscureText: obscureNew,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    hintText: 'Minimal 6 karakter',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _newPasswordError,
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                  onChanged: (_) {
                    if (_newPasswordError != null) {
                      setDialogState(() => _newPasswordError = null);
                    }
                    // Juga reset confirm password error jika ada
                    if (_confirmPasswordError != null) {
                      setDialogState(() => _confirmPasswordError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Konfirmasi Password Baru
                TextField(
                  controller: confirmPasswordController,
                  focusNode: confirmPasswordFocusNode,
                  obscureText: obscureConfirm,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    hintText: 'Masukkan ulang password baru',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _confirmPasswordError,
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  onChanged: (_) {
                    if (_confirmPasswordError != null) {
                      setDialogState(() => _confirmPasswordError = null);
                    }
                  },
                ),
                
                const SizedBox(height: 8),
                Text(
                  'Password minimal 6 karakter dan harus sama dengan konfirmasi',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                // Reset semua error
                setDialogState(() {
                  _currentPasswordError = null;
                  _newPasswordError = null;
                  _confirmPasswordError = null;
                });
                
                final currentPassword = currentPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();
                
                bool hasError = false;
                
                // Validasi current password
                if (currentPassword.isEmpty) {
                  setDialogState(() => _currentPasswordError = 'Password saat ini tidak boleh kosong');
                  hasError = true;
                }
                
                // Validasi password baru
                if (newPassword.isEmpty) {
                  setDialogState(() => _newPasswordError = 'Password baru tidak boleh kosong');
                  hasError = true;
                } else if (newPassword.length < 6) {
                  setDialogState(() => _newPasswordError = 'Password baru minimal 6 karakter');
                  hasError = true;
                }
                
                // Validasi konfirmasi password (TASK #6 - tampil di dalam card)
                if (confirmPassword.isEmpty) {
                  setDialogState(() => _confirmPasswordError = 'Konfirmasi password tidak boleh kosong');
                  hasError = true;
                } else if (newPassword.isNotEmpty && newPassword != confirmPassword) {
                  setDialogState(() => _confirmPasswordError = 'Konfirmasi password tidak cocok');
                  hasError = true;
                }
                
                // Validasi password baru tidak sama dengan lama
                if (!hasError && currentPassword.isNotEmpty && newPassword.isNotEmpty && currentPassword == newPassword) {
                  setDialogState(() => _newPasswordError = 'Password baru harus berbeda dengan password lama');
                  hasError = true;
                }
                
                if (hasError) return;
                
                // Rate limit - disable tombol
                setDialogState(() => _isLoading = true);
                
                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  
                  // Re-autentikasi dengan password lama
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPassword,
                  );
                  await user.reauthenticateWithCredential(cred);
                  
                  // Update password
                  await user.updatePassword(newPassword);
                  
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Password berhasil diperbarui!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                } on FirebaseAuthException catch (e) {
                  setDialogState(() => _isLoading = false);
                  
                  // Handle error dari Firebase - tampilkan di field yang sesuai
                  switch (e.code) {
                    case 'wrong-password':
                      setDialogState(() => _currentPasswordError = '❌ Password saat ini salah');
                      currentPasswordController.clear();
                      break;
                      
                    case 'invalid-credential':
                      setDialogState(() => _currentPasswordError = '❌ Password saat ini tidak valid');
                      currentPasswordController.clear();
                      break;
                      
                    case 'weak-password':
                      setDialogState(() => _newPasswordError = 'Password terlalu lemah. Gunakan kombinasi yang lebih kuat');
                      break;
                      
                    case 'requires-recent-login':
                      // Ini tetap pakai SnackBar karena butuh aksi logout
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('🔐 Untuk keamanan, silakan logout dan login kembali untuk mengganti password'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 4),
                        ),
                      );
                      break;
                      
                    case 'network-request-failed':
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('📡 Koneksi internet bermasalah. Periksa koneksi Anda.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      break;
                      
                    default:
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Terjadi kesalahan: ${e.message ?? "Silakan coba lagi"}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                  }
                  
                  if (!dialogContext.mounted) return;
                  
                } catch (e) {
                  setDialogState(() => _isLoading = false);
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Terjadi kesalahan: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan'),
            ),
          ],
        );
      },
    ),
  );
}

  // ==================== EDIT PROFILE DIALOG ====================
  void _showEditProfileDialog(BuildContext context, UserProvider userProvider) {
    final nameController = TextEditingController(text: userProvider.fullName);
    bool _isLoading = false;
    
    showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Masukkan nama lengkap',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ganti password? Buka menu "Ganti Password"',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setDialogState(() => _isLoading = true);
                
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  setDialogState(() => _isLoading = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Nama lengkap tidak boleh kosong'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                try {
                  await userProvider.updateProfile(fullName: newName);
                  
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  setDialogState(() => _isLoading = false);
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    if(!context.mounted) return;
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout, color: Colors.red.shade600, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Konfirmasi Logout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await FirebaseAuth.instance.signOut();
                userProvider.reset();
                cvProvider.resetAll();
                await CachedNetworkImage.evictFromCache('*');
                
                if (!context.mounted) return;
                
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                  (route) => false,
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}