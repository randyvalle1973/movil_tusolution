import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final clientesProvider = FutureProvider((ref) => ref.watch(databaseProvider).obtenerClientes());
final tecnicosProvider = FutureProvider((ref) async { final db = ref.watch(databaseProvider); await db.inicializarTecnicos(); return db.obtenerTecnicos(); });
final repuestosProvider = FutureProvider((ref) => ref.watch(databaseProvider).obtenerRepuestos());
final ordenesProvider = FutureProvider((ref) => ref.watch(databaseProvider).obtenerOrdenes());
final ordenesAbiertasProvider = FutureProvider((ref) => ref.watch(databaseProvider).obtenerOrdenes(abiertas: true));
