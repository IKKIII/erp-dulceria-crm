import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme.dart';
import '../../../core/session.dart';
import '../../../core/widgets/dialog_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/search_field.dart';
import '../data/facturacion_repository_impl.dart';
import '../domain/cotizacion.dart';

class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({super.key});
  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> with SingleTickerProviderStateMixin {
  final _repo = FacturacionRepositoryImpl();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  List<Cotizacion> _cotizaciones = [];
  List<Map<String, dynamic>> _ventas = [];
  String _busquedaCotizaciones = '';
  String _busquedaVentas = '';
  bool _loading = true;
  String? _error;
  bool _generando = false;

  List<Cotizacion> get _cotizacionesFiltradas {
    if (_busquedaCotizaciones.trim().isEmpty) return _cotizaciones;
    final q = _busquedaCotizaciones.trim().toLowerCase();
    return _cotizaciones
        .where((c) => c.clienteNombre.toLowerCase().contains(q) || '${c.id}'.contains(q))
        .toList();
  }

  List<Map<String, dynamic>> get _ventasFiltradas {
    if (_busquedaVentas.trim().isEmpty) return _ventas;
    final q = _busquedaVentas.trim().toLowerCase();
    return _ventas.where((v) {
      final cliente = (v['clientes'] is Map) ? (v['clientes']['nombre'] ?? '').toString() : 'público general';
      return cliente.toLowerCase().contains(q) || '${v['id']}'.contains(q);
    }).toList();
  }

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
      final cots = await _repo.listarCotizaciones();
      final ventas = await _repo.ventasFacturables();
      setState(() {
        _cotizaciones = cots;
        _ventas = ventas;
      });
    } catch (e) {
      setState(() => _error = 'No se pudo cargar facturación: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _nuevaCotizacion() {
    showDialog(context: context, builder: (_) => _CotizacionDialog(onSaved: _load));
  }

  Future<void> _generarPrefactura(Cotizacion c) async {
    setState(() => _generando = true);
    try {
      final items = await _repo.detalleCotizacion(c.id!);
      final bytes = await _pdfPrefactura(c: c, items: items);
      await Printing.sharePdf(bytes: bytes, filename: 'Prefactura_${c.id}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo generar la prefactura: $e')));
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  Future<void> _generarFactura(Map<String, dynamic> venta) async {
    setState(() => _generando = true);
    try {
      final datos = await _repo.obtenerVentaParaFactura(venta['id'] as int);
      final bytes = await _pdfFactura(datos: datos);
      await Printing.sharePdf(bytes: bytes, filename: 'Factura_Venta_${venta['id']}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No se pudo generar la factura: $e\n\nSi tu tabla venta_detalle usa otros nombres de '
                'columna, avísame para ajustar la consulta.')));
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  Future<Uint8List> _pdfPrefactura({required Cotizacion c, required List<Map<String, dynamic>> items}) async {
    const brown = PdfColor.fromInt(0xFF8B6F47);
    const orange = PdfColor.fromInt(0xFFFFB347);
    final empresa = AppSession.instance.empresa ?? 'ERP Dulcería';
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(empresa, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brown)),
        pw.Text('PREFACTURA / COTIZACIÓN', style: pw.TextStyle(fontSize: 12, color: orange, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('Cotización #${c.id}  ·  ${c.fecha.day}/${c.fecha.month}/${c.fecha.year}'),
        pw.Text('Cliente: ${c.clienteNombre}'),
        pw.SizedBox(height: 16),
        pw.Table.fromTextArray(
          headers: const ['Producto', 'Cant.', 'Precio unit.', 'Subtotal'],
          data: items
              .map((it) => [
                    (it['productos'] is Map) ? it['productos']['nombre'].toString() : '',
                    '${it['cantidad']}',
                    money(it['precio_unitario']),
                    money((it['cantidad'] as num) * (it['precio_unitario'] as num)),
                  ])
              .toList(),
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Total estimado: ${money(c.total)}',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: brown)),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Este documento es una cotización y no representa un comprobante fiscal ni un cobro realizado.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFA0826D)),
        ),
      ]),
    ));
    return doc.save();
  }

  Future<Uint8List> _pdfFactura({required Map<String, dynamic> datos}) async {
    const brown = PdfColor.fromInt(0xFF8B6F47);
    const orange = PdfColor.fromInt(0xFFFFB347);
    final empresa = AppSession.instance.empresa ?? 'ERP Dulcería';
    final venta = datos['venta'] as Map<String, dynamic>;
    final items = datos['items'] as List<Map<String, dynamic>>;
    final cliente = (venta['clientes'] is Map) ? venta['clientes'] as Map<String, dynamic> : <String, dynamic>{};
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(empresa, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brown)),
        pw.Text('FACTURA', style: pw.TextStyle(fontSize: 12, color: orange, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('Venta #${venta['id']}'),
        pw.SizedBox(height: 8),
        pw.Text('Datos del cliente', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: brown)),
        pw.Text('Nombre: ${cliente['nombre'] ?? 'Público General'}'),
        if ((cliente['direccion'] ?? '').toString().isNotEmpty) pw.Text('Dirección: ${cliente['direccion']}'),
        if ((cliente['correo'] ?? '').toString().isNotEmpty) pw.Text('Correo: ${cliente['correo']}'),
        if ((cliente['telefono'] ?? '').toString().isNotEmpty) pw.Text('Teléfono: ${cliente['telefono']}'),
        pw.SizedBox(height: 16),
        pw.Table.fromTextArray(
          headers: const ['Producto', 'Cant.', 'Precio unit.', 'Subtotal'],
          data: items
              .map((it) => [
                    (it['producto_nombre'] ?? '').toString(),
                    '${it['cantidad']}',
                    money(it['precio_unitario']),
                    money((it['cantidad'] as num) * (it['precio_unitario'] as num)),
                  ])
              .toList(),
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Total: ${money(venta['total'])}',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: brown)),
        ),
      ]),
    ));
    return doc.save();
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
          tabs: const [Tab(text: 'Cotizaciones'), Tab(text: 'Facturar venta')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaCotizacion,
        backgroundColor: kOrange,
        icon: const Icon(Icons.request_quote_outlined, color: Colors.white),
        label: const Text('Nueva cotización', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: kRed)))
              : Stack(children: [
                  TabBarView(
                    controller: _tabs,
                    children: [
                      Column(
                        children: [
                          SearchField(
                            hintText: 'Buscar por cliente o # de cotización…',
                            onChanged: (v) => setState(() => _busquedaCotizaciones = v),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _load,
                              child: _cotizacionesFiltradas.isEmpty
                                  ? ListView(children: [
                                      SizedBox(
                                        height: 400,
                                        child: _cotizaciones.isEmpty
                                            ? EmptyState(
                                                icon: Icons.request_quote_outlined,
                                                titulo: 'Aún no hay cotizaciones',
                                                subtitulo:
                                                    'Crea tu primera cotización para poder generar una prefactura.',
                                                accionTexto: 'Nueva cotización',
                                                onAccion: _nuevaCotizacion,
                                              )
                                            : const EmptyState(
                                                icon: Icons.search_off,
                                                titulo: 'Sin resultados',
                                                subtitulo: 'Ninguna cotización coincide con tu búsqueda.',
                                              ),
                                      ),
                                    ])
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: _cotizacionesFiltradas.length,
                                      itemBuilder: (context, i) {
                                        final c = _cotizacionesFiltradas[i];
                                        return Card(
                                          child: ListTile(
                                            title: Text('Cotización #${c.id} — ${c.clienteNombre}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                                            subtitle:
                                                Text('${c.fecha.day}/${c.fecha.month}/${c.fecha.year}  ·  ${c.estado}'),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.picture_as_pdf_outlined, color: kOrange),
                                              onPressed: _generando ? null : () => _generarPrefactura(c),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          SearchField(
                            hintText: 'Buscar por cliente o # de venta…',
                            onChanged: (v) => setState(() => _busquedaVentas = v),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _load,
                              child: _ventasFiltradas.isEmpty
                                  ? ListView(children: [
                                      SizedBox(
                                        height: 400,
                                        child: _ventas.isEmpty
                                            ? const EmptyState(
                                                icon: Icons.receipt_long_outlined,
                                                titulo: 'Aún no hay ventas para facturar',
                                                subtitulo: 'Cuando registres una venta, aquí podrás emitir su factura.',
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
                                      itemCount: _ventasFiltradas.length,
                                      itemBuilder: (context, i) {
                                        final v = _ventasFiltradas[i];
                                        final cliente =
                                            (v['clientes'] is Map) ? v['clientes']['nombre'] : 'Público General';
                                        return Card(
                                          child: ListTile(
                                            title: Text('Venta #${v['id']} — $cliente',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                                            trailing: ElevatedButton.icon(
                                              onPressed: _generando ? null : () => _generarFactura(v),
                                              icon: const Icon(Icons.receipt_long_outlined, size: 18),
                                              label: const Text('Facturar'),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_generando)
                    Container(
                      color: Colors.black26,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ]),
    );
  }
}

class _CotizacionDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _CotizacionDialog({required this.onSaved});
  @override
  State<_CotizacionDialog> createState() => _CotizacionDialogState();
}

class _CotizacionDialogState extends State<_CotizacionDialog> {
  final _repo = FacturacionRepositoryImpl();
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _productos = [];
  int? _clienteId;
  final List<ItemCotizacion> _items = [];
  bool _loading = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final cli = await _repo.catalogoClientes();
      final prod = await _repo.catalogoProductos();
      setState(() {
        _clientes = cli;
        _productos = prod;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo cargar catálogos: $e';
        _loading = false;
      });
    }
  }

  void _agregarItem() {
    if (_productos.isEmpty) return;
    final p = _productos.first;
    setState(() => _items.add(ItemCotizacion(
          productoId: p['id'] as int,
          productoNombre: p['nombre'] as String,
          cantidad: 1,
          precioUnitario: (p['precio_venta'] as num).toDouble(),
        )));
  }

  Future<void> _guardar() async {
    if (_items.isEmpty) {
      setState(() => _error = 'Agrega al menos un producto.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await _repo.crearCotizacion(clienteId: _clienteId, items: _items);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      setState(() => _error = 'No se pudo guardar la cotización: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DialogHeader(icon: Icons.request_quote_outlined, text: 'Nueva cotización'),
      content: SizedBox(
        width: dialogWidth(context),
        child: _loading
            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _clienteId,
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
                      onPressed: _productos.isEmpty ? null : _agregarItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar producto'),
                    ),
                  ),
                  ..._items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final it = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: it.productoId,
                            decoration: const InputDecoration(labelText: 'Producto'),
                            items: _productos
                                .map((p) => DropdownMenuItem(
                                    value: p['id'] as int,
                                    child: Text(p['nombre'], overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) => setState(() {
                              final p = _productos.firstWhere((p) => p['id'] == v);
                              _items[idx] = ItemCotizacion(
                                productoId: v!,
                                productoNombre: p['nombre'] as String,
                                cantidad: it.cantidad,
                                precioUnitario: (p['precio_venta'] as num).toDouble(),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: '${it.cantidad}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Cant.'),
                            onChanged: (v) => setState(() => it.cantidad = int.tryParse(v) ?? 1),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: kRed, size: 18),
                          onPressed: () => setState(() => _items.removeAt(idx)),
                        ),
                      ]),
                    );
                  }),
                  if (_error != null)
                    Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: kRed))),
                ]),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar cotización'),
        ),
      ],
    );
  }
}
