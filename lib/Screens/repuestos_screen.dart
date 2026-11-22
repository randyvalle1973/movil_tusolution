import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ViewModels/app_providers.dart';
import '../../ViewModels/repuestos_view_model.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets.dart';

class RepuestosScreen extends ConsumerWidget {
  const RepuestosScreen({super.key});

  Future<void> _addPart(BuildContext context, WidgetRef ref) async {
    final data = await showDialog<
        ({String nombre, String codigo, double precio, int existencias})>(
      context: context,
      builder: (_) => const _PartDialog(),
    );

    if (data == null) return;

    try {
      await ref.read(repuestosViewModelProvider).registrar(
            nombre: data.nombre,
            codigo: data.codigo,
            precio: data.precio,
            existencias: data.existencias,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repuesto agregado')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo agregar: $e')),
        );
      }
    }
  }

  Future<void> _editPart(
    BuildContext context,
    WidgetRef ref,
    Repuesto part,
  ) async {
    final data = await showDialog<
        ({String nombre, String codigo, double precio, int existencias})>(
      context: context,
      builder: (_) => _PartDialog(part: part),
    );

    if (data == null) return;

    try {
      await ref.read(repuestosViewModelProvider).editar(
            id: part.id,
            nombre: data.nombre,
            codigo: data.codigo,
            precio: data.precio,
            existencias: data.existencias,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repuesto actualizado correctamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $e')),
        );
      }
    }
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(repuestosProvider);
    await ref.read(repuestosProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(repuestosProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPart(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Agregar repuesto'),
      ),
      body: Column(
        children: [
          PageHeader(
            title: 'Repuestos',
            subtitle: 'Inventario del taller',
          ),
          Expanded(
            child: data.when(
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Inventario vacío',
                    message: 'Agrega los repuestos disponibles en el almacén.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _refresh(ref),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final part = items[index];
                      final low = part.existencias <= 3;

                      return Card(
                        child: ListTile(
                          onTap: () => _editPart(context, ref, part),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.12),
                            child: Icon(
                              Icons.memory,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            part.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${part.codigo} · ${part.precio.toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${part.existencias} uds.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color:
                                          low ? const Color(0xFFE07825) : null,
                                    ),
                                  ),
                                  if (low)
                                    const Text(
                                      'STOCK BAJO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFFE07825),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Editar repuesto',
                                onPressed: () => _editPart(
                                  context,
                                  ref,
                                  part,
                                ),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              error: (error, _) => Center(
                child: Text('Error: $error'),
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

class _PartDialog extends StatefulWidget {
  const _PartDialog({this.part});

  final Repuesto? part;

  @override
  State<_PartDialog> createState() => _PartDialogState();
}

class _PartDialogState extends State<_PartDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _price;
  late final TextEditingController _stock;

  bool get _editing => widget.part != null;

  @override
  void initState() {
    super.initState();

    final part = widget.part;

    _name = TextEditingController(text: part?.nombre ?? '');
    _code = TextEditingController(text: part?.codigo ?? '');
    _price = TextEditingController(
      text: part == null ? '' : part.precio.toString(),
    );
    _stock = TextEditingController(
      text: part?.existencias.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  static String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obligatorio' : null;
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;

    Navigator.pop(
      context,
      (
        nombre: _name.text.trim(),
        codigo: _code.text.trim(),
        precio: double.parse(_price.text.replaceAll(',', '.')),
        existencias: int.parse(_stock.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'Editar repuesto' : 'Agregar repuesto'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: fieldDecoration('Nombre'),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _code,
                decoration: fieldDecoration('Código'),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _price,
                decoration: fieldDecoration('Precio'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );

                  if (parsed == null || !parsed.isFinite || parsed <= 0) {
                    return 'El precio debe ser mayor que cero';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _stock,
                decoration: fieldDecoration('Existencias'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');

                  if (parsed == null || parsed < 0) {
                    return 'Introduce una cantidad válida';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_editing ? 'Guardar cambios' : 'Guardar'),
        ),
      ],
    );
  }
}
