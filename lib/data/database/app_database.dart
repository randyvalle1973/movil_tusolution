import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Clientes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().withLength(min: 2, max: 120)();
  TextColumn get telefono => text().withLength(min: 3, max: 40)();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

class Dispositivos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get clienteId => integer().references(Clientes, #id)();
  TextColumn get tipo => text()();
  TextColumn get marca => text()();
  TextColumn get modelo => text()();
  TextColumn get numeroSerie => text().nullable()();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

class Tecnicos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  TextColumn get especialidad => text()();
}

class Ordenes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dispositivoId => integer().references(Dispositivos, #id)();
  IntColumn get tecnicoId => integer().references(Tecnicos, #id)();
  TextColumn get fallaReportada => text()();
  TextColumn get diagnostico => text().nullable()();
  TextColumn get estado => text().withDefault(const Constant('recibida'))();
  RealColumn get manoObra => real().withDefault(const Constant(0))();
  DateTimeColumn get fechaRecepcion =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get fechaCierre => dateTime().nullable()();
}

class Trabajos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ordenId => integer().references(Ordenes, #id)();
  TextColumn get descripcion => text()();
  RealColumn get costo => real()();
}

class Repuestos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  TextColumn get codigo => text().unique()();
  RealColumn get precio => real()();
  IntColumn get existencias => integer()();
}

class RepuestosUsados extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ordenId => integer().references(Ordenes, #id)();
  IntColumn get repuestoId => integer().references(Repuestos, #id)();
  IntColumn get cantidad => integer()();
  RealColumn get precioUnitario => real()();
}

@DriftDatabase(
  tables: [
    Clientes,
    Dispositivos,
    Tecnicos,
    Ordenes,
    Trabajos,
    Repuestos,
    RepuestosUsados,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'tu_solution'));

  @override
  int get schemaVersion => 1;

  static const estadosFinales = ['entregada', 'cancelada'];

  String _validarTexto(String valor, String campo) {
    final texto = valor.trim();

    if (texto.isEmpty) {
      throw Exception('$campo es obligatorio.');
    }

    return texto;
  }

  String _validarTelefono(String valor) {
    final telefono = valor.trim();

    if (!RegExp(r'^\d{8}$').hasMatch(telefono)) {
      throw Exception('El teléfono debe tener exactamente 8 dígitos.');
    }

    return telefono;
  }

  Future<Ordene> _obtenerOrdenEditable(int ordenId) async {
    final orden =
        await (select(ordenes)..where((t) => t.id.equals(ordenId))).getSingle();

    if (estadosFinales.contains(orden.estado)) {
      throw Exception('No se puede modificar una orden finalizada.');
    }

    return orden;
  }

  Future<void> inicializarTecnicos() async {
    final actuales = await select(tecnicos).get();

    if (actuales.isNotEmpty) return;

    await batch((batch) {
      batch.insertAll(tecnicos, [
        TecnicosCompanion.insert(
          nombre: 'Técnico 1',
          especialidad: 'Telefonía y tablets',
        ),
        TecnicosCompanion.insert(
          nombre: 'Técnico 2',
          especialidad: 'Laptops y computadoras',
        ),
        TecnicosCompanion.insert(
          nombre: 'Técnico 3',
          especialidad: 'Electrónica general',
        ),
      ]);
    });
  }

  Future<List<Cliente>> obtenerClientes() {
    return (select(clientes)..orderBy([(t) => OrderingTerm.asc(t.nombre)]))
        .get();
  }

  Future<List<Tecnico>> obtenerTecnicos() {
    return (select(tecnicos)..orderBy([(t) => OrderingTerm.asc(t.nombre)]))
        .get();
  }

  Future<List<Repuesto>> obtenerRepuestos() {
    return (select(repuestos)..orderBy([(t) => OrderingTerm.asc(t.nombre)]))
        .get();
  }

  Future<List<OrdenResumen>> obtenerOrdenes({
    bool abiertas = false,
  }) async {
    final query = select(ordenes).join([
      innerJoin(
        dispositivos,
        dispositivos.id.equalsExp(ordenes.dispositivoId),
      ),
      innerJoin(
        clientes,
        clientes.id.equalsExp(dispositivos.clienteId),
      ),
      innerJoin(
        tecnicos,
        tecnicos.id.equalsExp(ordenes.tecnicoId),
      ),
    ]);

    if (abiertas) {
      query.where(ordenes.estado.isNotIn(estadosFinales));
    }

    query.orderBy([
      OrderingTerm.desc(ordenes.fechaRecepcion),
    ]);

    final rows = await query.get();

    return rows.map((row) {
      return OrdenResumen(
        orden: row.readTable(ordenes),
        dispositivo: row.readTable(dispositivos),
        cliente: row.readTable(clientes),
        tecnico: row.readTable(tecnicos),
      );
    }).toList();
  }

  Future<int> crearCliente({
    required String nombre,
    required String telefono,
  }) {
    final nombreValidado = _validarTexto(nombre, 'El nombre');
    final telefonoValidado = _validarTexto(telefono, 'El teléfono');

    if (nombreValidado.length < 2) {
      throw Exception('El nombre debe tener al menos 2 caracteres.');
    }

    if (telefonoValidado.length < 3) {
      throw Exception('El teléfono debe tener al menos 3 caracteres.');
    }

    return into(clientes).insert(
      ClientesCompanion.insert(
        nombre: nombreValidado,
        telefono: telefonoValidado,
      ),
    );
  }

  Future<int> crearOrdenCompleta({
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
    final tipoValidado = _validarTexto(tipo, 'El tipo de dispositivo');
    final marcaValidada = _validarTexto(marca, 'La marca');
    final modeloValidado = _validarTexto(modelo, 'El modelo');
    final fallaValidada = _validarTexto(falla, 'La falla reportada');

    return transaction(() async {
      final tecnico = await (select(tecnicos)
            ..where((t) => t.id.equals(tecnicoId)))
          .getSingle();

      final int idCliente;

      if (clienteId != null) {
        await (select(clientes)..where((t) => t.id.equals(clienteId)))
            .getSingle();

        idCliente = clienteId;
      } else {
        final nombre = _validarTexto(
          nombreCliente ?? '',
          'El nombre del cliente',
        );

        final telefono = _validarTexto(
          telefonoCliente ?? '',
          'El teléfono del cliente',
        );

        idCliente = await into(clientes).insert(
          ClientesCompanion.insert(
            nombre: nombre,
            telefono: telefono,
          ),
        );
      }

      final serie = numeroSerie?.trim();

      final existentes = serie == null || serie.isEmpty
          ? <Dispositivo>[]
          : await (select(dispositivos)
                ..where(
                  (t) =>
                      t.clienteId.equals(idCliente) &
                      t.numeroSerie.equals(serie),
                ))
              .get();

      final int dispositivoId;

      if (existentes.isNotEmpty) {
        dispositivoId = existentes.first.id;
      } else {
        dispositivoId = await into(dispositivos).insert(
          DispositivosCompanion.insert(
            clienteId: idCliente,
            tipo: tipoValidado,
            marca: marcaValidada,
            modelo: modeloValidado,
            numeroSerie: Value(
              serie == null || serie.isEmpty ? null : serie,
            ),
          ),
        );
      }

      final ordenesActivas = await (select(ordenes)
            ..where(
              (t) =>
                  t.dispositivoId.equals(dispositivoId) &
                  t.estado.isNotIn(estadosFinales),
            ))
          .get();

      if (ordenesActivas.isNotEmpty) {
        throw Exception(
          'Este dispositivo ya tiene una orden abierta '
          '(#${ordenesActivas.first.id}).',
        );
      }

      return into(ordenes).insert(
        OrdenesCompanion.insert(
          dispositivoId: dispositivoId,
          tecnicoId: tecnico.id,
          fallaReportada: fallaValidada,
        ),
      );
    });
  }

  Future<void> cambiarEstado(
    int ordenId,
    String estado,
  ) async {
    final orden =
        await (select(ordenes)..where((t) => t.id.equals(ordenId))).getSingle();

    const transiciones = <String, List<String>>{
      'recibida': ['en_reparacion', 'cancelada'],
      'en_reparacion': ['lista', 'cancelada'],
      'lista': ['entregada'],
      'entregada': [],
      'cancelada': [],
    };

    if (!(transiciones[orden.estado] ?? []).contains(estado)) {
      throw Exception(
        'No se permite cambiar de ${orden.estado} a $estado.',
      );
    }

    final cierre = estadosFinales.contains(estado)
        ? Value(DateTime.now())
        : const Value<DateTime?>.absent();

    await (update(ordenes)..where((t) => t.id.equals(ordenId))).write(
      OrdenesCompanion(
        estado: Value(estado),
        fechaCierre: cierre,
      ),
    );
  }

  Future<void> actualizarDiagnostico(
    int ordenId,
    String diagnostico,
  ) async {
    await _obtenerOrdenEditable(ordenId);

    final texto = diagnostico.trim();

    await (update(ordenes)..where((t) => t.id.equals(ordenId))).write(
      OrdenesCompanion(
        diagnostico: Value(texto.isEmpty ? null : texto),
      ),
    );
  }

  Future<int> crearRepuesto({
    required String nombre,
    required String codigo,
    required double precio,
    required int existencias,
  }) {
    final nombreValidado = _validarTexto(nombre, 'El nombre');
    final codigoValidado = _validarTexto(codigo, 'El código');

    if (precio <= 0 || !precio.isFinite) {
      throw Exception('El precio debe ser mayor que cero.');
    }

    if (existencias < 0) {
      throw Exception('Las existencias no pueden ser negativas.');
    }

    return into(repuestos).insert(
      RepuestosCompanion.insert(
        nombre: nombreValidado,
        codigo: codigoValidado,
        precio: precio,
        existencias: existencias,
      ),
    );
  }

  Future<void> actualizarRepuesto({
    required int id,
    required String nombre,
    required String codigo,
    required double precio,
    required int existencias,
  }) async {
    final nombreValidado = _validarTexto(nombre, 'El nombre');
    final codigoValidado = _validarTexto(codigo, 'El código');

    if (precio <= 0 || !precio.isFinite) {
      throw Exception('El precio debe ser mayor que cero.');
    }

    if (existencias < 0) {
      throw Exception('Las existencias no pueden ser negativas.');
    }

    final repuesto = await (select(repuestos)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (repuesto == null) {
      throw Exception('El repuesto no existe.');
    }

    final codigoExistente = await (select(repuestos)
          ..where((t) => t.codigo.equals(codigoValidado)))
        .getSingleOrNull();

    if (codigoExistente != null && codigoExistente.id != id) {
      throw Exception('Ya existe otro repuesto con ese código.');
    }

    await (update(repuestos)..where((t) => t.id.equals(id))).write(
      RepuestosCompanion(
        nombre: Value(nombreValidado),
        codigo: Value(codigoValidado),
        precio: Value(precio),
        existencias: Value(existencias),
      ),
    );
  }

  Future<void> agregarRepuestoAOrden({
    required int ordenId,
    required int repuestoId,
    required int cantidad,
  }) async {
    if (cantidad <= 0) {
      throw Exception('La cantidad debe ser mayor que cero.');
    }

    await transaction(() async {
      await _obtenerOrdenEditable(ordenId);

      final item = await (select(repuestos)
            ..where((t) => t.id.equals(repuestoId)))
          .getSingle();

      if (item.existencias < cantidad) {
        throw Exception(
          'Existencias insuficientes para ${item.nombre}. '
          'Disponibles: ${item.existencias}.',
        );
      }

      await (update(repuestos)..where((t) => t.id.equals(repuestoId))).write(
        RepuestosCompanion(
          existencias: Value(item.existencias - cantidad),
        ),
      );

      await into(repuestosUsados).insert(
        RepuestosUsadosCompanion.insert(
          ordenId: ordenId,
          repuestoId: repuestoId,
          cantidad: cantidad,
          precioUnitario: item.precio,
        ),
      );
    });
  }

  Future<void> registrarTrabajo({
    required int ordenId,
    required String descripcion,
    required double costo,
  }) async {
    final descripcionValidada = _validarTexto(
      descripcion,
      'La descripción del trabajo',
    );

    if (costo <= 0 || !costo.isFinite) {
      throw Exception('El costo debe ser mayor que cero.');
    }

    await transaction(() async {
      final orden = await _obtenerOrdenEditable(ordenId);

      await into(trabajos).insert(
        TrabajosCompanion.insert(
          ordenId: ordenId,
          descripcion: descripcionValidada,
          costo: costo,
        ),
      );

      await (update(ordenes)..where((t) => t.id.equals(ordenId))).write(
        OrdenesCompanion(
          manoObra: Value(orden.manoObra + costo),
        ),
      );
    });
  }

  Future<double> costoTotal(int ordenId) async {
    final orden =
        await (select(ordenes)..where((t) => t.id.equals(ordenId))).getSingle();

    final piezasRows = await (select(repuestosUsados)
          ..where((t) => t.ordenId.equals(ordenId)))
        .get();

    final costoRepuestos = piezasRows.fold<double>(
      0,
      (sum, item) => sum + item.cantidad * item.precioUnitario,
    );

    return orden.manoObra + costoRepuestos;
  }
}

class OrdenResumen {
  const OrdenResumen({
    required this.orden,
    required this.dispositivo,
    required this.cliente,
    required this.tecnico,
  });

  final Ordene orden;
  final Dispositivo dispositivo;
  final Cliente cliente;
  final Tecnico tecnico;
}
