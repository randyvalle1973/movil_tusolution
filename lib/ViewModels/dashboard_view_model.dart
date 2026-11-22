import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';
import '../data/database/app_database.dart';

final dashboardViewModelProvider = Provider<DashboardViewModel>((ref) => DashboardViewModel(ref));

class DashboardViewModel {
  DashboardViewModel(this.ref);
  final Ref ref;

  int contarRepuestosConStockBajo(List<Repuesto> items) => items.where((item) => item.existencias <= 3).length;

  void actualizarResumen() {
    ref.invalidate(ordenesProvider);
    ref.invalidate(ordenesAbiertasProvider);
    ref.invalidate(repuestosProvider);
    ref.invalidate(clientesProvider);
    ref.invalidate(tecnicosProvider);
  }
}
