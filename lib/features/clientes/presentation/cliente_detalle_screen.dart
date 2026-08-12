import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/session.dart';
import '../../../core/widgets/dialog_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/interacciones_repository_impl.dart';

const _tiposIconos = {
  'llamada': Icons.call_outlined,
  'visita': Icons.storefront_outlined,
  'correo': Icons.email_outlined,
  'nota': Icons.note_alt_outlined,
};

const _tiposNombres = {
  'llamada': 'Llamada',
  'visita': 'Visita',
  'correo': 'Correo',
  'nota': 'Nota',
};

/// Detalle de un cliente: datos de contacto + historial de interacciones
/// (llamadas, visitas, correos, notas) — cubre el requerimiento de
/// "historial de interacciones" de un CRM.
class ClienteDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> cliente;
  const ClienteDetalleScreen({super.key, required this.cliente});

  @override
  State<ClienteDetalleScreen> createState() => _ClienteDetalleScreenState();
}

class _ClienteDetalleScreenState extends State<ClienteDetalleScreen> {
  final _repo = InteraccionesRepositoryImpl();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  bool get _puedeEditar => ['admin', 'cajero'].contains(AppSession.instance.role);

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
      final data = await _repo.listar(widget.cliente['id'] as int);
      setState(() => _items = data);
    } catch (e) {
      setState(() => _error = 'No se pudieron cargar las interacciones: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _abrirFormulario() {
    showDialog(
      context: context,
      builder: (_) => _InteraccionDialog(clienteId: widget.cliente['id'] as int, onSaved: _load),
    );
  }

  static String _fecha(dynamic v) {
    final s = (v ?? '').toString();
    return s.length >= 16 ? s.substring(0, 16).replaceFirst('T', ' ') : s;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cliente;
    return Scaffold(
      appBar: AppBar(title: Text(c['nombre'] ?? 'Cliente')),
      floatingActionButton: _puedeEditar
          ? FloatingActionButton.extended(
              onPressed: _abrirFormulario,
              backgroundColor: kOrange,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Agregar interacción', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((c['telefono'] ?? '').toString().isNotEmpty)
                      _fila(Icons.phone_outlined, c['telefono']),
                    if ((c['correo'] ?? '').toString().isNotEmpty)
                      _fila(Icons.email_outlined, c['correo']),
                    if ((c['direccion'] ?? '').toString().isNotEmpty)
                      _fila(Icons.location_on_outlined, c['direccion']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Historial de interacciones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: kBrown, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: kRed)))
            else if (_items.isEmpty)
              const SizedBox(
                height: 260,
                child: EmptyState(
                  icon: Icons.history_outlined,
                  titulo: 'Sin interacciones registradas',
                  subtitulo: 'Registra llamadas, visitas, correos o notas de seguimiento con este cliente.',
                ),
              )
            else
              ..._items.map((i) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kYellow,
                        child: Icon(_tiposIconos[i['tipo']] ?? Icons.note_outlined, color: kBrown, size: 20),
                      ),
                      title: Text(_tiposNombres[i['tipo']] ?? i['tipo'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                      subtitle: Text('${i['descripcion'] ?? ''}\n${_fecha(i['fecha'])}'),
                      isThreeLine: true,
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _fila(IconData icono, dynamic texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icono, size: 18, color: kBrown),
        const SizedBox(width: 10),
        Expanded(child: Text('$texto')),
      ]),
    );
  }
}

class _InteraccionDialog extends StatefulWidget {
  final int clienteId;
  final VoidCallback onSaved;
  const _InteraccionDialog({required this.clienteId, required this.onSaved});
  @override
  State<_InteraccionDialog> createState() => _InteraccionDialogState();
}

class _InteraccionDialogState extends State<_InteraccionDialog> {
  final _repo = InteraccionesRepositoryImpl();
  final _formKey = GlobalKey<FormState>();
  final _descripcion = TextEditingController();
  String _tipo = 'nota';
  bool _loading = false;
  String? _error;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repo.crear({
        'cliente_id': widget.clienteId,
        'tipo': _tipo,
        'descripcion': _descripcion.text.trim(),
        'creado_por': AppSession.instance.userId,
      });
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      setState(() => _error = 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DialogHeader(icon: Icons.history_edu_outlined, text: 'Nueva interacción'),
      content: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: _tiposNombres.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _tipo = v ?? 'nota'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descripcion,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descripción'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: kRed))),
        ]),
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
