import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../ViewModels/app_providers.dart';
import '../ViewModels/ordenes_view_model.dart';
import '../shared/widgets.dart';

class OrdenesScreen extends ConsumerWidget {
  const OrdenesScreen({super.key});

  Future<void> _cambiarEstado(
    BuildContext context,
    WidgetRef ref,
    int ordenId,
    String estado,
  ) async {
    try {
      await ref.read(ordenesViewModelProvider).cambiarEstado(ordenId, estado);

      ref.read(ordenesViewModelProvider).actualizarListados();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado de la orden actualizado correctamente'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar la orden: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(ordenesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ordenes/nueva'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva orden'),
      ),
      body: Column(
        children: [
          PageHeader(
            title: 'Órdenes',
            subtitle: 'Seguimiento de las reparaciones',
            action: IconButton(
              onPressed: () {
                ref.read(ordenesViewModelProvider).actualizarListados();
              },
              icon: const Icon(Icons.refresh),
            ),
          ),
          Expanded(
            child: data.when(
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'Sin órdenes todavía',
                    message: 'Registra la primera reparación para comenzar.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.read(ordenesViewModelProvider).actualizarListados();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final orden = item.orden;

                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            context.push('/ordenes/${orden.id}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Orden #${orden.id}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    StatusChip(status: orden.estado),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${item.dispositivo.tipo} · '
                                  '${item.dispositivo.marca} '
                                  '${item.dispositivo.modelo}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.cliente.nombre,
                                  style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.engineering_outlined,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      item.tecnico.nombre,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  orden.fallaReportada,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (![
                                  'entregada',
                                  'cancelada',
                                ].contains(orden.estado)) ...[
                                  const Divider(height: 20),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: PopupMenuButton<String>(
                                      tooltip: 'Cambiar estado',
                                      onSelected: (value) {
                                        _cambiarEstado(
                                          context,
                                          ref,
                                          orden.id,
                                          value,
                                        );
                                      },
                                      itemBuilder: (_) {
                                        return switch (orden.estado) {
                                          'recibida' => const [
                                              PopupMenuItem(
                                                value: 'en_reparacion',
                                                child: Text(
                                                  'Iniciar reparación',
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'cancelada',
                                                child: Text(
                                                  'Cancelar orden',
                                                ),
                                              ),
                                            ],
                                          'en_reparacion' => const [
                                              PopupMenuItem(
                                                value: 'lista',
                                                child: Text(
                                                  'Marcar como lista',
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'cancelada',
                                                child: Text(
                                                  'Cancelar orden',
                                                ),
                                              ),
                                            ],
                                          'lista' => const [
                                              PopupMenuItem(
                                                value: 'entregada',
                                                child: Text(
                                                  'Marcar como entregada',
                                                ),
                                              ),
                                            ],
                                          _ => const <PopupMenuEntry<String>>[],
                                        };
                                      },
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Actualizar estado'),
                                          SizedBox(width: 5),
                                          Icon(Icons.more_horiz),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error al cargar las órdenes: $e'),
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
