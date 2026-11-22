# Tu Solution

Aplicación Flutter para la gestión local de un taller de reparación de celulares, tablets y laptops. El proyecto está organizado con arquitectura MVVM: las pantallas se encuentran en `lib/Screens` y la lógica de presentación y negocio en `lib/ViewModels`.

## Tecnologías

- Flutter para Android.
- Drift + SQLite para persistencia local.
- Riverpod para estado y proveedores.
- GoRouter para navegación.
- SharedPreferences para conservar el tema elegido.

## Funcionalidades

- Dashboard con resumen de órdenes, clientes, técnicos y alertas de inventario.
- Creación de órdenes con cliente, dispositivo y técnico responsable en un único flujo.
- Reutilización de un dispositivo existente cuando coincide el número de serie para el mismo cliente.
- Bloqueo de órdenes activas duplicadas para el mismo dispositivo.
- Flujo de estados: recibida, en reparación, lista, entregada y cancelada.
- Registro de diagnóstico, trabajos y costos de mano de obra.
- Inventario de repuestos con alta mediante ventana emergente.
- Descuento transaccional de existencias al utilizar repuestos en una orden.
- Alerta de stock bajo cuando quedan 3 unidades o menos.
- Consulta del historial de órdenes entregadas o canceladas.
- Consulta de los tres técnicos predefinidos y su carga de órdenes activas.
- Tema claro, oscuro y sistema, con preferencia guardada.
- Funcionamiento local sin autenticación ni conexión obligatoria a Internet.

## Estructura

```text
lib/
├── main.dart
├── Screens/
│   ├── ajustes/
│   ├── clientes/
│   ├── dashboard/
│   ├── historial/
│   ├── ordenes/
│   ├── repuestos/
│   └── tecnicos/
├── ViewModels/
│   ├── app_providers.dart
│   ├── clientes_view_model.dart
│   ├── dashboard_view_model.dart
│   ├── historial_view_model.dart
│   ├── ordenes_view_model.dart
│   ├── repuestos_view_model.dart
│   ├── tecnicos_view_model.dart
│   └── theme_view_model.dart
├── core/
│   ├── router/
│   └── theme/
├── data/
│   └── database/
└── shared/
    ├── main_shell.dart
    └── widgets.dart
```

Las pantallas se encargan de representar la interfaz y capturar las interacciones. Las operaciones de negocio, validaciones de flujo, acceso a datos desde la presentación y refresco de proveedores están delegados a los ViewModels. `AppDatabase` concentra las operaciones SQLite y las transacciones.

## Preparación y ejecución

Requisitos: Flutter instalado y configurado para Android, además de Android Studio o un dispositivo Android con depuración habilitada.

Desde la carpeta raíz del proyecto:

1. Generar la plataforma Android si no está incluida:

   ```bash
   flutter create --platforms android .
   ```

2. Instalar dependencias:

   ```bash
   flutter pub get
   ```

3. Generar el código de Drift:

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Revisar el proyecto:

   ```bash
   flutter analyze
   ```

5. Ejecutar:

   ```bash
   flutter run
   ```

## Persistencia y datos iniciales

La base de datos SQLite se crea localmente con el nombre `tu_solution`. La primera carga de técnicos inserta los tres técnicos predefinidos si todavía no existen. Los datos permanecen guardados al cerrar la aplicación.

## Consideraciones

- Al crear una orden se registra o selecciona el cliente, se registra o reutiliza su dispositivo y se asigna uno de los tres técnicos.
- El número de serie permite reconocer un dispositivo ya registrado para el mismo cliente.
- El sistema impide crear otra orden para un dispositivo que ya tenga una orden abierta.
- El uso de repuestos descuenta el stock y registra el precio unitario aplicado dentro de una transacción.
- La moneda no está fijada porque el enunciado no especifica una.
- Antes de la entrega académica, ejecutar y probar el proyecto en Android, corregir cualquier incidencia del entorno y guardar capturas reales de la aplicación funcionando.
