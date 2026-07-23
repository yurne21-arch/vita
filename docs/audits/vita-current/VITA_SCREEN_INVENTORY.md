# VITA — Inventario de pantallas (mapa visual)

Rutas, capturas, estados, overlays y flujos observados. Capturas en `screenshots/`.
Build: `main@9b8b58a` · datos sintéticos (usuario de auditoría temporal).

## Rutas (router)

Fuente: `core/router/app_router.dart` · shell `core/widgets/app_shell.dart`.

| # | Ruta | Pantalla | Archivo | En nav | Capturas |
|---|---|---|---|---|---|
| 1 | `/login` | LoginScreen | `features/auth/presentation/login_screen.dart` | no | `states/login__desktop__default.png`, `states/login__mobile__default.png` |
| 2 | `/mi-vida` | MiVidaScreen | `features/mi_vida/presentation/mi_vida_screen.dart` | Tab 1 | desktop/tablet/mobile (default+scroll) + `states/mi-vida__w320`, `w1920` |
| 3 | `/proyectos` | ProyectosScreen | `features/proyectos/presentation/proyectos_screen.dart` | Tab 2 | desktop/tablet/mobile (default+scroll) |
| 4 | `/mi-mes` | MiMesScreen | `features/mi_mes/presentation/mi_mes_screen.dart` | Tab 3 | desktop/tablet/mobile (default+scroll) |
| 5 | `/calendario` | CalendarioScreen | `features/agenda/presentation/calendario_screen.dart` | Tab 4 | desktop/tablet/mobile (default) |
| 6 | `/finanzas` | FinanzasScreen | `features/finanzas/presentation/finanzas_screen.dart` | Tab 5 | desktop/tablet/mobile (default+scroll) + `states/finanzas__w320`, `w1920` |
| 7 | `/ajustes` | AjustesScreen | `features/ajustes/presentation/ajustes_screen.dart` | Tab 6 | desktop/tablet/mobile (default) |

**Push (no ruta):** `ProyectoDetalleScreen` (detalle de proyecto) se abre por `Navigator.push` desde Proyectos y Mi Vida — auditado por código (no capturado en navegador; requiere abrir un proyecto).

## Overlays (diálogos y hojas inferiores)

Auditados por **código** (interacción canvas no automatizada en esta pasada). Fuente: inventario de código.

**Hojas inferiores (bottom sheets):** registrar estado (Mi Vida), administrar hábitos (Mi Vida), editor de evento (Agenda), hoja del día (Agenda), menú gasto/ingreso (Finanzas), ver pagos de crédito (Finanzas), editores de movimiento/deuda/presupuesto/tarjeta/crédito/meta/cuenta (Finanzas), editor de proyecto/tarea/bitácora (Proyectos).

**Diálogos:** prioridad (Mi Vida), hábito (Mi Vida), editar nombre (Ajustes), confirmar salir (Ajustes), eliminar proyecto (Proyectos), confirmar genérico (detalle Proyecto), saldar Tricount (Finanzas), cerrar mes (Finanzas), pedir monto+fecha / pago tarjeta (Finanzas).

**Pickers:** `showDatePicker` (Proyectos, Finanzas, Agenda), `showTimePicker` (Agenda) — estilo Material estándar.

## Estados por pantalla (implementados en código; los observados en navegador se marcan 👁)

| Pantalla | default | loading | vacío | error | datos | guardando |
|---|---|---|---|---|---|---|
| Login | 👁 | ✅(botón) | — | ✅(snackbar) | — | ✅ |
| Mi Vida | 👁 | ✅ | ✅ (por tarjeta) | ✅ ErrorEnTarjeta | 👁 | ✅ |
| Proyectos | 👁 | ✅ | ✅ (hero vacío 👁, `_VacioActivos`) | ⚠️ sin reintentar | 👁 | ✅ |
| Mi Mes | 👁 | ✅ | ✅ `_EspejoVacio` | ✅ ErrorEnTarjeta | 👁 | ✅ |
| Calendario | 👁 | ✅ | ✅ `_VacioDia` 👁 | ⚠️ sin reintentar | 👁 (parcial) | ✅ |
| Finanzas | 👁 | ✅ | ✅ `_Vacio` (SALDOS 👁) | ✅ ErrorEnTarjeta | 👁 | ✅ |
| Ajustes | 👁 | ✅ | n/a | ✅ ErrorEnTarjeta | 👁 | ✅ |

Estados NO verificados empíricamente (requieren provocar la condición): error de red real, offline, sincronización pendiente, permisos, lista muy larga, texto muy largo. La app no tiene offline real (Drift desactivado, MASTER §12).

## Flujos principales (observados / por código)

- **Login → Mi Vida:** 👁 verificado (correo+contraseña → redirección `/mi-vida`).
- **Navegación entre 6 pestañas:** 👁 fluida, conserva estado por `IndexedStack`.
- **Crear/editar/completar** prioridades, hábitos, estado, eventos, movimientos, proyectos, pasos, metas: por código (overlays), no automatizados en navegador.
- **Cerrar mes / cartola PDF / Tricount / recordatorios .ics:** por código.

## Pantallas faltantes / inaccesibles / enlaces rotos

- **Faltante por roadmap:** módulo **Salud** propio (hoy dentro de Mi Vida); **Motor de IA** (puerto vacío).
- **Inaccesible:** ninguna ruta rota; todas cargan.
- **Enlaces rotos:** ninguno (0 requests fallidas).
- **Defecto de render:** hero de Proyectos (VITA-001) — no es enlace roto, es contenido que no pinta.

## Consola y red

`screenshots/../console-and-network.json` — **0 errores de consola y 0 requests fallidas** en las 7 rutas × 3 breakpoints.
