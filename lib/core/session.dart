/// Sesión simple en memoria — sin gestor de estado externo.
/// Se llena una vez al iniciar sesión (HomeShell) y se limpia al salir.
class AppSession {
  AppSession._();
  static final AppSession instance = AppSession._();
  String? userId;
  String? role; // 'admin' | 'cajero' | 'almacenista'
  String? nombre;
  String? correo;
  String? empresa;
  bool get isAdmin => role == 'admin';
  void clear() {
    userId = null;
    role = null;
    nombre = null;
    correo = null;
    empresa = null;
  }
}

/// Qué apartados puede ver cada rol.
const Map<String, List<String>> roleModules = {
  'admin': [
    'dashboard', 'ventas', 'inventario', 'compras', 'proveedores',
    'clientes', 'finanzas', 'facturacion', 'reportes', 'rh', 'auditoria',
  ],
  'cajero': ['ventas', 'inventario', 'clientes', 'facturacion'],
  'almacenista': ['inventario', 'proveedores', 'compras'],
};

const Map<String, String> moduleNames = {
  'dashboard': 'Dashboard',
  'inventario': 'Inventario',
  'ventas': 'Ventas',
  'clientes': 'Clientes',
  'proveedores': 'Proveedores',
  'compras': 'Compras',
  'finanzas': 'Finanzas',
  'reportes': 'Reportes',
  'facturacion': 'Facturación',
  'rh': 'Usuarios (RH)',
  'auditoria': 'Auditoría',
};
