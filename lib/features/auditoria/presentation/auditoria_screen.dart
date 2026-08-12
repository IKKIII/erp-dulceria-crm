import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/dialog_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/error_utils.dart';
import '../data/auditoria_repository_impl.dart';
import '../domain/audit_entry.dart';

const Map<String, String> _nombreTabla = {
  'productos': 'Productos',
  'clientes': 'Clientes',
  'proveedores': 'Proveedores',
  'ventas': 'Ventas',
  'compras': 'Compras',
  'finanzas': 'Finanzas',
  'profiles': 'Usuarios',
};

const Map<String, Color> _colorAccion = {
  'INSERT': kGreen,
  'UPDATE': kOrange,
  'DELETE': kRed,
};

const Map<String, String> _textoAccion = {
  'INSERT': 'Creó',
  'UPDATE': 'Editó',
  'DELETE': 'Eliminó',
};

/// Solo visible para 'admin' (ver roleModules en core/session.dart).
/// Muestra el historial de cambios en las tablas de negocio: quién hizo
/// qué y cuándo, alimentado por los triggers de migracion_3_auditoria.sql.
class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});
  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  final _repo = AuditoriaRepositoryImpl();
  List<AuditEntry> _entradas = [];
  String _busqueda = '';
  bool _loading = true;
  String? _error;

  List<AuditEntry> get _filtradas {
    if (_busqueda.trim().isEmpty) return _entradas;
    final q = _busqueda.trim().toLowerCase();
    return _entradas.where((e) {
      final tabla = (_nombreTabla[e.tabla] ?? e.tabla).toLowerCase();
      final usuario = (e.usuarioNombre ?? '').toLowerCase();
      return tabla.contains(q) || usuario.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.listar();
      setState(() => _entradas = data);
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _verDetalle(AuditEntry e) {
    showDialog(context: context, builder: (_) => _DetalleAuditDialog(entrada: e));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: kRed)))
              : Column(
                  children: [
                    SearchField(
                      hintText: 'Buscar por tabla o usuario…',
                      onChanged: (v) => setState(() => _busqueda = v),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: _filtradas.isEmpty
                            ? ListView(children: [
                                SizedBox(
                                  height: 400,
                                  child: _entradas.isEmpty
                                      ? const EmptyState(
                                          icon: Icons.history_outlined,
                                          titulo: 'Aún no hay actividad registrada',
                                          subtitulo: 'Aquí verás quién crea, edita o elimina información en el sistema.',
                                        )
                                      : const EmptyState(
                                          icon: Icons.search_off,
                                          titulo: 'Sin resultados',
                                          subtitulo: 'Ningún registro coincide con tu búsqueda.',
                                        ),
                                ),
                              ])
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _filtradas.length,
                                itemBuilder: (context, i) {
                                  final e = _filtradas[i];
                                  final color = _colorAccion[e.accion] ?? kBrown;
                                  final texto = _textoAccion[e.accion] ?? e.accion;
                                  final tabla = _nombreTabla[e.tabla] ?? e.tabla;
                                  final fecha = e.fecha;
                                  final fechaStr =
                                      '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
                                  return Card(
                                    child: ListTile(
                                      onTap: () => _verDetalle(e),
                                      leading: CircleAvatar(
                                        backgroundColor: color.withValues(alpha: 0.15),
                                        child: Icon(
                                          e.accion == 'INSERT'
                                              ? Icons.add
                                              : e.accion == 'DELETE'
                                                  ? Icons.delete_outline
                                                  : Icons.edit_outlined,
                                          color: color,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text('$texto en $tabla',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                                      subtitle: Text('${e.usuarioNombre ?? 'Usuario desconocido'}  ·  $fechaStr'),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _DetalleAuditDialog extends StatelessWidget {
  final AuditEntry entrada;
  const _DetalleAuditDialog({required this.entrada});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: DialogHeader(
        icon: Icons.history_outlined,
        text: '${_textoAccion[entrada.accion] ?? entrada.accion} — ${_nombreTabla[entrada.tabla] ?? entrada.tabla}',
      ),
      content: SizedBox(
        width: dialogWidth(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: ${entrada.usuarioNombre ?? 'Desconocido'}'),
              Text('Registro ID: ${entrada.registroId}'),
              const SizedBox(height: 12),
              if (entrada.datosAnteriores != null) ...[
                const Text('Antes:', style: TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                Text(entrada.datosAnteriores.toString(), style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
              ],
              if (entrada.datosNuevos != null) ...[
                const Text('Después:', style: TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                Text(entrada.datosNuevos.toString(), style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}
