import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ViewModels/theme_view_model.dart';
import '../shared/widgets.dart';

class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeViewModelProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader(
          title: 'Ajustes', subtitle: 'Preferencias de la aplicación'),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.palette_outlined,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          Text('Apariencia',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800))
                        ]),
                        const SizedBox(height: 5),
                        Text('Selecciona cómo se mostrará Tu Solution.',
                            style:
                                TextStyle(color: Theme.of(context).hintColor)),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<ThemeMode>(
                            value: mode,
                            decoration:
                                fieldDecoration('Tema de la aplicación'),
                            items: const [
                              DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text('Sistema')),
                              DropdownMenuItem(
                                  value: ThemeMode.light, child: Text('Claro')),
                              DropdownMenuItem(
                                  value: ThemeMode.dark, child: Text('Oscuro'))
                            ],
                            onChanged: (value) {
                              if (value != null)
                                ref
                                    .read(themeViewModelProvider.notifier)
                                    .cambiarTema(value);
                            }),
                      ])))),
      Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
              child: ListTile(
                  leading: Icon(Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary),
                  title: const Text('Tu Solution'),
                  subtitle: const Text(
                      'Gestión local de reparaciones · Versión 1.0.0')))),
    ]);
  }
}
