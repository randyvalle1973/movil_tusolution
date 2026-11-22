import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../ViewModels/app_providers.dart';
import '../../ViewModels/ordenes_view_model.dart';
import '../../ViewModels/repuestos_view_model.dart';
import '../../shared/widgets.dart';

class OrdenDetalleScreen extends ConsumerStatefulWidget {
  const OrdenDetalleScreen({
    super.key,
    required this.ordenId,
  });

  final int ordenId;

  @override
  ConsumerState<OrdenDetalleScreen> createState() => _OrdenDetalleScreenState();
}

class _OrdenDetalleScreenState extends ConsumerState<OrdenDetalleScreen> {
  late Future<OrdenResumen?> orderFuture;
  late Future<double> totalFuture;
  late Future<List<QueryRow>> trabajosFuture;
  late Future<List<QueryRow>> repuestosFuture;
  bool _cambiandoEstado = false;
  bool _cambiandoTecnico = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final viewModel = ref.read(ordenesViewModelProvider);

    orderFuture = viewModel.obtenerDetalle(widget.ordenId);
    totalFuture = viewModel.calcularCostoTotal(widget.ordenId);
    trabajosFuture = viewModel.obtenerTrabajos(widget.ordenId);
    repuestosFuture = viewModel.obtenerRepuestosUtilizados(widget.ordenId);
  }

  void refresh() {
    if (!mounted) return;

    setState(_reload);
  }

  void _mostrarError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editDiagnosis(String? current) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _DiagnosisDialog(initialText: current ?? ''),
    );

    if (value == null || !mounted) return;

    try {
      await ref
          .read(ordenesViewModelProvider)
          .guardarDiagnostico(widget.ordenId, value);

      refresh();
    } catch (e) {
      _mostrarError(e);
    }
  }

  Future<void> _cambiarTecnico(OrdenResumen item) async {
    if (_cambiandoTecnico) return;

    try {
      final tecnicos = await ref.read(tecnicosProvider.future);

      if (!mounted) return;

      if (tecnicos.isEmpty) {
        _mostrarError('No hay técnicos registrados.');
        return;
      }

      final tecnicoId = await showDialog<int>(
        context: context,
        builder: (_) => _TecnicoDialog(
          tecnicos: tecnicos,
          tecnicoActualId: item.tecnico.id,
        ),
      );

      if (tecnicoId == null || !mounted) return;

      if (tecnicoId == item.tecnico.id) return;

      setState(() => _cambiandoTecnico = true);

      await ref.read(ordenesViewModelProvider).reasignarTecnico(
            ordenId: widget.ordenId,
            tecnicoId: tecnicoId,
          );

      if (!mounted) return;

      refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Técnico responsable actualizado correctamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) {
        setState(() => _cambiandoTecnico = false);
      }
    }
  }

  Future<void> _addWork() async {
    final work = await showDialog<({String descripcion, double costo})>(
      context: context,
      builder: (_) => const _WorkDialog(),
    );

    if (work == null || !mounted) return;

    try {
      await ref.read(ordenesViewModelProvider).registrarTrabajo(
            ordenId: widget.ordenId,
            descripcion: work.descripcion,
            costo: work.costo,
          );

      refresh();
    } catch (e) {
      _mostrarError(e);
    }
  }

  Future<void> _addPart() async {
    try {
      final inventory =
          await ref.read(repuestosViewModelProvider).obtenerInventario();

      if (!mounted) return;

      final parts = inventory
          .where((part) => part.existencias > 0)
          .map(
            (part) => (
              id: part.id,
              nombre: part.nombre,
              existencias: part.existencias,
            ),
          )
          .toList();

      if (parts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay repuestos disponibles en el inventario.',
            ),
          ),
        );
        return;
      }

      final selection = await showDialog<({int repuestoId, int cantidad})>(
        context: context,
        builder: (_) => _PartDialog(parts: parts),
      );

      if (selection == null || !mounted) return;

      await ref.read(repuestosViewModelProvider).utilizar(
            ordenId: widget.ordenId,
            repuestoId: selection.repuestoId,
            cantidad: selection.cantidad,
          );

      refresh();
    } catch (e) {
      _mostrarError(e);
    }
  }

  List<({String value, String label, IconData icon})> _transiciones(
    String estado,
  ) {
    return switch (estado) {
      'recibida' => const [
          (
            value: 'en_reparacion',
            label: 'Iniciar reparación',
            icon: Icons.build_outlined,
          ),
          (
            value: 'cancelada',
            label: 'Cancelar orden',
            icon: Icons.cancel_outlined,
          ),
        ],
      'en_reparacion' => const [
          (
            value: 'lista',
            label: 'Marcar como lista',
            icon: Icons.check_circle_outline,
          ),
          (
            value: 'cancelada',
            label: 'Cancelar orden',
            icon: Icons.cancel_outlined,
          ),
        ],
      'lista' => const [
          (
            value: 'entregada',
            label: 'Marcar como entregada',
            icon: Icons.local_shipping_outlined,
          ),
        ],
      _ => const [],
    };
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    if (_cambiandoEstado) return;

    if (nuevoEstado == 'cancelada') {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancelar orden'),
          content: Text(
            'La orden #${widget.ordenId} quedará cancelada y ya no se '
            'podrá modificar. ¿Quieres continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancelar orden'),
            ),
          ],
        ),
      );

      if (confirmar != true || !mounted) return;
    }

    setState(() => _cambiandoEstado = true);

    try {
      final viewModel = ref.read(ordenesViewModelProvider);

      await viewModel.cambiarEstado(widget.ordenId, nuevoEstado);
      viewModel.actualizarListados();

      if (!mounted) return;

      refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado de la orden actualizado correctamente'),
        ),
      );
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _cambiandoEstado = false);
    }
  }

  Widget _buildCambiarEstado(String estado) {
    final opciones = _transiciones(estado);

    if (opciones.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: MenuAnchor(
        menuChildren: [
          for (final opcion in opciones)
            MenuItemButton(
              leadingIcon: Icon(opcion.icon),
              onPressed: () => _cambiarEstado(opcion.value),
              child: Text(opcion.label),
            ),
        ],
        builder: (context, controller, _) => FilledButton.tonalIcon(
          onPressed: _cambiandoEstado
              ? null
              : () =>
                  controller.isOpen ? controller.close() : controller.open(),
          icon: _cambiandoEstado
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync_alt),
          label: const Text('Cambiar estado'),
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title, {
    VoidCallback? onAdd,
    bool enabled = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (onAdd != null)
          IconButton(
            onPressed: enabled ? onAdd : null,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Agregar',
          ),
      ],
    );
  }

  Widget _buildTrabajos() {
    return FutureBuilder<List<QueryRow>>(
      future: trabajosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text('Error al cargar los trabajos: ${snapshot.error}');
        }

        final rows = snapshot.data ?? [];

        if (rows.isEmpty) {
          return const Text(
            'Todavía no hay trabajos registrados.',
          );
        }

        return Column(
          children: rows.map((work) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                work.read<String>('descripcion'),
              ),
              trailing: Text(
                work.read<double>('costo').toStringAsFixed(2),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRepuestos() {
    return FutureBuilder<List<QueryRow>>(
      future: repuestosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Error al cargar los repuestos: ${snapshot.error}',
          );
        }

        final rows = snapshot.data ?? [];

        if (rows.isEmpty) {
          return const Text(
            'Todavía no se han utilizado repuestos.',
          );
        }

        return Column(
          children: rows.map((part) {
            final cantidad = part.read<int>('cantidad');
            final precio = part.read<double>('precio_unitario');

            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                part.read<String>('nombre_repuesto'),
              ),
              subtitle: Text('Cantidad: $cantidad'),
              trailing: Text(
                (cantidad * precio).toStringAsFixed(2),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTotal() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Costo total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            FutureBuilder<double>(
              future: totalFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Icon(Icons.error_outline);
                }

                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  );
                }

                return Text(
                  (snapshot.data ?? 0).toStringAsFixed(2),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalle(OrdenResumen item) {
    final estadoFinal = [
      'entregada',
      'cancelada',
    ].contains(item.orden.estado);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${item.dispositivo.marca} ${item.dispositivo.modelo}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            StatusChip(status: item.orden.estado),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${item.dispositivo.tipo} · ${item.cliente.nombre} · ${item.cliente.telefono}',
        ),
        if (!estadoFinal) ...[
          const SizedBox(height: 14),
          _buildCambiarEstado(item.orden.estado),
        ],
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Falla reportada',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(item.orden.fallaReportada),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Diagnóstico técnico',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: estadoFinal
                          ? null
                          : () => _editDiagnosis(
                                item.orden.diagnostico,
                              ),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
                Text(
                  item.orden.diagnostico?.isNotEmpty == true
                      ? item.orden.diagnostico!
                      : 'Sin diagnóstico registrado.',
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Técnico responsable',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.tecnico.nombre,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cambiar técnico responsable',
                      onPressed: estadoFinal || _cambiandoTecnico
                          ? null
                          : () => _cambiarTecnico(item),
                      icon: _cambiandoTecnico
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'Fecha de recepción',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.orden.fechaRecepcion.toLocal().toString().split('.')[0],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle(
          'Trabajos realizados',
          onAdd: _addWork,
          enabled: !estadoFinal,
        ),
        _buildTrabajos(),
        const SizedBox(height: 16),
        _sectionTitle(
          'Repuestos utilizados',
          onAdd: _addPart,
          enabled: !estadoFinal,
        ),
        _buildRepuestos(),
        const SizedBox(height: 20),
        _buildTotal(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orden #${widget.ordenId}'),
      ),
      body: FutureBuilder<OrdenResumen?>(
        future: orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Error al cargar la orden',
              message: snapshot.error.toString(),
            );
          }

          final item = snapshot.data;

          if (item == null) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Orden no encontrada',
              message: 'No se pudo localizar esta reparación.',
            );
          }

          return _buildDetalle(item);
        },
      ),
    );
  }
}

class _TecnicoDialog extends StatefulWidget {
  const _TecnicoDialog({
    required this.tecnicos,
    required this.tecnicoActualId,
  });

  final List<Tecnico> tecnicos;
  final int tecnicoActualId;

  @override
  State<_TecnicoDialog> createState() => _TecnicoDialogState();
}

class _TecnicoDialogState extends State<_TecnicoDialog> {
  late int _seleccionado = widget.tecnicoActualId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar técnico responsable'),
      content: DropdownButtonFormField<int>(
        value: _seleccionado,
        isExpanded: true,
        decoration: fieldDecoration('Técnico'),
        items: widget.tecnicos.map((tecnico) {
          return DropdownMenuItem<int>(
            value: tecnico.id,
            child: Text(
              tecnico.nombre,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _seleccionado = value);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _seleccionado),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _DiagnosisDialog extends StatefulWidget {
  const _DiagnosisDialog({required this.initialText});

  final String initialText;

  @override
  State<_DiagnosisDialog> createState() => _DiagnosisDialogState();
}

class _DiagnosisDialogState extends State<_DiagnosisDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Diagnóstico técnico'),
      content: TextField(
        controller: _controller,
        minLines: 3,
        maxLines: 5,
        decoration: fieldDecoration('Diagnóstico'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _WorkDialog extends StatefulWidget {
  const _WorkDialog();

  @override
  State<_WorkDialog> createState() => _WorkDialogState();
}

class _WorkDialogState extends State<_WorkDialog> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _cost = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;

    Navigator.pop(context, (
      descripcion: _description.text.trim(),
      costo: double.parse(_cost.text.replaceAll(',', '.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar trabajo'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _description,
              decoration: fieldDecoration('Descripción'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'La descripción es obligatoria';
                }

                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _cost,
              decoration: fieldDecoration('Costo de mano de obra'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final value = double.tryParse(
                  (v ?? '').replaceAll(',', '.'),
                );

                if (value == null || !value.isFinite || value <= 0) {
                  return 'Introduce un costo mayor que cero';
                }

                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

typedef _PartOption = ({int id, String nombre, num existencias});

class _PartDialog extends StatefulWidget {
  const _PartDialog({required this.parts});

  final List<_PartOption> parts;

  @override
  State<_PartDialog> createState() => _PartDialogState();
}

class _PartDialogState extends State<_PartDialog> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  late int _selected = widget.parts.first.id;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;

    Navigator.pop(context, (
      repuestoId: _selected,
      cantidad: int.parse(_quantity.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Utilizar repuesto'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _selected,
              isExpanded: true,
              decoration: fieldDecoration('Repuesto'),
              items: widget.parts.map((part) {
                return DropdownMenuItem<int>(
                  value: part.id,
                  child: Text(
                    '${part.nombre} (${part.existencias} disponibles)',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selected = value);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _quantity,
              decoration: fieldDecoration('Cantidad'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final amount = int.tryParse(v ?? '');

                if (amount == null || amount <= 0) {
                  return 'Cantidad inválida';
                }

                final part = widget.parts.firstWhere(
                  (p) => p.id == _selected,
                );

                if (amount > part.existencias) {
                  return 'Solo hay ${part.existencias} disponibles';
                }

                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Descontar del inventario'),
        ),
      ],
    );
  }
}
