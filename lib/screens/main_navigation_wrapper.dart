import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'izin_guru_screen.dart';
import 'profile_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  static MainNavigationWrapperState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainNavigationWrapperState>();

  @override
  State<MainNavigationWrapper> createState() => MainNavigationWrapperState();
}

class MainNavigationWrapperState extends State<MainNavigationWrapper>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  late final AnimationController _navCtrl;

  @override
  void initState() {
    super.initState();
    _navCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  set currentIndex(int index) => setState(() => _currentIndex = index);

  @override
  void dispose() {
    _navCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isGuru = auth.role.toLowerCase() == 'guru';

    final List<Widget> screens = [
      const DashboardScreen(),
      if (isGuru) const IzinGuruScreen(),
      const ProfileScreen(),
    ];

    final List<_NavItem> navItems = [
      _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
      if (isGuru) _NavItem(icon: Icons.edit_document, label: 'Izin'),
      _NavItem(icon: Icons.person_rounded, label: 'Profil'),
    ];

    return Scaffold(
      backgroundColor: T.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.03), end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: _AnimatedNavBar(
        items: navItems,
        selectedIndex: _currentIndex,
        onTap: (i) {
          HapticFeedback.selectionClick();
          if (i != _currentIndex) {
            setState(() => _currentIndex = i);
          }
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _AnimatedNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _AnimatedNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: T.card,
        border: Border(top: BorderSide(color: T.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == selectedIndex;
              return _NavButton(
                item: items[i],
                selected: selected,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton(
      {required this.item, required this.selected, required this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.selected ? 22 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: widget.selected ? T.ink : Colors.transparent,
            borderRadius: T.r99,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.item.icon,
                size: 22,
                color: widget.selected ? Colors.white : T.muted,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: widget.selected
                    ? Row(children: [
                        const SizedBox(width: 7),
                        Text(
                          widget.item.label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
