import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nunca dejar la pantalla en blanco: si algo falla, mostrar el motivo.
  ErrorWidget.builder = (details) => Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Ocurrió un error:\n${details.exception}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );

  try {
    if (Env.isConfigured) {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
      );
    }
  } catch (e) {
    debugPrint('Supabase no se pudo iniciar: $e');
  }

  runApp(const ProviderScope(child: VitaApp()));
}
