import 'package:flutter/material.dart';
import '../../../core/supabase_client.dart';
import '../../../core/theme.dart';
import '../../../core/session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../proveedores/presentation/proveedores_screen.dart';
import '../../productos/presentation/productos_screen.dart';
import '../../compras/presentation/compras_screen.dart';
import '../../ventas/presentation/ventas_screen.dart';
import '../../clientes/presentation/clientes_screen.dart';
import '../../finanzas/presentation/finanzas_screen.dart';
import '../../reportes/presentation/reportes_screen.dart';
import '../../facturacion/presentation/cotizaciones_screen.dart';
import '../../rh/presentation/rh_screen.dart';
import '../../auditoria/presentation/auditoria_screen.dart';

const Map<String, IconData> _modIcons = {
  'dashboard': Icons.dashboard_outlined,
  'inventario': Icons.inventory_2_outlined,
  'ventas': Icons.point_of_sale_outlined,
  'clientes': Icons.people_outline,
  'proveedores': Icons.local_shipping_outlined,
  'compras': Icons.shopping_cart_outlined,
  'finanzas': Icons.account_balance_outlined,
  'reportes': Icons.picture_as_pdf_outlined,
  'facturacion': Icons.receipt_long_outlined,
  'rh': Icons.badge_outlined,
  'auditoria': Icons.history_outlined,
};

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _loading = true;
  String _current = 'dashboard';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      var rows = await supabase.from('profiles').select().eq('id', uid);
      if (rows.isEmpty) {
        // Login con Google (u otro proveedor) que nunca pasó por SetupScreen:
        // creamos el perfil aquí mismo con datos de la cuenta, rol admin
        // por default.
        final user = supabase.auth.currentUser;
        final nuevoPerfil = {
          'id': uid,
          'nombre': (user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'] ?? user?.email ?? 'Usuario')
              as String,
          'correo': user?.email ?? '',
          'role': 'admin',
          'empresa': 'Mi Empresa',
        };
        try {
          await supabase.from('profiles').insert(nuevoPerfil);
        } on PostgrestException catch (e) {
          // 23505 = llave duplicada: el perfil en realidad ya existía (el
          // SELECT de arriba no llegó a verlo a tiempo, un caso raro de
          // sincronización justo después de iniciar sesión). No es un
          // error real — seguimos y lo volvemos a leer abajo.
          if (e.code != '23505') rethrow;
        }
        rows = await supabase.from('profiles').select().eq('id', uid);
      }
      final row = rows.first;
      AppSession.instance.userId = uid;
      AppSession.instance.role = row['role'] as String?;
      AppSession.instance.nombre = row['nombre'] as String?;
      AppSession.instance.correo = row['correo'] as String?;
      AppSession.instance.empresa = row['empresa'] as String?;
      final mods = roleModules[AppSession.instance.role] ?? const ['dashboard'];
      _current = mods.isNotEmpty ? mods.first : 'dashboard';
    } catch (e) {
      _error = 'No se pudo cargar tu perfil: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _salir() async {
    await supabase.auth.signOut();
    AppSession.instance.clear();
  }

  Widget _body() {
    switch (_current) {
      case 'dashboard':
        return const DashboardScreen();
      case 'inventario':
        return const ProductosScreen();
      case 'ventas':
        return const VentasScreen();
      case 'clientes':
        return const ClientesScreen();
      case 'proveedores':
        return const ProveedoresScreen();
      case 'compras':
        return const ComprasScreen();
      case 'finanzas':
        return const FinanzasScreen();
      case 'reportes':
        return const ReportesScreen();
      case 'facturacion':
        return const CotizacionesScreen();
      case 'rh':
        return const RhScreen();
      case 'auditoria':
        return const AuditoriaScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: kRed)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _salir, child: const Text('Volver a intentar / salir')),
              ],
            ),
          ),
        ),
      );
    }

    final mods = roleModules[AppSession.instance.role] ?? const ['dashboard'];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppSession.instance.empresa ?? 'ERP Dulcería'),
        actions: [
          IconButton(
            tooltip: 'Salir',
            icon: const Icon(Icons.logout),
            onPressed: _salir,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppSession.instance.empresa ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppSession.instance.role ?? ''} · ${AppSession.instance.correo ?? ''}',
                      style: TextStyle(fontSize: 12, color: kBrown.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: mods
                      .map(
                        (m) => ListTile(
                          leading: Icon(_modIcons[m], color: _current == m ? kOrange : kBrown),
                          title: Text(
                            moduleNames[m] ?? m,
                            style: TextStyle(
                              fontWeight: _current == m ? FontWeight.bold : FontWeight.normal,
                              color: kBrown,
                            ),
                          ),
                          selected: _current == m,
                          selectedTileColor: Colors.white,
                          onTap: () {
                            setState(() => _current = m);
                            Navigator.of(context).pop();
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const Divider(height: 1),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier,
                builder: (context, mode, _) {
                  final esOscuro = mode == ThemeMode.dark;
                  return SwitchListTile(
                    secondary: Icon(esOscuro ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: kBrown),
                    title: const Text('Modo oscuro', style: TextStyle(color: kBrown)),
                    value: esOscuro,
                    onChanged: (v) => setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: _body(),
    );
  }
}
