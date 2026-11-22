import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import 'app_providers.dart';

final tecnicosViewModelProvider = Provider<TecnicosViewModel>((ref) => TecnicosViewModel());

class TecnicosViewModel {
  int contarOrdenesActivas(int tecnicoId, List<OrdenResumen> orders) {
    return orders.where((item) => item.tecnico.id == tecnicoId).length;
  }
}
