import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // En pantallas muy angostas (≤360) las 6 etiquetas se parten a mitad de
    // palabra ("Proyecto s"). Reducimos el tamaño de la etiqueta para que
    // quepan en una sola línea, sin renombrar módulos ni ocultar etiquetas.
    final ancho = MediaQuery.sizeOf(context).width;
    final estiloEtiqueta = ancho <= 360
        ? const TextStyle(
            fontSize: 9, fontWeight: FontWeight.w500, height: 1.05)
        : null;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: estiloEtiqueta == null
              ? null
              : WidgetStatePropertyAll(estiloEtiqueta),
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
