import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/session.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/aviso_dialog.dart';
import '../../../core/widgets/dialog_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/search_field.dart';
import '../data/proveedores_repository_impl.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});
  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final _repo = ProveedoresRepositoryImpl();
  List<Map<String, dynamic>> _items = [];
  String _busqueda = '';
  bool _loading = true;
  String? _error;
  bool get _puedeEditar => ['admin', 'almacenista'].contains(AppSession.instance.role);

  List<Map<String, dynamic>> get _filtrados {
    if (_busqueda.trim().isEmpty) return _items;
    final q = _busqueda.trim().toLowerCase();
    return _items.where((p) {
      final nombre = (p['nombre'] ?? '').toString().toLowerCase();
      final contacto = (p['contacto'] ?? '').toString().toLowerCase();
      return nombre.contains(q) || contacto.contains(q);
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
      setState(() => _items = data);
    } catch (e) {
      setState(() => _error = 'No se pudo cargar proveedores: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _desactivar(int id) async {
    try {
      await _repo.desactivar(id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackExito('Proveedor desactivado'));
      }
    } catch (e) {
      if (mounted) {
        await mostrarAvisoError(context, mensaje: 'No se pudo desactivar: $e');
      }
    }
  }

  void _confirmarDesactivar(int id, String nombre) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const DialogHeader(icon: Icons.visibility_off_outlined, text: '¿Desactivar proveedor?', color: kRed),
        content: Text(
          '"$nombre" dejará de aparecer en la lista, pero su historial de compras se conserva. Puedes reactivarlo después desde la base de datos si lo necesitas.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            onPressed: () {
              Navigator.of(context).pop();
              _desactivar(id);
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  void _abrirFormulario() {
    showDialog(context: context, builder: (_) => _ProveedorDialog(onSaved: _load));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _puedeEditar
          ? FloatingActionButton(
              onPressed: _abrirFormulario,
              backgroundColor: kOrange,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: kRed)))
              : Column(
                  children: [
                    SearchField(
                      hintText: 'Buscar por nombre o contacto…',
                      onChanged: (v) => setState(() => _busqueda = v),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: _filtrados.isEmpty
                            ? ListView(children: [
                                SizedBox(
                                  height: 400,
                                  child: _items.isEmpty
                                      ? EmptyState(
                                          icon: Icons.local_shipping_outlined,
                                          titulo: 'Aún no tienes proveedores',
                                          subtitulo: 'Registra tu primer proveedor para empezar a llevar sus datos.',
                                          accionTexto: _puedeEditar ? 'Agregar proveedor' : null,
                                          onAccion: _puedeEditar ? _abrirFormulario : null,
                                        )
                                      : const EmptyState(
                                          icon: Icons.search_off,
                                          titulo: 'Sin resultados',
                                          subtitulo: 'Ningún proveedor coincide con tu búsqueda.',
                                        ),
                                ),
                              ])
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _filtrados.length,
                                itemBuilder: (context, i) {
                                  final p = _filtrados[i];
                                  return Card(
                                    child: ListTile(
                                      title: Text(p['nombre'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                                      subtitle: Text(
                                          '${p['contacto'] ?? ''}${(p['contacto'] ?? '').toString().isNotEmpty && (p['telefono'] ?? '').toString().isNotEmpty ? ' — ' : ''}${p['telefono'] ?? ''}'),
                                      trailing: _puedeEditar
                                          ? IconButton(
                                              icon: const Icon(Icons.visibility_off_outlined, color: kRed),
                                              tooltip: 'Desactivar',
                                              onPressed: () => _confirmarDesactivar(p['id'] as int, p['nombre'] ?? ''),
                                            )
                                          : null,
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

class _ProveedorDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _ProveedorDialog({required this.onSaved});
  @override
  State<_ProveedorDialog> createState() => _ProveedorDialogState();
}

class _ProveedorDialogState extends State<_ProveedorDialog> {
  final _repo = ProveedoresRepositoryImpl();
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _contacto = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _direccion = TextEditingController();
  bool _loading = false;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _repo.crear({
        'nombre': _nombre.text.trim(),
        'contacto': _contacto.text.trim(),
        'telefono': _telefono.text.trim(),
        'correo': _correo.text.trim(),
        'direccion': _direccion.text.trim(),
      });
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        widget.onSaved();
        messenger.showSnackBar(snackExito('Proveedor guardado correctamente'));
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) await mostrarAvisoError(context, mensaje: 'No se pudo guardar: $e');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DialogHeader(icon: Icons.local_shipping_outlined, text: 'Nuevo proveedor'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => validarNombreValido(v, campo: 'El nombre'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contacto,
              decoration: const InputDecoration(labelText: 'Contacto'),
              validator: (v) => validarNombreValido(v, campo: 'El contacto'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              validator: validarTelefonoOpcional,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo'),
              validator: validarCorreoOpcional,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _direccion,
              decoration: const InputDecoration(labelText: 'Dirección'),
              validator: (v) => validarRequerido(v, campo: 'La dirección'),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _loading ? null : _guardar,
          child: _loading
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
