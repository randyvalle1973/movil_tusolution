import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import 'app_providers.dart';

final historialViewModelProvider = FutureProvider<List<OrdenResumen>>((ref) async {
  final orders = await ref.watch(databaseProvider).obtenerOrdenes();
  return HistorialViewModel.filtrar(orders);
});

class HistorialViewModel {
  static List<OrdenResumen> filtrar(List<OrdenResumen> orders) {
    return orders.where((item) => ['entregada', 'cancelada'].contains(item.orden.estado)).toList();
  }
}
