import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ViewModels/app_providers.dart';
import '../ViewModels/clientes_view_model.dart';
import '../shared/widgets.dart';

class RegistrarClienteScreen extends ConsumerStatefulWidget {
  const RegistrarClienteScreen({super.key});

  @override
  ConsumerState<RegistrarClienteScreen> createState() =>
      _RegistrarClienteScreenState();
}

class _RegistrarClienteScreenState
    extends ConsumerState<RegistrarClienteScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();

  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      await ref.read(clientesViewModelProvider).registrar(
            nombre: name.text.trim(),
            telefono: phone.text.trim(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente registrado correctamente'),
        ),
      );

      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo registrar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar cliente'),
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Datos del cliente',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Podrás asociarlo a uno o varios dispositivos al registrar reparaciones.',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: name,
              decoration: fieldDecoration(
                'Nombre completo',
                icon: Icons.person_outline,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().length < 2
                  ? 'Introduce un nombre válido'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: phone,
              decoration: fieldDecoration(
                'Teléfono',
                icon: Icons.phone_outlined,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              maxLength: 8,
              validator: (v) {
                if (v == null || !RegExp(r'^\d{8}$').hasMatch(v)) {
                  return 'El teléfono debe tener exactamente 8 dígitos';
                }

                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: saving ? null : save,
                child: Text(
                  saving ? 'Guardando...' : 'Guardar cliente',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
