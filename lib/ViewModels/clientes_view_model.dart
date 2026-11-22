import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import '../data/database/app_database.dart';

typedef ClienteHistorial = ({
  Cliente cliente,
  List<Dispositivo> dispositivos,
  List<OrdenResumen> ordenes,
});

final clientesViewModelProvider =
    Provider<ClientesViewModel>((ref) => ClientesViewModel(ref));

final clienteHistorialProvider =
    FutureProvider.family<ClienteHistorial?, int>((ref, clienteId) async {
  final db = ref.watch(databaseProvider);

  final clientes = await db.obtenerClientes();

  Cliente? cliente;

  for (final item in clientes) {
    if (item.id == clienteId) {
      cliente = item;
      break;
    }
  }

  if (cliente == null) return null;

  final dispositivos = await (db.select(db.dispositivos)
        ..where((t) => t.clienteId.equals(clienteId)))
      .get();

  final todasLasOrdenes = await db.obtenerOrdenes();

  final ordenes =
      todasLasOrdenes.where((item) => item.cliente.id == clienteId).toList()
        ..sort(
          (a, b) => b.orden.fechaRecepcion.compareTo(a.orden.fechaRecepcion),
        );

  return (
    cliente: cliente,
    dispositivos: dispositivos,
    ordenes: ordenes,
  );
});

class ClientesViewModel {
  ClientesViewModel(this.ref);

  final Ref ref;

  Future<void> registrar({
    required String nombre,
    required String telefono,
  }) async {
    await ref.read(databaseProvider).crearCliente(
          nombre: nombre,
          telefono: telefono,
        );

    ref.invalidate(clientesProvider);
  }

  void actualizarListado() => ref.invalidate(clientesProvider);
}
