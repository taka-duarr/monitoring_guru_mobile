import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'izin_guru_screen.dart';
import 'profile_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  static MainNavigationWrapperState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationWrapperState>();
  }

  @override
  State<MainNavigationWrapper> createState() => MainNavigationWrapperState();
}

class MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  set currentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isGuru = auth.role.toLowerCase() == 'guru';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      const DashboardScreen(),
      if (isGuru) const IzinGuruScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.blueGrey.shade100)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BottomMenuItem(
                  label: 'Jadwal',
                  icon: Icons.home_outlined,
                  selected: _currentIndex == 0,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentIndex = 0);
                  },
                ),
                if (isGuru)
                  _BottomMenuItem(
                    label: 'Izin',
                    icon: Icons.description_outlined,
                    selected: _currentIndex == 1,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _currentIndex = 1);
                    },
                  ),
                _BottomMenuItem(
                  label: 'Profil',
                  icon: Icons.person_outline,
                  selected: isGuru ? _currentIndex == 2 : _currentIndex == 1,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentIndex = isGuru ? 2 : 1);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomMenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _BottomMenuItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (isDark ? const Color(0xFF818CF8) : Colors.indigo.shade700)
        : (isDark ? const Color(0xFF64748B) : Colors.blueGrey.shade400);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
