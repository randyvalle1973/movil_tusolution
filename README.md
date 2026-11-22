# Tu Solution

Aplicación móvil desarrollada en Flutter para la gestión de un taller de reparación de equipos electrónicos. Permite administrar clientes, dispositivos, órdenes de reparación, técnicos y repuestos desde una única aplicación, utilizando una base de datos local para conservar la información.

## Características principales

### Gestión de clientes
- Registrar clientes con nombre y número de teléfono.
- Consultar los clientes registrados.
- Editar la información de los clientes.
- Consultar el historial de reparaciones de cada cliente.
- Evitar la eliminación de clientes que tengan dispositivos registrados, para preservar el historial.

### Gestión de dispositivos
- Registrar dispositivos asociados a un cliente.
- Almacenar tipo, marca, modelo y número de serie.
- Reconocer dispositivos existentes mediante el número de serie dentro del mismo cliente.
- Consultar el historial de reparaciones de cada dispositivo.
- Permitir que un mismo dispositivo tenga varias órdenes de reparación a lo largo del tiempo.

### Gestión de órdenes de reparación
- Crear órdenes seleccionando un cliente existente o registrando uno nuevo.
- Registrar o reutilizar el dispositivo del cliente.
- Asignar un técnico responsable.
- Registrar la falla reportada por el cliente.
- Registrar diagnósticos y trabajos realizados.
- Administrar los estados de las órdenes:
  - Recibida.
  - En reparación.
  - Lista para entregar.
  - Entregada.
  - Cancelada.
- Consultar órdenes abiertas y su información.
- Consultar el historial de reparaciones.
- Reasignar el técnico responsable de una orden.
- Impedir la creación de otra orden para un dispositivo que ya tenga una orden abierta.

### Gestión de técnicos
- Consultar los técnicos registrados.
- Visualizar el técnico responsable de cada orden.
- Consultar la carga de trabajo de los técnicos.
- Asignar y reasignar técnicos a las órdenes.

### Gestión de repuestos e inventario
- Registrar repuestos con nombre, código, precio y existencias.
- Editar los datos de los repuestos.
- Consultar las existencias disponibles.
- Descontar automáticamente las unidades utilizadas en una reparación.
- Registrar el precio unitario aplicado al momento de utilizar el repuesto.
- Alertar cuando las existencias sean bajas.

### Cálculo de costos
El costo total de una reparación se calcula sumando:

**Total = Mano de obra + Costo de los repuestos utilizados**

Los precios de los repuestos utilizados se conservan en el historial de cada orden, aunque posteriormente se modifique el precio del inventario.

## Tecnologías utilizadas

- **Flutter:** desarrollo de la aplicación móvil.
- **Dart:** lenguaje de programación.
- **SQLite:** almacenamiento local de información.
- **Drift:** acceso y gestión de la base de datos.
- **Riverpod:** administración del estado.
- **GoRouter:** navegación entre pantallas.
- **Arquitectura MVVM:** separación de responsabilidades entre interfaz, lógica y datos.

## Almacenamiento de datos

La aplicación utiliza una base de datos local SQLite mediante Drift.

Esto permite:
- Conservar los datos al cerrar y volver a abrir la aplicación.
- Trabajar sin conexión a Internet.
- Mantener relaciones entre clientes, dispositivos, órdenes, técnicos y repuestos.
- Ejecutar operaciones relacionadas con el inventario mediante transacciones para mantener la consistencia de los datos.

## Estructura del proyecto

La organización principal del código es la siguiente:

```text
lib/
├── core/
│   ├── router/
│   │   └── app_router.dart
│   └── theme/
│       └── app_theme.dart
│
├── data/
│   └── database/
│       ├── app_database.dart
│       └── app_database.g.dart
│
├── Screens/
│   ├── ajustes_screen.dart
│   ├── clientes_screen.dart
│   ├── dashboard_screen.dart
│   ├── historial_screen.dart
│   ├── ordenes_screen.dart
│   ├── orden_detalle_screen.dart
│   ├── registrar_cliente_screen.dart
│   ├── registrar_orden_screen.dart
│   ├── repuestos_screen.dart
│   └── tecnicos_screen.dart
│
├── ViewModels/
│   ├── app_providers.dart
│   ├── clientes_view_model.dart
│   ├── dashboard_view_model.dart
│   ├── historial_view_model.dart
│   ├── ordenes_view_model.dart
│   ├── repuestos_view_model.dart
│   ├── tecnicos_view_model.dart
│   └── theme_view_model.dart
│
├── shared/
│   ├── main_shell.dart
│   └── widgets.dart
│
└── main.dart
```

## Requisitos para ejecutar el proyecto

- Flutter SDK instalado.
- Dart SDK compatible con la versión de Flutter.
- Android Studio o Visual Studio Code.
- Android SDK.
- Emulador Android o dispositivo físico con depuración USB habilitada.

## Instalación y ejecución

1. Clonar el repositorio:

```bash
git clone URL_DEL_REPOSITORIO
```

2. Entrar en la carpeta del proyecto:

```bash
cd tu_solution
```

3. Instalar las dependencias:

```bash
flutter pub get
```

4. Generar los archivos de Drift si fuera necesario:

```bash
dart run build_runner build --delete-conflicting-outputs
```

5. Ejecutar la aplicación:

```bash
flutter run
```

## Pruebas recomendadas

Antes de considerar terminada la instalación y validación del proyecto, se recomienda comprobar los siguientes escenarios:

- Registrar un cliente y crear una orden para él.
- Crear una orden utilizando un cliente existente.
- Registrar un dispositivo y comprobar su reutilización mediante el número de serie.
- Intentar crear una segunda orden mientras el dispositivo tenga una orden abierta.
- Asignar y reasignar técnicos.
- Registrar trabajos y comprobar el cálculo de la mano de obra.
- Agregar repuestos a una orden y verificar el descuento de existencias.
- Comprobar que se conserva el precio unitario histórico de los repuestos.
- Consultar el historial de un cliente y de sus dispositivos.
- Cerrar y volver a abrir la aplicación para comprobar la persistencia de los datos.

## Consideraciones

- La aplicación está diseñada para funcionar localmente, sin necesidad de conexión a Internet.
- La información se almacena en el dispositivo mediante SQLite.
- No se establece una moneda específica, ya que el enunciado del proyecto no determina una.
- Los clientes con dispositivos registrados no pueden eliminarse, con el objetivo de preservar la integridad del historial de reparaciones.

## Objetivo del proyecto

Desarrollar una herramienta que facilite la administración de un taller de reparación de equipos electrónicos, centralizando la información de los clientes, sus dispositivos, las reparaciones realizadas, los técnicos responsables y el inventario de repuestos.

El proyecto aplica conceptos de desarrollo móvil, persistencia de datos, gestión de estados, arquitectura de software y operaciones transaccionales.
