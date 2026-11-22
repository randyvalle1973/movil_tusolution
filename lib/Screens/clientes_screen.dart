import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/database/app_database.dart';
import '../ViewModels/app_providers.dart';
import '../ViewModels/clientes_view_model.dart';
import '../shared/widgets.dart';

class ClientesScreen extends ConsumerWidget {
  const ClientesScreen({super.key});

  Future<void> _mostrarHistorialDispositivo(
    BuildContext context,
    dynamic dispositivo,
    List<OrdenResumen> todasLasOrdenes,
  ) async {
    final ordenes = todasLasOrdenes
        .where((item) => item.dispositivo.id == dispositivo.id)
        .toList()
      ..sort(
        (a, b) => b.orden.fechaRecepcion.compareTo(a.orden.fechaRecepcion),
      );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          child: Icon(
                            Icons.devices_outlined,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dispositivo.marca} ${dispositivo.modelo}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(dispositivo.tipo),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (dispositivo.numeroSerie?.isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Número de serie: ${dispositivo.numeroSerie}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.history,
                            label: 'Reparaciones',
                            value: '${ordenes.length}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.build_outlined,
                            label: 'Abiertas',
                            value:
                                '${ordenes.where((item) => item.orden.estado != 'entregada' && item.orden.estado != 'cancelada').length}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Text(
                  'Historial de este dispositivo',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ordenes.isEmpty
                    ? const EmptyState(
                        icon: Icons.history,
                        title: 'Sin reparaciones',
                        message:
                            'Este dispositivo todavía no tiene órdenes de reparación.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: ordenes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final item = ordenes[index];

                          return Card(
                            child: ListTile(
                              onTap: () {
                                Navigator.pop(sheetContext);
                                context.push('/ordenes/${item.orden.id}');
                              },
                              leading: CircleAvatar(
                                child: Icon(
                                  item.orden.estado == 'entregada'
                                      ? Icons.check
                                      : item.orden.estado == 'cancelada'
                                          ? Icons.cancel_outlined
                                          : Icons.build_outlined,
                                ),
                              ),
                              title: Text(
                                'Orden #${item.orden.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.orden.fallaReportada,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Técnico: ${item.tecnico.nombre}',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Fecha: ${item.orden.fechaRecepcion.toLocal().toString().split('.')[0]}',
                                    ),
                                  ],
                                ),
                              ),
                              isThreeLine: true,
                              trailing: StatusChip(
                                status: item.orden.estado,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _mostrarHistorial(
    BuildContext context,
    WidgetRef ref,
    int clienteId,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.85,
          child: Consumer(
            builder: (context, ref, _) {
              final data = ref.watch(clienteHistorialProvider(clienteId));

              return data.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Error al cargar el historial: $error'),
                  ),
                ),
                data: (historial) {
                  if (historial == null) {
                    return const EmptyState(
                      icon: Icons.person_off_outlined,
                      title: 'Cliente no encontrado',
                      message: 'No se pudo localizar este cliente.',
                    );
                  }

                  final cliente = historial.cliente;
                  final dispositivos = historial.dispositivos;
                  final ordenes = historial.ordenes;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.12),
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 28,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cliente.nombre,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(cliente.telefono),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _SummaryCard(
                                    icon: Icons.devices_outlined,
                                    label: 'Dispositivos',
                                    value: '${dispositivos.length}',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _SummaryCard(
                                    icon: Icons.history,
                                    label: 'Reparaciones',
                                    value: '${ordenes.length}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          children: [
                            Text(
                              'Dispositivos registrados',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            if (dispositivos.isEmpty)
                              const Text(
                                'Este cliente todavía no tiene dispositivos registrados.',
                              )
                            else
                              ...dispositivos.map(
                                (dispositivo) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    onTap: () => _mostrarHistorialDispositivo(
                                      context,
                                      dispositivo,
                                      ordenes,
                                    ),
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.devices_outlined),
                                    ),
                                    title: Text(
                                      '${dispositivo.marca} ${dispositivo.modelo}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${dispositivo.tipo}'
                                      '${dispositivo.numeroSerie?.isNotEmpty == true ? '\nSerie: ${dispositivo.numeroSerie}' : ''}',
                                    ),
                                    isThreeLine:
                                        dispositivo.numeroSerie?.isNotEmpty ==
                                            true,
                                    trailing: const Icon(Icons.chevron_right),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            Text(
                              'Historial de reparaciones',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            if (ordenes.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: EmptyState(
                                  icon: Icons.history,
                                  title: 'Sin reparaciones',
                                  message:
                                      'Las órdenes de este cliente aparecerán aquí.',
                                ),
                              )
                            else
                              ...ordenes.map(
                                (item) => Card(
                                  margin: const EdgeInsets.only(bottom: 9),
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      context.push('/ordenes/${item.orden.id}');
                                    },
                                    leading: CircleAvatar(
                                      child: Icon(
                                        item.orden.estado == 'entregada'
                                            ? Icons.check
                                            : item.orden.estado == 'cancelada'
                                                ? Icons.cancel_outlined
                                                : Icons.build_outlined,
                                      ),
                                    ),
                                    title: Text(
                                      '${item.dispositivo.marca} ${item.dispositivo.modelo}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Orden #${item.orden.id} · ${item.orden.fallaReportada}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Técnico: ${item.tecnico.nombre}',
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.orden.fechaRecepcion
                                                .toLocal()
                                                .toString()
                                                .split('.')[0],
                                          ),
                                        ],
                                      ),
                                    ),
                                    isThreeLine: true,
                                    trailing: StatusChip(
                                      status: item.orden.estado,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clientesProvider);

    return Column(
      children: [
        PageHeader(
          title: 'Clientes',
          subtitle: 'Personas registradas en el taller',
          action: IconButton(
            onPressed: () => context.push('/clientes/nuevo'),
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ),
        Expanded(
          child: data.when(
            data: (items) => items.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    title: 'Sin clientes',
                    message:
                        'Los clientes se registran al crear una orden de reparación.',
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(clientesProvider);
                      await ref.read(clientesProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final client = items[index];

                        return Card(
                          child: ListTile(
                            onTap: () => _mostrarHistorial(
                              context,
                              ref,
                              client.id,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: .12),
                              child: Icon(
                                Icons.person_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              client.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(client.telefono),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
                  ),
            error: (e, _) => Center(
              child: Text('Error: $e'),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
