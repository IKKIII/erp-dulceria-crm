import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/session.dart';
import '../../../core/error_utils.dart';
import '../../../core/csv_export.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/aviso_dialog.dart';
import '../../../core/widgets/dialog_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/search_field.dart';
import '../../proveedores/data/proveedores_repository_impl.dart';
import '../data/productos_repository_impl.dart';

/// Categorías fijas del catálogo. "Otros" es el comodín para lo que no
/// encaje en ninguna de las anteriores.
const List<String> kCategoriasProducto = [
  'Snacks',
  'Bebidas',
  'Dulces',
  'Chocolates',
  'Botanas',
  'Chicles',
  'Paletas',
  'Otros',
];

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});
  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> with SingleTickerProviderStateMixin {
  final _repo = ProductosRepositoryImpl();

  /// "Todos" + cada categoría fija, como pestañas.
  final List<String> _categoriasTabs = ['Todos', ...kCategoriasProducto];
  late final TabController _tabs =
      TabController(length: _categoriasTabs.length, vsync: this)..addListener(_onTabChange);

  List<Map<String, dynamic>> _productos = [];
  String _busqueda = '';
  bool _loading = true;
  String? _error;
  bool get _puedeEditar => ['admin', 'almacenista'].contains(AppSession.instance.role);

  void _onTabChange() {
    // Evita reconstruir dos veces por el mismo cambio (una al iniciar el
    // swipe/tap y otra al terminar la animación).
    if (!_tabs.indexIsChanging) setState(() {});
  }

  /// Lo que se muestra en pantalla: filtrado por la pestaña activa y,
  /// si hay texto en el buscador, también por nombre o categoría.
  List<Map<String, dynamic>> get _visibles {
    final categoriaTab = _categoriasTabs[_tabs.index];
    var lista = _productos;
    if (categoriaTab != 'Todos') {
      lista = lista.where((p) => p['categoria'] == categoriaTab).toList();
    }
    if (_busqueda.trim().isNotEmpty) {
      final q = _busqueda.trim().toLowerCase();
      lista = lista.where((p) {
        final nombre = (p['nombre'] ?? '').toString().toLowerCase();
        final categoria = (p['categoria'] ?? '').toString().toLowerCase();
        return nombre.contains(q) || categoria.contains(q);
      }).toList();
    }
    return lista;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChange);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.listarTodos();
      setState(() => _productos = data);
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _eliminar(int id) async {
    try {
      await _repo.eliminar(id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackExito('Producto eliminado'));
      }
    } catch (e) {
      if (mounted) {
        await mostrarAvisoError(context, mensaje: friendlyError(e));
      }
    }
  }

  void _confirmarEliminar(int id, String nombre) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const DialogHeader(icon: Icons.warning_amber_rounded, text: '¿Eliminar producto?', color: kRed),
        content: Text('Se eliminará "$nombre" permanentemente. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            onPressed: () {
              Navigator.of(context).pop();
              _eliminar(id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _abrirFormulario({Map<String, dynamic>? producto}) {
    showDialog(
      context: context,
      builder: (_) => _ProductoDialog(producto: producto, productosExistentes: _productos, onSaved: _load),
    );
  }

  Future<void> _exportarCsv() async {
    if (_productos.isEmpty) return;
    try {
      await exportarCsv(
        nombreArchivo: 'productos',
        encabezados: const ['Nombre', 'Categoría', 'Stock', 'Stock mínimo', 'Precio venta', 'Costo promedio'],
        filas: _productos
            .map((p) => [
                  p['nombre'],
                  p['categoria'],
                  p['stock'],
                  p['stock_minimo'],
                  p['precio_venta'],
                  p['costo_promedio'],
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: kBrown,
          indicatorColor: kOrange,
          tabs: _categoriasTabs.map((c) => Tab(text: c)).toList(),
        ),
      ),
      floatingActionButton: _puedeEditar
          ? FloatingActionButton(
              onPressed: () => _abrirFormulario(),
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
                    Row(
                      children: [
                        Expanded(
                          child: SearchField(
                            hintText: 'Buscar por nombre o categoría…',
                            onChanged: (v) => setState(() => _busqueda = v),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Exportar a CSV',
                          icon: const Icon(Icons.file_download_outlined, color: kBrown),
                          onPressed: _productos.isEmpty ? null : _exportarCsv,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: _visibles.isEmpty
                            ? ListView(children: [
                                SizedBox(
                                  height: 400,
                                  child: _productos.isEmpty
                                      ? EmptyState(
                                          icon: Icons.inventory_2_outlined,
                                          titulo: 'Aún no tienes productos',
                                          subtitulo: 'Agrega tu primer producto para empezar a llevar tu inventario.',
                                          accionTexto: _puedeEditar ? 'Agregar producto' : null,
                                          onAccion: _puedeEditar ? () => _abrirFormulario() : null,
                                        )
                                      : const EmptyState(
                                          icon: Icons.search_off,
                                          titulo: 'Sin resultados',
                                          subtitulo: 'Ningún producto coincide con esta categoría o búsqueda.',
                                        ),
                                ),
                              ])
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _visibles.length,
                                itemBuilder: (context, i) {
                                  final p = _visibles[i];
                                  final stockBajo = (p['stock'] as int) <= (p['stock_minimo'] as int);
                                  return Card(
                                    child: ListTile(
                                      title: Text(p['nombre'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                                      subtitle: Text(
                                          '${p['categoria']} — Stock: ${p['stock']} — Venta: ${money(p['precio_venta'])}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (stockBajo)
                                            const Padding(
                                              padding: EdgeInsets.only(right: 6),
                                              child: Icon(Icons.warning_amber_rounded, color: kRed, size: 20),
                                            ),
                                          if (_puedeEditar)
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: kBrown),
                                              onPressed: () => _abrirFormulario(producto: p),
                                            ),
                                          if (_puedeEditar)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: kRed),
                                              onPressed: () =>
                                                  _confirmarEliminar(p['id'] as int, p['nombre'] ?? ''),
                                            ),
                                        ],
                                      ),
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

class _ProductoDialog extends StatefulWidget {
  final Map<String, dynamic>? producto;
  final List<Map<String, dynamic>> productosExistentes;
  final VoidCallback onSaved;
  const _ProductoDialog({this.producto, required this.productosExistentes, required this.onSaved});
  @override
  State<_ProductoDialog> createState() => _ProductoDialogState();
}

class _ProductoDialogState extends State<_ProductoDialog> {
  final _repo = ProductosRepositoryImpl();
  final _repoProveedores = ProveedoresRepositoryImpl();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre, _precio, _costo, _stock, _stockMin;
  late List<String> _categoriasDisponibles;
  String? _categoriaSeleccionada;
  List<Map<String, dynamic>> _proveedores = [];
  int? _proveedorId;
  bool _loading = false;
  bool _cargandoProveedores = true;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombre = TextEditingController(text: p?['nombre'] ?? '');
    _precio = TextEditingController(text: (p?['precio_venta'] ?? '').toString());
    _costo = TextEditingController(text: (p?['costo_promedio'] ?? '').toString());
    _stock = TextEditingController(text: (p?['stock'] ?? '0').toString());
    _stockMin = TextEditingController(text: (p?['stock_minimo'] ?? '5').toString());
    _proveedorId = p?['proveedor_id'] as int?;

    // Si el producto ya tenía una categoría que no está en la lista fija
    // (ej. datos viejos con "General"), la agregamos como opción extra
    // para no perder el dato al abrir el formulario de edición.
    _categoriasDisponibles = List.of(kCategoriasProducto);
    final categoriaActual = p?['categoria'] as String?;
    if (categoriaActual != null &&
        categoriaActual.trim().isNotEmpty &&
        !_categoriasDisponibles.contains(categoriaActual)) {
      _categoriasDisponibles.insert(0, categoriaActual);
    }
    _categoriaSeleccionada = categoriaActual;
    _cargarProveedores();
  }

  Future<void> _cargarProveedores() async {
    try {
      final prov = await _repoProveedores.listar();
      setState(() {
        _proveedores = prov;
        _cargandoProveedores = false;
      });
    } catch (e) {
      setState(() => _cargandoProveedores = false);
      if (mounted) await mostrarAvisoError(context, mensaje: 'No se pudo cargar proveedores: $e');
    }
  }

  /// Busca, entre los productos ya existentes (excluyendo este mismo si
  /// se está editando), alguno cuyo nombre sea sospechosamente parecido
  /// al que se está por guardar.
  Map<String, dynamic>? _buscarNombreParecido(String nombreNuevo) {
    final idActual = widget.producto?['id'];
    for (final p in widget.productosExistentes) {
      if (idActual != null && p['id'] == idActual) continue;
      if (sonNombresParecidos(nombreNuevo, (p['nombre'] ?? '').toString())) {
        return p;
      }
    }
    return null;
  }

  Future<bool> _confirmarNombreParecido(String nombreExistente) async {
    final continuar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const DialogHeader(icon: Icons.compare_arrows, text: 'Nombre muy parecido', color: kOrange),
        content: Text(
          'Ya existe un producto llamado "$nombreExistente", muy similar al nombre que escribiste. '
          '¿Seguro que no es el mismo producto? Puedes continuar si de verdad son diferentes.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kOrange),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar de todas formas'),
          ),
        ],
      ),
    );
    return continuar ?? false;
  }

  /// Verifica que el proveedor elegido no choque con el que ya surte este
  /// mismo producto en otro registro (por si dos productos con el mismo
  /// nombre exacto tuvieran proveedores distintos — caso raro pero posible
  /// si el usuario editó el nombre manualmente).
  String? _proveedorEnConflicto(String nombreNuevo) {
    if (_proveedorId == null) return null;
    final idActual = widget.producto?['id'];
    for (final p in widget.productosExistentes) {
      if (idActual != null && p['id'] == idActual) continue;
      final mismoNombre = (p['nombre'] ?? '').toString().trim().toLowerCase() == nombreNuevo.trim().toLowerCase();
      final provExistente = p['proveedor_id'] as int?;
      if (mismoNombre && provExistente != null && provExistente != _proveedorId) {
        return p['nombre'] as String;
      }
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      await mostrarAvisoFaltante(context, mensaje: 'Selecciona una categoría antes de continuar.');
      return;
    }

    final nombreNuevo = _nombre.text.trim();

    final conflicto = _proveedorEnConflicto(nombreNuevo);
    if (conflicto != null) {
      await mostrarAvisoError(
        context,
        titulo: 'Proveedor en conflicto',
        mensaje:
            'El producto "$conflicto" ya existe con un proveedor distinto asignado. '
            'Un mismo producto no puede tener dos proveedores diferentes.',
      );
      return;
    }

    final parecido = _buscarNombreParecido(nombreNuevo);
    if (parecido != null) {
      final continuar = await _confirmarNombreParecido(parecido['nombre'] as String);
      if (!continuar) return;
    }

    setState(() => _loading = true);
    try {
      final data = {
        'nombre': nombreNuevo,
        'categoria': _categoriaSeleccionada,
        'precio_venta': double.tryParse(_precio.text) ?? 0,
        'costo_promedio': double.tryParse(_costo.text) ?? 0,
        'stock': int.tryParse(_stock.text) ?? 0,
        'stock_minimo': int.tryParse(_stockMin.text) ?? 5,
        'proveedor_id': _proveedorId,
      };
      if (widget.producto != null) {
        await _repo.actualizar(widget.producto!['id'] as int, data);
      } else {
        await _repo.crear(data);
      }
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final mensajeExito = widget.producto != null
            ? 'Producto actualizado correctamente'
            : 'Producto guardado correctamente';
        Navigator.of(context).pop();
        widget.onSaved();
        messenger.showSnackBar(snackExito(mensajeExito));
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
      title: DialogHeader(
        icon: widget.producto == null ? Icons.add_circle_outline : Icons.edit_outlined,
        text: widget.producto == null ? 'Nuevo producto' : 'Editar producto',
      ),
      content: SizedBox(
        width: dialogWidth(context),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => validarNombreValido(v, campo: 'El nombre'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categoriasDisponibles
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoriaSeleccionada = v),
                validator: (v) => v == null ? 'Selecciona una categoría.' : null,
              ),
              const SizedBox(height: 10),
              _cargandoProveedores
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  : DropdownButtonFormField<int?>(
                      initialValue: _proveedorId,
                      decoration: const InputDecoration(labelText: 'Proveedor (opcional)'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Sin proveedor asignado')),
                        ..._proveedores.map((pr) => DropdownMenuItem<int?>(
                              value: pr['id'] as int,
                              child: Text(pr['nombre'] ?? '', overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) => setState(() => _proveedorId = v),
                    ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _precio,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Precio venta'),
                    validator: (v) => validarNumeroNoNegativo(v, campo: 'El precio de venta'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _costo,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Costo'),
                    validator: (v) => validarNumeroNoNegativo(v, campo: 'El costo'),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock'),
                    validator: (v) => validarEnteroNoNegativo(v, campo: 'El stock'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stockMin,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock mínimo'),
                    validator: (v) => validarEnteroNoNegativo(v, campo: 'El stock mínimo'),
                  ),
                ),
              ]),
            ]),
          ),
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
