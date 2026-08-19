import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A standard, high-contrast back button matching Zindagi+'s emerald visual theme.
///
/// Pops the current route from the navigation stack if possible ([context.canPop]).
/// If popped from an isolated entry (such as a notification or deep link without history),
/// it navigates safely to [fallbackLocation].
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.fallbackLocation,
    this.onPressed,
    this.color,
  });

  /// Optional route to navigate to if the navigation stack has no previous route to pop.
  final String? fallbackLocation;

  /// Optional custom callback to override standard back action.
  final VoidCallback? onPressed;

  /// Custom icon color (defaults to theme's primary emerald color).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.primary;

    return IconButton(
      icon: const Icon(Icons.arrow_back),
      color: iconColor,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else if (context.canPop()) {
          context.pop();
        } else if (fallbackLocation != null) {
          context.go(fallbackLocation!);
        } else {
          context.go('/dashboard');
        }
      },
    );
  }
}
