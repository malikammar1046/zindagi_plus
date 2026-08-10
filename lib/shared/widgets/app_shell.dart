import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';

/// A floating, liquid-glass tab dock with a compact layout for narrow screens.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2329).withValues(alpha: .78),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: .14)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .35),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(
                    5,
                    (index) => Expanded(
                      child: _DockItem(
                        index: index,
                        selected: navigationShell.currentIndex == index,
                        onTap: () => _onTap(index),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final VoidCallback onTap;

  static const labels = ['Home', 'Upload', 'Meals', 'AI', 'Profile'];
  static const icons = [
    Icons.grid_view_rounded,
    Icons.add_circle_outline_rounded,
    Icons.restaurant_outlined,
    Icons.auto_awesome_outlined,
    Icons.person_outline_rounded,
  ];
  static const selectedIcons = [
    Icons.grid_view_rounded,
    Icons.add_circle_rounded,
    Icons.restaurant_rounded,
    Icons.auto_awesome_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: labels[index],
        child: GestureDetector(
          onTapDown: (_) => onTap(),
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: 42,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              AppColors.emerald.withValues(alpha: .42),
                              AppColors.emerald.withValues(alpha: .16),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(15),
                    border: selected
                        ? Border.all(
                            color: AppColors.mint.withValues(alpha: .32),
                          )
                        : null,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.emerald.withValues(alpha: .24),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    scale: selected ? 1.08 : 1,
                    child: Icon(
                      selected ? selectedIcons[index] : icons[index],
                      color: selected ? AppColors.mint : AppColors.textTertiary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: selected ? AppColors.mint : AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: selected ? .1 : 0,
                  ),
                  child: Text(
                    labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
