import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ViewModels/app_providers.dart';
import '../ViewModels/tecnicos_view_model.dart';
import '../shared/widgets.dart';

class TecnicosScreen extends ConsumerWidget {
  const TecnicosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(tecnicosProvider);
    final orders = ref.watch(ordenesAbiertasProvider);
    final viewModel = ref.watch(tecnicosViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Técnicos'),
      ),
      body: data.when(
        data: (items) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Equipo de trabajo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                'Los tres técnicos asignados al taller.',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 18),
              ...items.map(
                (tech) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                      child: Icon(
                        Icons.engineering_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      tech.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(tech.especialidad),
                    trailing: orders.when(
                      data: (list) {
                        final cantidad = viewModel.contarOrdenesActivas(
                          tech.id,
                          list,
                        );

                        return Chip(
                          label: Text('$cantidad activas'),
                        );
                      },
                      error: (_, __) => const Chip(
                        label: Text('—'),
                      ),
                      loading: () => const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
