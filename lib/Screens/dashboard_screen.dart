import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../ViewModels/app_providers.dart';
import '../ViewModels/dashboard_view_model.dart';
import '../shared/widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordenesAbiertasProvider);
    final parts = ref.watch(repuestosProvider);
    final clients = ref.watch(clientesProvider);
    final technicians = ref.watch(tecnicosProvider);
    final dashboardViewModel = ref.watch(dashboardViewModelProvider);
    return RefreshIndicator(
        onRefresh: () async {
          ref.read(dashboardViewModelProvider).actualizarResumen();
        },
        child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
          PageHeader(
              title: 'Tu Solution',
              subtitle: 'Panel de control del taller',
              action: IconButton(
                  onPressed: () => context.push('/ajustes'),
                  icon: const Icon(Icons.settings_outlined))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF1769E0), Color(0xFF398FEA)]),
                      borderRadius: BorderRadius.circular(22)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GESTIÓN DEL TALLER',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        const Text('Todo bajo control.',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        const Text(
                            'Consulta las reparaciones y el inventario de hoy.',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 18),
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1769E0)),
                                onPressed: () => context.push('/ordenes/nueva'),
                                icon: const Icon(Icons.add),
                                label: const Text('Registrar reparación'))),
                      ]))),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('Resumen',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _MetricCard(
                        title: 'Órdenes abiertas',
                        icon: Icons.assignment_outlined,
                        value: orders.when(
                            data: (v) => '${v.length}',
                            error: (_, __) => '—',
                            loading: () => '…')),
                    _MetricCard(
                        title: 'Clientes',
                        icon: Icons.people_outline,
                        value: clients.when(
                            data: (v) => '${v.length}',
                            error: (_, __) => '—',
                            loading: () => '…')),
                    _MetricCard(
                        title: 'Técnicos',
                        icon: Icons.engineering_outlined,
                        value: technicians.when(
                            data: (v) => '${v.length}',
                            error: (_, __) => '—',
                            loading: () => '…')),
                    _MetricCard(
                        title: 'Stock bajo',
                        icon: Icons.warning_amber_outlined,
                        value: parts.when(
                            data: (v) =>
                                '${dashboardViewModel.contarRepuestosConStockBajo(v)}',
                            error: (_, __) => '—',
                            loading: () => '…')),
                  ])),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(children: [
                Expanded(
                    child: Text('Accesos rápidos',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold))),
                TextButton(
                    onPressed: () => context.push('/tecnicos'),
                    child: const Text('Técnicos'))
              ])),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                    child: _QuickAction(
                        icon: Icons.history,
                        label: 'Historial',
                        onTap: () => context.push('/historial'))),
                const SizedBox(width: 10),
                Expanded(
                    child: _QuickAction(
                        icon: Icons.engineering,
                        label: 'Técnicos',
                        onTap: () => context.push('/tecnicos')))
              ])),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(children: [
                Expanded(
                    child: Text('Órdenes recientes',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold))),
                TextButton(
                    onPressed: () => context.go('/ordenes'),
                    child: const Text('Ver todas'))
              ])),
          orders.when(
              data: (items) => items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: EmptyState(
                          icon: Icons.task_alt,
                          title: 'Todo al día',
                          message: 'No hay órdenes abiertas.'))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                          children: items
                              .take(3)
                              .map((item) => Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                      leading: const CircleAvatar(
                                          child: Icon(Icons.devices)),
                                      title: Text(
                                          '${item.dispositivo.marca} ${item.dispositivo.modelo}'),
                                      subtitle: Text(
                                          '${item.cliente.nombre} · ${item.tecnico.nombre}'),
                                      trailing: StatusChip(
                                          status: item.orden.estado))))
                              .toList())),
              error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20), child: Text('Error: $e')),
              loading: () => const Center(
                  child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))),
        ]));
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.title, required this.icon, required this.value});
  final String title;
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor))
              ])));
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
      child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(label,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                const Icon(Icons.chevron_right)
              ]))));
}
