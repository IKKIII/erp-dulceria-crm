import '../../../core/supabase_client.dart';
import '../domain/cotizacion.dart';
import '../domain/facturacion_repository.dart';

class FacturacionRepositoryImpl implements FacturacionRepository {
  @override
  Future<List<Cotizacion>> listarCotizaciones() async {
    final res = await supabase
        .from('cotizaciones')
        .select('id, cliente_id, total, fecha, estado, clientes(nombre)')
        .order('id', ascending: false);
    return List<Map<String, dynamic>>.from(res).map(Cotizacion.fromMap).toList();
  }

  @override
  Future<int> crearCotizacion({int? clienteId, required List<ItemCotizacion> items}) async {
    final total = items.fold<double>(0, (acc, it) => acc + it.subtotal);
    final cot = await supabase
        .from('cotizaciones')
        .insert({'cliente_id': clienteId, 'total': total, 'estado': 'pendiente'})
        .select('id')
        .single();
    final cotizacionId = cot['id'] as int;
    await supabase.from('cotizacion_detalle').insert([
      for (final it in items)
        {
          'cotizacion_id': cotizacionId,
          'producto_id': it.productoId,
          'cantidad': it.cantidad,
          'precio_unitario': it.precioUnitario,
        },
    ]);
    return cotizacionId;
  }

  @override
  Future<List<Map<String, dynamic>>> detalleCotizacion(int cotizacionId) async {
    final res = await supabase
        .from('cotizacion_detalle')
        .select('cantidad, precio_unitario, productos(nombre)')
        .eq('cotizacion_id', cotizacionId);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<List<Map<String, dynamic>>> catalogoClientes() async {
    final res = await supabase.from('clientes').select();
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<List<Map<String, dynamic>>> catalogoProductos() async {
    final res = await supabase.from('productos').select();
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<List<Map<String, dynamic>>> ventasFacturables() async {
    final res = await supabase
        .from('ventas')
        .select('id, total, fecha, clientes(nombre)')
        .order('id', ascending: false)
        .limit(30);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<Map<String, dynamic>> obtenerVentaParaFactura(int ventaId) async {
    final venta = await supabase
        .from('ventas')
        .select('id, total, fecha, clientes(nombre, correo, telefono, direccion)')
        .eq('id', ventaId)
        .single();
    final items = await supabase
        .from('venta_detalle')
        .select('cantidad, precio_unitario, producto_nombre')
        .eq('venta_id', ventaId);
    return {
      'venta': venta,
      'items': List<Map<String, dynamic>>.from(items),
    };
  }
}
