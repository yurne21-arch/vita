import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Traduce cualquier error a algo que una persona pueda leer.
///
/// Los repositorios ya lanzan excepciones de dominio con mensajes escritos para
/// la usuaria (incluido el del trigger 'Máximo 3 prioridades por día'). Lo que
/// nunca debe llegar a pantalla es un `PostgrestException(...)` crudo.
String mensajeDeError(Object error) {
  final texto = error.toString().trim();
  if (texto.isEmpty) return 'Algo salió mal. Inténtalo de nuevo.';

  // Las excepciones de dominio ya traen un mensaje limpio: su toString() es el
  // mensaje. Las de infraestructura traen ruido técnico: se descartan.
  final pareceTecnico = texto.contains('Exception:') ||
      texto.contains('Error:') ||
      texto.contains('statusCode') ||
      texto.startsWith('type ') ||
      texto.contains('_TypeError');
  if (pareceTecnico) {
    return 'No pudimos completar la acción. Revisa tu internet e inténtalo de nuevo.';
  }
  return texto;
}

/// Ejecuta una acción y, si falla, se lo dice a la usuaria.
///
/// Toda escritura pasa por aquí. Una acción que falla en silencio —el check que
/// se desmarca solo, el diálogo que se cierra sin guardar— es peor que un error
/// visible: enseña a desconfiar de la app.
Future<void> accionSegura(
  BuildContext context,
  Future<void> Function() accion,
) async {
  try {
    await accion();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensajeDeError(e))),
    );
  }
}

/// Estado de error dentro de una tarjeta, con opción de reintentar.
///
/// Existe para que un fallo de red no se disfrace de "no tienes nada": decirle
/// a la usuaria que no tiene prioridades cuando en realidad falló la carga es
/// mentirle.
class ErrorEnTarjeta extends StatelessWidget {
  const ErrorEnTarjeta({
    required this.mensaje,
    required this.onReintentar,
    super.key,
  });

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                mensaje,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }
}
