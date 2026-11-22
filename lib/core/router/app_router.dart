import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../Screens/ajustes_screen.dart';
import '../../Screens/clientes_screen.dart';
import '../../Screens/registrar_cliente_screen.dart';
import '../../Screens/dashboard_screen.dart';
import '../../Screens/historial_screen.dart';
import '../../Screens/ordenes_screen.dart';
import '../../Screens/registrar_orden_screen.dart';
import '../../Screens/orden_detalle_screen.dart';
import '../../Screens/repuestos_screen.dart';
import '../../Screens/tecnicos_screen.dart';
import '../../shared/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          MainShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
            path: '/', builder: (context, state) => const DashboardScreen()),
        GoRoute(
            path: '/ordenes',
            builder: (context, state) => const OrdenesScreen()),
        GoRoute(
            path: '/clientes',
            builder: (context, state) => const ClientesScreen()),
        GoRoute(
            path: '/repuestos',
            builder: (context, state) => const RepuestosScreen()),
        GoRoute(
            path: '/ajustes',
            builder: (context, state) => const AjustesScreen()),
      ],
    ),
    GoRoute(
        path: '/clientes/nuevo',
        builder: (context, state) => const RegistrarClienteScreen()),
    GoRoute(
        path: '/ordenes/nueva',
        builder: (context, state) => const RegistrarOrdenScreen()),
    GoRoute(
        path: '/ordenes/:id',
        builder: (context, state) => OrdenDetalleScreen(
            ordenId: int.parse(state.pathParameters['id']!))),
    GoRoute(
        path: '/tecnicos', builder: (context, state) => const TecnicosScreen()),
    GoRoute(
        path: '/historial',
        builder: (context, state) => const HistorialScreen()),
  ],
);
