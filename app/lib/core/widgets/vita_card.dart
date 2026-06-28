import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Tarjeta base de VITA: superficie limpia, sin sombras duras, mucho aire.
class VitaCard extends StatelessWidget {
  const VitaCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}
