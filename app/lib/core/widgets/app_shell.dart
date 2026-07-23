import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurfaceVariant;
    // En pantallas muy angostas (≤360) las 6 etiquetas se parten a mitad de
    // palabra ("Proyecto s"): bajamos el tamaño para que quepan en una línea.
    final ancho = MediaQuery.sizeOf(context).width;
    final tamEtiqueta = ancho <= 360 ? 9.0 : 12.0;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        // Estilo propio, sin la "píldora" Material: el estado activo se
        // comunica con el ícono relleno y el acento.
        data: NavigationBarThemeData(
          indicatorColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final activo = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: tamEtiqueta,
              height: 1.05,
              fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
              color: activo ? AppColors.accent : muted,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final activo = states.contains(WidgetState.selected);
            return IconThemeData(
                size: 24, color: activo ? AppColors.accent : muted);
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          // Solo pestañas que llevan a algo real. Una pestaña que dice
          // "próximamente" ocupa un quinto de la navegación para no hacer nada.
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny),
              label: 'Mi Vida',
            ),
            NavigationDestination(
              icon: Icon(Icons.flag_outlined),
              selectedIcon: Icon(Icons.flag),
              label: 'Proyectos',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Mi Mes',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Calendario',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Finanzas',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
