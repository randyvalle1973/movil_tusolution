import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ViewModels/historial_view_model.dart';
import '../shared/widgets.dart';

class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(historialViewModelProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Historial de reparaciones')),
        body: data.when(
            data: (items) {
              final history = items;
              if (history.isEmpty)
                return const EmptyState(
                    icon: Icons.history,
                    title: 'Sin historial',
                    message: 'Las órdenes finalizadas aparecerán aquí.');
              return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return Card(
                        child: ListTile(
                            leading: const CircleAvatar(
                                child: Icon(Icons.build_outlined)),
                            title: Text(
                                '${item.dispositivo.marca} ${item.dispositivo.modelo}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                '${item.cliente.nombre} · ${item.tecnico.nombre}\n${item.orden.fallaReportada}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            isThreeLine: true,
                            trailing: StatusChip(status: item.orden.estado)));
                  });
            },
            error: (e, _) => Center(child: Text('Error: $e')),
            loading: () => const Center(child: CircularProgressIndicator())));
  }
}
