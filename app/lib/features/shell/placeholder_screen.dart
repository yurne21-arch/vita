import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty,
                  size: 40, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
              const Text('Próximamente'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Cimientos (Sprint 0). Esta sección aún no se construye.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
