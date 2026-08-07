import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';

/// A floating, liquid-glass tab dock which retains each GoRouter branch.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;
  void _onTap(int index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: navigationShell,
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFF1C2329).withValues(alpha: .78),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: .14)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 30, offset: const Offset(0, 14))],
            ),
            child: Row(children: List.generate(4, (i) => Expanded(child: _DockItem(
              index: i, selected: navigationShell.currentIndex == i, onTap: () => _onTap(i),
            )))),
          ),
        ),
      ),
    ),
  );
}

class _DockItem extends StatelessWidget {
  const _DockItem({required this.index, required this.selected, required this.onTap});
  final int index; final bool selected; final VoidCallback onTap;
  static const labels = ['Home', 'Upload', 'Meals', 'Profile'];
  static const icons = [Icons.grid_view_rounded, Icons.add_circle_outline_rounded, Icons.restaurant_outlined, Icons.person_outline_rounded];
  static const selectedIcons = [Icons.grid_view_rounded, Icons.add_circle_rounded, Icons.restaurant_rounded, Icons.person_rounded];
  @override Widget build(BuildContext context) => Semantics(
    button: true, selected: selected, label: labels[index],
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 360), curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 11, vertical: 10),
        decoration: BoxDecoration(color: selected ? AppColors.emerald.withValues(alpha: .16) : Colors.transparent, borderRadius: BorderRadius.circular(20), boxShadow: selected ? [BoxShadow(color: AppColors.emerald.withValues(alpha: .16), blurRadius: 14)] : null),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedScale(duration: const Duration(milliseconds: 260), scale: selected ? 1.13 : 1, child: Icon(selected ? selectedIcons[index] : icons[index], color: selected ? AppColors.mint : AppColors.textTertiary, size: 22)),
          AnimatedSize(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic, child: selected ? Padding(padding: const EdgeInsets.only(left: 7), child: Text(labels[index], style: const TextStyle(color: AppColors.mint, fontSize: 11, fontWeight: FontWeight.w800))) : const SizedBox.shrink()),
        ]),
      ),
    )),
  );
}
