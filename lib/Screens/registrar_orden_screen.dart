import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../ViewModels/app_providers.dart';
import '../ViewModels/ordenes_view_model.dart';
import '../shared/widgets.dart';

class RegistrarOrdenScreen extends ConsumerStatefulWidget {
  const RegistrarOrdenScreen({super.key});
  @override
  ConsumerState<RegistrarOrdenScreen> createState() =>
      _RegistrarOrdenScreenState();
}

class _RegistrarOrdenScreenState extends ConsumerState<RegistrarOrdenScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final type = TextEditingController();
  final brand = TextEditingController();
  final model = TextEditingController();
  final serial = TextEditingController();
  final fault = TextEditingController();
  int clientValue = 0;
  int? technicianId;
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    type.dispose();
    brand.dispose();
    model.dispose();
    serial.dispose();
    fault.dispose();
    super.dispose();
  }

  String? requiredText(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio'
      : null;

  Future<void> save() async {
    if (!formKey.currentState!.validate() || technicianId == null) return;
    setState(() => saving = true);
    try {
      final id = await ref.read(ordenesViewModelProvider).registrar(
            clienteId: clientValue == 0 ? null : clientValue,
            nombreCliente: clientValue == 0 ? name.text : null,
            telefonoCliente: clientValue == 0 ? phone.text : null,
            tipo: type.text.trim(),
            marca: brand.text.trim(),
            modelo: model.text.trim(),
            numeroSerie: serial.text,
            falla: fault.text,
            tecnicoId: technicianId!,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Orden #$id registrada correctamente')));
      context.pop();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientesProvider);
    final technicians = ref.watch(tecnicosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva reparación')),
      body: Form(
          key: formKey,
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text('Registrar orden',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(
                    'Registra al cliente, su dispositivo y el técnico responsable. Si repites el número de serie para el mismo cliente, se reutilizará el dispositivo.',
                    style: TextStyle(color: Theme.of(context).hintColor)),
                const SizedBox(height: 22),
                _SectionTitle(title: '1. Cliente', icon: Icons.person_outline),
                clients.when(
                    data: (items) => DropdownButtonFormField<int>(
                        value: clientValue,
                        decoration: fieldDecoration('Cliente',
                            icon: Icons.people_outline),
                        items: [
                          const DropdownMenuItem(
                              value: 0, child: Text('Registrar nuevo cliente')),
                          ...items.map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.nombre)))
                        ],
                        onChanged: (value) =>
                            setState(() => clientValue = value ?? 0)),
                    error: (e, _) => Text('Error cargando clientes: $e'),
                    loading: () => const LinearProgressIndicator()),
                if (clientValue == 0) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: name,
                      decoration: fieldDecoration('Nombre del cliente'),
                      validator: requiredText,
                      textCapitalization: TextCapitalization.words),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: phone,
                      decoration: fieldDecoration('Teléfono',
                          icon: Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                      validator: requiredText),
                ],
                const SizedBox(height: 24),
                _SectionTitle(
                    title: '2. Dispositivo', icon: Icons.devices_outlined),
                DropdownButtonFormField<String>(
                    decoration: fieldDecoration('Tipo de dispositivo'),
                    items: const ['Celular', 'Tablet', 'Laptop', 'Otro']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => type.text = v ?? '',
                    validator: (_) =>
                        type.text.isEmpty ? 'Selecciona un tipo' : null),
                const SizedBox(height: 12),
                TextFormField(
                    controller: brand,
                    decoration: fieldDecoration('Marca'),
                    validator: requiredText,
                    textCapitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                TextFormField(
                    controller: model,
                    decoration: fieldDecoration('Modelo'),
                    validator: requiredText),
                const SizedBox(height: 12),
                TextFormField(
                    controller: serial,
                    decoration: fieldDecoration('Número de serie'),
                    validator: requiredText),
                const SizedBox(height: 24),
                _SectionTitle(
                    title: '3. Reparación', icon: Icons.build_outlined),
                TextFormField(
                    controller: fault,
                    decoration: fieldDecoration('Falla reportada',
                        hint: 'Describe el problema que presenta el equipo'),
                    minLines: 3,
                    maxLines: 5,
                    validator: requiredText),
                const SizedBox(height: 12),
                technicians.when(
                    data: (items) => DropdownButtonFormField<int>(
                        value: technicianId,
                        decoration: fieldDecoration('Técnico responsable',
                            icon: Icons.engineering_outlined),
                        items: items
                            .map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text('${t.nombre} · ${t.especialidad}')))
                            .toList(),
                        onChanged: (v) => setState(() => technicianId = v),
                        validator: (v) =>
                            v == null ? 'Selecciona un técnico' : null),
                    error: (e, _) => Text('Error cargando técnicos: $e'),
                    loading: () => const LinearProgressIndicator()),
                const SizedBox(height: 24),
                SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                        onPressed: saving ? null : save,
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_outlined),
                        label: Text(saving
                            ? 'Guardando...'
                            : 'Crear orden de reparación'))),
              ])),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800))
      ]));
}
