
ERP Dulceria - CRM

Aplicacion movil de gestion empresarial (ERP/CRM) desarrollada en Flutter, con backend en Supabase (PostgreSQL). Proyecto para la materia de Programacion Movil, UPFIM.

Tecnologias
Flutter / Dart
Supabase (PostgreSQL, Auth, RLS, funciones RPC)
Arquitectura por capas (feature-first): domain, data, presentation
Librerias principales
supabase_flutter - conexion con el backend
shared_preferences - persistencia local
google_fonts - tipografia
fl_chart - graficas
intl - formato de fecha/moneda en espanol
pdf y printing - generacion y exportacion de reportes en PDF
Estructura del proyecto
lib/
 |-- core/              (validadores y widgets compartidos)
 `-- features/
      |-- auth
      |-- home
      |-- dashboard
      |-- productos
      |-- clientes
      |-- proveedores
      |-- compras
      |-- ventas
      |-- facturacion    (cotizaciones)
      |-- finanzas
      |-- reportes
      |-- rh
      `-- auditoria

Cada modulo sigue el patron domain / data / presentation, con inversion de dependencias via el patron Repositorio (Clean Architecture simplificada).

Modulos clave
Autenticacion (auth) via Supabase Auth
Aislamiento multi-empresa mediante empresa_id, triggers y RLS
Registro de ventas y compras con funciones RPC transaccionales (stock, costo promedio, movimientos de inventario)
Facturacion (cotizaciones) para clientes
Reportes exportables a PDF
Auditoria de acciones del sistema
Como correr el proyecto
Instalar dependencias:
flutter pub get
Crear un archivo env.json en la raiz del proyecto con las credenciales de Supabase (no incluido en el repositorio por seguridad).
Correr la app:
flutter run --dart-define-from-file=env.json
Autores

Proyecto desarrollado en equipo para la materia de Programacion Movil, UPFIM. Docente: Ing. Daniel Hernandez Perez.
