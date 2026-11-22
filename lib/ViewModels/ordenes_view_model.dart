import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import '../data/database/app_database.dart';

final ordenesViewModelProvider =
    Provider<OrdenesViewModel>((ref) => OrdenesViewModel(ref));

class OrdenesViewModel {
  OrdenesViewModel(this.ref);

  final Ref ref;

  AppDatabase get db => ref.read(databaseProvider);

  Future<int> registrar({
    required int? clienteId,
    required String? nombreCliente,
    required String? telefonoCliente,
    required String tipo,
    required String marca,
    required String modelo,
    String? numeroSerie,
    required String falla,
    required int tecnicoId,
  }) async {
    if (clienteId == null) {
      final telefono = telefonoCliente?.trim() ?? '';

      if (!RegExp(r'^\d{8}$').hasMatch(telefono)) {
        throw Exception(
          'El teléfono del cliente debe tener exactamente 8 dígitos.',
        );
      }
    }

    final id = await db.crearOrdenCompleta(
      clienteId: clienteId,
      nombreCliente: nombreCliente,
      telefonoCliente: telefonoCliente,
      tipo: tipo,
      marca: marca,
      modelo: modelo,
      numeroSerie: numeroSerie,
      falla: falla,
      tecnicoId: tecnicoId,
    );

    actualizarListados();
    ref.invalidate(clientesProvider);

    return id;
  }

  Future<void> cambiarEstado(int ordenId, String estado) async {
    await db.cambiarEstado(ordenId, estado);
    actualizarListados();
  }

  Future<void> reasignarTecnico({
    required int ordenId,
    required int tecnicoId,
  }) async {
    final tecnico = await (db.select(db.tecnicos)
          ..where((t) => t.id.equals(tecnicoId)))
        .getSingleOrNull();

    if (tecnico == null) {
      throw Exception('El técnico seleccionado no existe.');
    }

    final actualizadas = await db.customUpdate(
      'UPDATE ordenes SET tecnico_id = ? '
      'WHERE id = ? AND estado NOT IN (?, ?)',
      variables: [
        Variable.withInt(tecnicoId),
        Variable.withInt(ordenId),
        Variable.withString('entregada'),
        Variable.withString('cancelada'),
      ],
      updates: {db.ordenes},
    );

    if (actualizadas == 0) {
      final orden = await (db.select(db.ordenes)
            ..where((t) => t.id.equals(ordenId)))
          .getSingleOrNull();

      if (orden == null) {
        throw Exception('La orden no existe.');
      }

      throw Exception(
        'No se puede cambiar el técnico de una orden finalizada.',
      );
    }

    actualizarListados();
    ref.invalidate(tecnicosProvider);
  }

  Future<OrdenResumen?> obtenerDetalle(int ordenId) async {
    final orders = await db.obtenerOrdenes();

    for (final order in orders) {
      if (order.orden.id == ordenId) return order;
    }

    return null;
  }

  Future<void> guardarDiagnostico(
    int ordenId,
    String diagnostico,
  ) =>
      db.actualizarDiagnostico(ordenId, diagnostico);

  Future<void> registrarTrabajo({
    required int ordenId,
    required String descripcion,
    required double costo,
  }) =>
      db.registrarTrabajo(
        ordenId: ordenId,
        descripcion: descripcion,
        costo: costo,
      );

  Future<List<QueryRow>> obtenerTrabajos(int ordenId) => db.customSelect(
        'SELECT * FROM trabajos WHERE orden_id = ?',
        variables: [Variable.withInt(ordenId)],
      ).get();

  Future<List<QueryRow>> obtenerRepuestosUtilizados(int ordenId) =>
      db.customSelect(
        'SELECT ru.*, r.nombre AS nombre_repuesto '
        'FROM repuestos_usados ru '
        'INNER JOIN repuestos r ON r.id = ru.repuesto_id '
        'WHERE ru.orden_id = ?',
        variables: [Variable.withInt(ordenId)],
      ).get();

  Future<double> calcularCostoTotal(int ordenId) => db.costoTotal(ordenId);

  void actualizarListados() {
    ref.invalidate(ordenesProvider);
    ref.invalidate(ordenesAbiertasProvider);
  }
}
