import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/session.dart';
import '../../../core/error_utils.dart';
import '../../../core/csv_export.dart';
import '../../../core/widgets/aviso_dialog.dart';
import '../../../core/widgets/dialog_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/search_field.dart';
import '../data/compras_repository_impl.dart';

class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});
  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  final _repo = ComprasRepositoryImpl();
  List<Map<String, dynamic>> _compras = [];
  String _busqueda = '';
  DateTimeRange? _rangoFecha;
  bool _loading = true;
  String? _error;
  bool get _puedeEditar => ['admin', 'almacenista'].contains(AppSession.instance.role);

  List<Map<String, dynamic>> get _filtradas {
    var lista = _compras;
    if (_rangoFecha != null) {
      final desde = _rangoFecha!.start;
      final hasta = _rangoFecha!.end.add(const Duration(days: 1));
      lista = lista.where((c) {
        final fecha = DateTime.tryParse((c['fecha'] ?? '').toString());
        if (fecha == null) return false;
        return fecha.isAfter(desde) && fecha.isBefore(hasta);
      }).toList();
    }
    if (_busqueda.trim().isEmpty) return lista;
    final q = _busqueda.trim().toLowerCase();
    return lista.where((c) {
      final proveedor = (c['proveedores'] is Map) ? (c['proveedores']['nombre'] ?? '').toString() : '';
      return proveedor.toLowerCase().contains(q) || '${c['id']}'.contains(q);
    }).toList();
  }

  Future<void> _elegirRangoFecha() async {
    final ahora = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(ahora.year - 2),
      lastDate: DateTime(ahora.year + 1),
      initialDateRange: _rangoFecha,
      helpText: 'Filtrar compras por fecha',
    );
    if (rango != null) setState(() => _rangoFecha = rango);
  }

  void _limpiarRangoFecha() => setState(() => _rangoFecha = null);

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
      setState(() => _compras = data);
    } catch (e) {
      setState(() => _error = 'No se pudo cargar compras: ' + friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _nuevaCompra() {
    showDialog(context: context, builder: (_) => _CompraDialog(onSaved: _load));
  }

  Future<void> _exportarCsv() async {
    try {
      await exportarCsv(
        nombreArchivo: 'compras',
        encabezados: const ['# Compra', 'Proveedor', 'Fecha', 'Total'],
        filas: _filtradas
            .map((c) => [
                  c['id'],
                  (c['proveedores'] is Map) ? c['proveedores']['nombre'] : '',
                  c['fecha'],
                  c['total'],
                ])
            .toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          snackExito('Copiado al portapapeles. Pégalo en Excel o Google Sheets.'),
        );
      }
    } catch (e) {
      if (mounted) {
        await mostrarAvisoError(context, mensaje: friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _puedeEditar
          ? FloatingActionButton.extended(
              onPressed: _nuevaCompra,
              backgroundColor: kOrange,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nueva compra', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: kRed)))
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SearchField(
                            hintText: 'Buscar por proveedor o # de compra…',
                            onChanged: (v) => setState(() => _busqueda = v),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Filtrar por fecha',
                          icon: Icon(Icons.calendar_month_outlined,
                              color: _rangoFecha != null ? kOrange : kBrown),
                          onPressed: _elegirRangoFecha,
                        ),
                        IconButton(
                          tooltip: 'Exportar a CSV',
                          icon: const Icon(Icons.file_download_outlined, color: kBrown),
                          onPressed: _compras.isEmpty ? null : _exportarCsv,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    if (_rangoFecha != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(
                            label: Text(
                              '${_rangoFecha!.start.day}/${_rangoFecha!.start.month}/${_rangoFecha!.start.year} — '
                              '${_rangoFecha!.end.day}/${_rangoFecha!.end.month}/${_rangoFecha!.end.year}',
                            ),
                            onDeleted: _limpiarRangoFecha,
                            deleteIcon: const Icon(Icons.close, size: 16),
                          ),
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: _filtradas.isEmpty
                            ? ListView(children: [
                                SizedBox(
                                  height: 400,
                                  child: _compras.isEmpty
                                      ? EmptyState(
                                          icon: Icons.shopping_cart_outlined,
                                          titulo: 'Aún no hay compras registradas',
                                          subtitulo: 'Registra tu primera compra para empezar a surtir tu inventario.',
                                          accionTexto: _puedeEditar ? 'Nueva compra' : null,
                                          onAccion: _puedeEditar ? _nuevaCompra : null,
                                        )
                                      : const EmptyState(
                                          icon: Icons.search_off,
                                          titulo: 'Sin resultados',
                                          subtitulo: 'Ninguna compra coincide con tu búsqueda.',
                                        ),
                                ),
                              ])
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _filtradas.length,
                                itemBuilder: (context, i) {
                                  final c = _filtradas[i];
                                  final proveedor = (c['proveedores'] is Map) ? c['proveedores']['nombre'] : '—';
                                  final fecha = (c['fecha'] ?? '').toString();
                                  return Card(
                                    child: ListTile(
                                      title: Text('Compra #${c['id']} — $proveedor',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                                      subtitle: Text(fecha.length >= 16 ? fecha.substring(0, 16) : fecha),
                                      trailing: Text(money(c['total']),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: kGreen)),
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

class _CompraDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _CompraDialog({required this.onSaved});
  @override
  State<_CompraDialog> createState() => _CompraDialogState();
}

class _CompraDialogState extends State<_CompraDialog> {
  final _repo = ComprasRepositoryImpl();
  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _productos = [];
  int? _proveedorId;
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final prov = await _repo.catalogoProveedores();
      final prod = await _repo.catalogoProductos();
      setState(() {
        _proveedores = prov;
        _productos = prod;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) await mostrarAvisoError(context, mensaje: 'No se pudo cargar catálogos: ' + friendlyError(e));
    }
  }

  /// Un producto es compatible con el proveedor elegido si no tiene
  /// proveedor asignado (proveedor_id null) o si su proveedor coincide
  /// exactamente con el seleccionado en el formulario.
  bool _compatibleConProveedor(Map<String, dynamic> producto) {
    final provProducto = producto['proveedor_id'] as int?;
    if (provProducto == null || _proveedorId == null) return true;
    return provProducto == _proveedorId;
  }

  /// Productos que se pueden agregar como un ítem NUEVO: compatibles con
  /// el proveedor elegido y que todavía no estén usados en otro renglón
  /// de esta misma compra (evita repetir producto).
  List<Map<String, dynamic>> get _productosDisponiblesParaAgregar {
    final usados = _items.map((i) => i['producto_id']).toSet();
    return _productos.where((p) => !usados.contains(p['id']) && _compatibleConProveedor(p)).toList();
  }

  /// Opciones válidas para el dropdown de un renglón específico: las
  /// disponibles para agregar, más el producto que ya tiene seleccionado
  /// ese mismo renglón (para no perderlo de las opciones al construir).
  List<Map<String, dynamic>> _opcionesParaItem(int idx) {
    final productoActual = _items[idx]['producto_id'];
    final usadosPorOtros = _items
        .asMap()
        .entries
        .where((e) => e.key != idx)
        .map((e) => e.value['producto_id'])
        .toSet();
    return _productos
        .where((p) => (p['id'] == productoActual || !usadosPorOtros.contains(p['id'])) && _compatibleConProveedor(p))
        .toList();
  }

  Future<void> _agregarItem() async {
    final disponibles = _productosDisponiblesParaAgregar;
    if (disponibles.isEmpty) {
      final motivo = _proveedorId != null
          ? 'Ya agregaste todos los productos disponibles para este proveedor, o no hay ninguno compatible con él.'
          : 'Ya agregaste todos los productos disponibles, o no queda ninguno por agregar.';
      await mostrarAvisoFaltante(context, mensaje: motivo);
      return;
    }
    setState(() => _items.add({
          'producto_id': disponibles.first['id'],
          'cantidad': 1,
          'costo_unitario': (disponibles.first['costo_promedio'] as num).toDouble(),
        }));
  }

  /// Al cambiar de proveedor, quita de la compra los productos que ya no
  /// sean compatibles (los que pertenecen a otro proveedor distinto).
  Future<void> _cambiarProveedor(int? nuevoProveedorId) async {
    setState(() => _proveedorId = nuevoProveedorId);
    final aQuitar = _items.where((i) {
      final producto = _productos.firstWhere(
        (p) => p['id'] == i['producto_id'],
        orElse: () => <String, dynamic>{},
      );
      return producto.isNotEmpty && !_compatibleConProveedor(producto);
    }).toList();
    if (aQuitar.isNotEmpty) {
      setState(() => _items.removeWhere((i) => aQuitar.contains(i)));
      if (mounted) {
        await mostrarAvisoFaltante(
          context,
          mensaje:
              'Se quitaron ${aQuitar.length} producto(s) de la lista porque pertenecen a otro proveedor distinto al que elegiste.',
        );
      }
    }
  }

  Future<void> _guardar() async {
    if (_proveedorId == null) {
      await mostrarAvisoFaltante(context, mensaje: 'Selecciona un proveedor antes de continuar.');
      return;
    }
    if (_items.isEmpty) {
      await mostrarAvisoFaltante(context, mensaje: 'Agrega al menos un producto a la compra.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await _repo.registrarCompra(proveedorId: _proveedorId!, items: _items);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        widget.onSaved();
        messenger.showSnackBar(snackExito('Compra registrada correctamente'));
      }
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) await mostrarAvisoError(context, mensaje: 'No se pudo registrar la compra: ' + friendlyError(e));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DialogHeader(icon: Icons.shopping_cart_outlined, text: 'Nueva compra'),
      content: SizedBox(
        width: dialogWidth(context),
        child: _loading
            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _proveedorId,
                    decoration: const InputDecoration(labelText: 'Proveedor'),
                    items: _proveedores
                        .map((p) => DropdownMenuItem(value: p['id'] as int, child: Text(p['nombre'])))
                        .toList(),
                    onChanged: (v) => _cambiarProveedor(v),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _productos.isEmpty ? null : _agregarItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar producto'),
                    ),
                  ),
                  ..._items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: item['producto_id'] as int,
                            decoration: const InputDecoration(labelText: 'Producto'),
                            items: _opcionesParaItem(idx)
                                .map((p) => DropdownMenuItem(
                                    value: p['id'] as int,
                                    child: Text(p['nombre'], overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) => setState(() => item['producto_id'] = v),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: '${item['cantidad']}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Cant.'),
                            onChanged: (v) => item['cantidad'] = int.tryParse(v) ?? 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: '${item['costo_unitario']}',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Costo'),
                            onChanged: (v) => item['costo_unitario'] = double.tryParse(v) ?? 0,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: kRed, size: 18),
                          onPressed: () => setState(() => _items.removeAt(idx)),
                        ),
                      ]),
                    );
                  }),
                ]),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Registrar compra'),
        ),
      ],
    );
  }
}
