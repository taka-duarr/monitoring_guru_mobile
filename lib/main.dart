import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Gagal memuat file .env: $e");
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const AbsensiApp(),
    ),
  );
}

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: const Color(0xFF4F46E5),
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
  cardColor: Colors.white,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF4F46E5),
    brightness: Brightness.light,
    surface: Colors.white,
    onSurface: const Color(0xFF0F172A),
  ),
  textTheme: GoogleFonts.interTextTheme().copyWith(
    titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
    bodyMedium: GoogleFonts.inter(color: const Color(0xFF334155)),
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF6366F1),
  scaffoldBackgroundColor: const Color(0xFF0F172A),
  cardColor: const Color(0xFF1E293B),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF4F46E5),
    brightness: Brightness.dark,
    surface: const Color(0xFF1E293B),
    onSurface: const Color(0xFFF1F5F9),
  ),
  textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
    titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFF1F5F9)),
    bodyMedium: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
  ),
);

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi Guru',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Secara simpel arahkan berdasarkan status login
          if (auth.isAuthenticated) {
            return const MainNavigationWrapper();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
