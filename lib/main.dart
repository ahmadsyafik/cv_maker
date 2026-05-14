import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'state/cv_provider.dart';
import 'providers/user_provider.dart';
import 'pages/home_page.dart';
import 'pages/builder_page.dart';
import 'pages/preview_page.dart';
import 'pages/export_page.dart';
import 'pages/profile_page.dart';
import 'pages/auth/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inisialisasi Firebase dengan error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    // Jika sudah di-initialize, tetap lanjut
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CVProvider()),
      ],
      child: MaterialApp(
        title: 'CV Builder Mahasiswa',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: GoogleFonts.poppins().fontFamily,
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/main': (context) => const MainNavigation(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _hasLoadedData = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Load data hanya sekali setelah login
          if (!_hasLoadedData) {
            _hasLoadedData = true;
            
            // Gunakan WidgetsBinding untuk memastikan context siap
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadUserData();
            });
          }
          
          return const MainNavigation();
        }

        // Reset flag ketika logout
        _hasLoadedData = false;
        return const LandingPage();
      },
    );
  }

  Future<void> _loadUserData() async {
    try {
      final userProvider = context.read<UserProvider>();
      final cvProvider = context.read<CVProvider>();
      
      await Future.wait([
        userProvider.fetchUserData(),
        cvProvider.loadFromFirestore(),
      ]);
      
      print('✅ User and CV data loaded successfully');
    } catch (e) {
      print('❌ Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const BuilderPage(),
    const PreviewPage(),
    const ExportPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          elevation: 4,
          height: 65,
          backgroundColor: Colors.white,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          indicatorColor: Colors.blue.shade100,
          surfaceTintColor: Colors.white,
          shadowColor: Colors.black26,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_outlined),
              selectedIcon: Icon(Icons.edit),
              label: 'Buat CV',
            ),
            NavigationDestination(
              icon: Icon(Icons.preview_outlined),
              selectedIcon: Icon(Icons.preview),
              label: 'Pratinjau',
            ),
            NavigationDestination(
              icon: Icon(Icons.ios_share_outlined),
              selectedIcon: Icon(Icons.ios_share),
              label: 'Ekspor',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}