import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.background,
      gradient: RadialGradient(colors: [Color(0xFF173D37), AppColors.background], center: Alignment(-.9, -1.1), radius: 1.25),
    ),
    child: Stack(children: [
      const Positioned(right: -90, top: 150, child: _Glow(color: AppColors.blue)),
      const Positioned(left: -120, bottom: 80, child: _Glow(color: AppColors.emerald)),
      child,
    ]),
  );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color}); final Color color;
  @override Widget build(BuildContext context) => IgnorePointer(child: Container(width: 240, height: 240, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: .075), boxShadow: [BoxShadow(color: color.withValues(alpha: .16), blurRadius: 100, spreadRadius: 35)])));
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.radius = 28, this.gradient, this.onTap});
  final Widget child; final EdgeInsetsGeometry padding; final double radius; final Gradient? gradient; final VoidCallback? onTap;
  @override Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Material(color: Colors.transparent, child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient ?? LinearGradient(colors: [Colors.white.withValues(alpha: .105), Colors.white.withValues(alpha: .045)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: .14)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .22), blurRadius: 28, offset: const Offset(0, 14))],
          ), child: child,
        ),
      )),
    ),
  );
}

class PremiumButton extends StatefulWidget {
  const PremiumButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon});
  final String label; final VoidCallback? onPressed; final bool loading; final IconData? icon;
  @override State<PremiumButton> createState() => _PremiumButtonState();
}
class _PremiumButtonState extends State<PremiumButton> {
  var pressed = false;
  @override Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.onPressed == null ? null : (_) => setState(() => pressed = true),
    onTapUp: (_) => setState(() => pressed = false), onTapCancel: () => setState(() => pressed = false), onTap: widget.onPressed,
    child: AnimatedScale(duration: const Duration(milliseconds: 140), scale: pressed ? .97 : 1, child: Container(
      height: 56, alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [AppColors.emerald, Color(0xFF238F87)]), boxShadow: [BoxShadow(color: AppColors.emerald.withValues(alpha: .28), blurRadius: 22, offset: const Offset(0, 10))]),
      child: widget.loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background)) : Row(mainAxisSize: MainAxisSize.min, children: [if (widget.icon != null) ...[Icon(widget.icon, color: AppColors.background, size: 19), const SizedBox(width: 9)], Text(widget.label, style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.w800))]),
    )),
  );
}
