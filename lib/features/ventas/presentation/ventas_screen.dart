import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/session.dart';
import '../../../core/error_utils.dart';
import '../../../core/csv_export.dart';
import '../../../core/widgets/dialog_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/search_field.dart';
import '../data/ventas_repository_impl.dart';

/// Muestra un diálogo emergente llamativo (icono + color + título) en vez
/// de un simple texto. Se usa tanto para errores del servidor (stock
/// insuficiente, etc.) como para avisos de validación del formulario.
Future<void> _mostrarAviso(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required IconData icono,
  required Color color,
}) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: DialogHeader(icon: icono, text: titulo, color: color),
      content: Text(mensaje),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: color),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});
  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final _repo = VentasRepositoryImpl();
  List<Map<String, dynamic>> _ventas = [];
  String _busqueda = '';
  DateTimeRange? _rangoFecha;
  bool _loading = true;
  String? _error;
  bool get _puedeEditar => ['admin', 'cajero'].contains(AppSession.instance.role);

  List<Map<String, dynamic>> get _filtradas {
    var lista = _ventas;
    if (_rangoFecha != null) {
      final desde = _rangoFecha!.start;
      final hasta = _rangoFecha!.end.add(const Duration(days: 1));
      lista = lista.where((v) {
        final fecha = DateTime.tryParse((v['fecha'] ?? '').toString());
        if (fecha == null) return false;
        return fecha.isAfter(desde) && fecha.isBefore(hasta);
      }).toList();
    }
    if (_busqueda.trim().isEmpty) return lista;
    final q = _busqueda.trim().toLowerCase();
    return lista.where((v) {
      final cliente = (v['clientes'] is Map) ? (v['clientes']['nombre'] ?? '').toString() : 'público general';
      return cliente.toLowerCase().contains(q) || '${v['id']}'.contains(q);
    }).toList();
  }

  Future<void> _elegirRangoFecha() async {
    final ahora = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(ahora.year - 2),
      lastDate: DateTime(ahora.year + 1),
      initialDateRange: _rangoFecha,
      helpText: 'Filtrar ventas por fecha',
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
      setState(() => _ventas = data);
    } catch (e) {
      setState(() => _error = 'No se pudo cargar ventas: ${friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _nuevaVenta() {
    showDialog(context: context, builder: (_) => _VentaDialog(onSaved: _ventaRegistrada));
  }

  /// Se llama cuando una venta se guardó con éxito: recarga la lista y
  /// muestra una notificación verde flotante, bien visible.
  Future<void> _ventaRegistrada() async {
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Venta registrada correctamente',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _verDetalle(Map<String, dynamic> venta) {
    showDialog(context: context, builder: (_) => _DetalleVentaDialog(venta: venta, repo: _repo));
  }

  Future<void> _exportarCsv() async {
    try {
      await exportarCsv(
        nombreArchivo: 'ventas',
        encabezados: const ['# Venta', 'Cliente', 'Vendedor', 'Fecha', 'Total'],
        filas: _filtradas
            .map((v) => [
                  v['id'],
                  (v['clientes'] is Map) ? v['clientes']['nombre'] : 'Público General',
                  (v['profiles'] is Map) ? v['profiles']['nombre'] : '',
                  v['fecha'],
                  v['total'],
                ])
            .toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copiado al portapapeles. Pégalo en Excel o Google Sheets.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _puedeEditar
          ? FloatingActionButton.extended(
              onPressed: _nuevaVenta,
              backgroundColor: kOrange,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nueva venta', style: TextStyle(color: Colors.white)),
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
                            hintText: 'Buscar por cliente o # de venta…',
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
                          onPressed: _ventas.isEmpty ? null : _exportarCsv,
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
                                  child: _ventas.isEmpty
                                      ? EmptyState(
                                          icon: Icons.point_of_sale_outlined,
                                          titulo: 'Aún no hay ventas registradas',
                                          subtitulo: 'Registra tu primera venta para empezar a ver tus ingresos aquí.',
                                          accionTexto: _puedeEditar ? 'Nueva venta' : null,
                                          onAccion: _puedeEditar ? _nuevaVenta : null,
                                        )
                                      : const EmptyState(
                                          icon: Icons.search_off,
                                          titulo: 'Sin resultados',
                                          subtitulo: 'Ninguna venta coincide con tu búsqueda.',
                                        ),
                                ),
                              ])
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _filtradas.length,
                                itemBuilder: (context, i) {
                                  final v = _filtradas[i];
                                  final cliente = (v['clientes'] is Map) ? v['clientes']['nombre'] : 'Público General';
                                  final vendedor = (v['profiles'] is Map) ? v['profiles']['nombre'] : null;
                                  final fecha = (v['fecha'] ?? '').toString();
                                  return Card(
                                    child: ListTile(
                                      onTap: () => _verDetalle(v),
                                      title: Text('Venta #${v['id']} — $cliente',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                                      subtitle: Text(
                                        [
                                          fecha.length >= 16 ? fecha.substring(0, 16) : fecha,
                                          if (vendedor != null) 'Vendió: $vendedor',
                                        ].join('  ·  '),
                                      ),
                                      trailing: Text(money(v['total']),
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

/// Muestra el detalle (productos, cantidades, importes) de una venta ya
/// registrada. Requiere que venta_detalle tenga columnas venta_id,
/// producto_id, cantidad, precio_unitario — ajusta el repositorio si tu
/// esquema usa otros nombres.
class _DetalleVentaDialog extends StatefulWidget {
  final Map<String, dynamic> venta;
  final VentasRepositoryImpl repo;
  const _DetalleVentaDialog({required this.venta, required this.repo});
  @override
  State<_DetalleVentaDialog> createState() => _DetalleVentaDialogState();
}

class _DetalleVentaDialogState extends State<_DetalleVentaDialog> {
  List<Map<String, dynamic>>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final items = await widget.repo.obtenerDetalle(widget.venta['id'] as int);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo cargar el detalle: ${friendlyError(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cliente = (widget.venta['clientes'] is Map) ? widget.venta['clientes']['nombre'] : 'Público General';
    return AlertDialog(
      title: DialogHeader(icon: Icons.receipt_long_outlined, text: 'Venta #${widget.venta['id']} — $cliente'),
      content: SizedBox(
        width: 380,
        child: _error != null
            ? Text(_error!, style: const TextStyle(color: kRed))
            : _items == null
                ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._items!.map((it) {
                        final nombre = it['producto_nombre'] ?? 'Producto';
                        final cant = it['cantidad'];
                        final precio = it['precio_unitario'];
                        return ListTile(
                          dense: true,
                          title: Text('$nombre'),
                          subtitle: Text('Cantidad: $cant'),
                          trailing: Text(money(precio)),
                        );
                      }),
                      const Divider(),
                      ListTile(
                        dense: true,
                        title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(money(widget.venta['total']),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: kGreen)),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}

class _VentaDialog extends StatefulWidget {
  final Future<void> Function() onSaved;
  const _VentaDialog({required this.onSaved});
  @override
  State<_VentaDialog> createState() => _VentaDialogState();
}

class _VentaDialogState extends State<_VentaDialog> {
  final _repo = VentasRepositoryImpl();
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _productos = [];
  int? _clienteId;
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _guardando = false;
  String? _errorCarga;

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final cli = await _repo.catalogoClientes();
      final prod = await _repo.catalogoProductosConStock();
      setState(() {
        _clientes = cli;
        _productos = prod;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorCarga = 'No se pudo cargar catálogos: ${friendlyError(e)}';
        _loading = false;
      });
    }
  }

  void _agregarItem() {
    if (_productos.isEmpty) return;
    setState(() => _items.add({'producto_id': _productos.first['id'], 'cantidad': 1}));
  }

  Future<void> _guardar() async {
    if (_items.isEmpty) {
      await _mostrarAviso(
        context,
        titulo: 'Falta información',
        mensaje: 'Agrega al menos un producto a la venta antes de continuar.',
        icono: Icons.info_outline,
        color: kOrange,
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await _repo.registrarVenta(clienteId: _clienteId, items: _items);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      final mensaje = friendlyError(e);
      final esStock = mensaje.toLowerCase().contains('stock insuficiente');
      if (mounted) {
        await _mostrarAviso(
          context,
          titulo: esStock ? 'Stock insuficiente' : 'No se pudo registrar la venta',
          mensaje: mensaje,
          icono: esStock ? Icons.inventory_2_outlined : Icons.error_outline,
          color: kRed,
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DialogHeader(icon: Icons.point_of_sale_outlined, text: 'Nueva venta'),
      content: SizedBox(
        width: dialogWidth(context),
        child: _loading
            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
            : _errorCarga != null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_errorCarga!, style: const TextStyle(color: kRed)),
                  )
                : _productos.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No hay productos con stock disponible.'),
                      )
                    : SingleChildScrollView(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: _clienteId,
                            decoration: const InputDecoration(labelText: 'Cliente (opcional)'),
                            items: _clientes
                                .map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['nombre'])))
                                .toList(),
                            onChanged: (v) => setState(() => _clienteId = v),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _agregarItem,
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
                                    items: _productos
                                        .map((p) => DropdownMenuItem(
                                            value: p['id'] as int,
                                            child: Text('${p['nombre']} (${p['stock']})', overflow: TextOverflow.ellipsis)))
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
              : const Text('Registrar venta'),
        ),
      ],
    );
  }
}
