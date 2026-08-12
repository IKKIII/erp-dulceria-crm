import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/session.dart';
import '../../../core/widgets/dialog_header.dart';
import '../data/rh_repository_impl.dart';
import '../domain/usuario.dart';

const _roles = ['admin', 'cajero', 'almacenista'];

/// Solo visible para 'admin' (ver roleModules en core/session.dart).
/// Permite ver/editar el rol de cada usuario y ver cuántas ventas emitió
/// cada uno.
class RhScreen extends StatefulWidget {
  const RhScreen({super.key});
  @override
  State<RhScreen> createState() => _RhScreenState();
}

class _RhScreenState extends State<RhScreen> with SingleTickerProviderStateMixin {
  final _repo = RhRepositoryImpl();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  List<Usuario> _usuarios = [];
  List<Map<String, dynamic>> _ventasPorVendedor = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final usuarios = await _repo.listarUsuarios();
      final ventas = await _repo.ventasPorVendedor();
      setState(() {
        _usuarios = usuarios;
        _ventasPorVendedor = ventas;
      });
    } catch (e) {
      setState(() => _error = 'No se pudo cargar usuarios: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cambiarRol(Usuario u, String nuevoRol) async {
    if (u.id == AppSession.instance.userId && nuevoRol != 'admin') {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const DialogHeader(icon: Icons.warning_amber_rounded, text: '¿Quitarte el rol de admin?', color: kRed),
          content: const Text('Estás a punto de cambiar tu propio rol. Podrías perder acceso a este mismo módulo.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Continuar')),
          ],
        ),
      );
      if (confirmar != true) return;
    }
    try {
      await _repo.actualizarRol(u.id, nuevoRol);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo actualizar el rol: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabs,
          labelColor: kBrown,
          indicatorColor: kOrange,
          tabs: const [Tab(text: 'Usuarios'), Tab(text: 'Ventas por vendedor')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: kRed)))
              : TabBarView(
                  controller: _tabs,
                  children: [
                    RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _usuarios.length,
                        itemBuilder: (context, i) {
                          final u = _usuarios[i];
                          return Card(
                            child: ListTile(
                              title: Text(u.nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                              subtitle: Text(u.correo),
                              trailing: DropdownButton<String>(
                                value: _roles.contains(u.role) ? u.role : null,
                                hint: Text(u.role),
                                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                onChanged: (nuevo) {
                                  if (nuevo != null) _cambiarRol(u, nuevo);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: _load,
                      child: _ventasPorVendedor.isEmpty
                          ? ListView(children: const [
                              Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: Text('Aún no hay ventas registradas.')),
                              ),
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _ventasPorVendedor.length,
                              itemBuilder: (context, i) {
                                final v = _ventasPorVendedor[i];
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.badge_outlined, color: kOrange),
                                    title: Text(v['nombre'] as String,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                                    subtitle: Text('${v['ventas']} ventas'),
                                    trailing: Text(money(v['total']),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: kGreen)),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
