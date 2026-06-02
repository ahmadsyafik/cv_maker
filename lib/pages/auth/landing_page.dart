import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cv_maker/pages/auth/login_page.dart';
import 'package:cv_maker/pages/auth/register_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setSystemUI();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setSystemUI();
    }
  }

  void _setSystemUI() {
    // Gunakan edge-to-edge agar konten bisa sampai ke tepi,
    // tapi tetap memperhatikan cutout dan gesture navigation
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        // Untuk Android, ini akan membuat navigation bar transparan
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  void dispose() {
    // Kembalikan ke mode default saat halaman ditutup
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: null, // Kembali ke default
      statusBarColor: null,
    ));
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Ini penting untuk menghindari tumpang tindih dengan system UI
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background SVG
          SvgPicture.asset(
            'assets/background/background.svg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            placeholderBuilder: (context) => Container(
              color: const Color(0xFF2578AD),
            ),
          ),

          // Overlay gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),

          // Content dengan SafeArea yang lebih cerdas
          SafeArea(
            // Hanya bottom yang false, top tetap true agar tidak tumpang tindih status bar
            bottom: false,
            // Tambahkan minimum padding untuk bottom
            child: Column(
              children: [
                // Spacer fleksibel untuk teks di tengah
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Selamat Datang!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Buat CV profesional Anda dalam hitungan menit',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Isi detail Anda dan buat CV Anda secara instan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.white70,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tombol-tombol dengan padding untuk gesture navigation
                Padding(
                  // Padding bottom untuk menghindari gesture navigation bar
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: SizedBox(
                    height: 90,
                    child: Padding(
                      // Padding horizontal agar tidak terlalu pinggir
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tombol DAFTAR
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              ),
                              child: Container(
                                alignment: Alignment.topCenter,
                                padding: const EdgeInsets.only(top: 38),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF285EA4)
                                      .withValues(alpha: 0.2),
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(50),
                                  ),
                                ),
                                child: const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Tombol MASUK
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              ),
                              child: Container(
                                alignment: Alignment.topCenter,
                                padding: const EdgeInsets.only(top: 38),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(50),
                                  ),
                                ),
                                child: const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color.fromARGB(255, 12, 53, 106),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}