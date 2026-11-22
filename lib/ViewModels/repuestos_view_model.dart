import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import '../data/database/app_database.dart';

final repuestosViewModelProvider = Provider<RepuestosViewModel>((ref) {
  return RepuestosViewModel(ref);
});

class RepuestosViewModel {
  RepuestosViewModel(this.ref);

  final Ref ref;

  AppDatabase get db => ref.read(databaseProvider);

  Future<void> registrar({
    required String nombre,
    required String codigo,
    required double precio,
    required int existencias,
  }) async {
    await db.crearRepuesto(
      nombre: nombre,
      codigo: codigo,
      precio: precio,
      existencias: existencias,
    );

    actualizarListado();
  }

  Future<void> editar({
    required int id,
    required String nombre,
    required String codigo,
    required double precio,
    required int existencias,
  }) async {
    await db.actualizarRepuesto(
      id: id,
      nombre: nombre,
      codigo: codigo,
      precio: precio,
      existencias: existencias,
    );

    actualizarListado();
  }

  Future<List<Repuesto>> obtenerInventario() {
    return db.obtenerRepuestos();
  }

  Future<void> utilizar({
    required int ordenId,
    required int repuestoId,
    required int cantidad,
  }) async {
    await db.agregarRepuestoAOrden(
      ordenId: ordenId,
      repuestoId: repuestoId,
      cantidad: cantidad,
    );

    actualizarListado();
    ref.invalidate(ordenesProvider);
    ref.invalidate(ordenesAbiertasProvider);
  }

  void actualizarListado() {
    ref.invalidate(repuestosProvider);
  }
}
