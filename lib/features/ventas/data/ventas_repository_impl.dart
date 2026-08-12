import '../../../core/supabase_client.dart';
import '../domain/ventas_repository.dart';

class VentasRepositoryImpl implements VentasRepository {
  @override
  Future<List<Map<String, dynamic>>> listar() async {
    // vendedor_id -> profiles(nombre): requiere la migración 2 (columna
    // vendedor_id en ventas + FK a profiles). Si aún no la corres, quita
    // ", profiles(nombre)" de este select.
    final res = await supabase
        .from('ventas')
        .select('id, total, fecha, clientes(nombre), profiles(nombre)')
        .order('id', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<List<Map<String, dynamic>>> obtenerDetalle(int ventaId) async {
    final res = await supabase
        .from('venta_detalle')
        .select('cantidad, precio_unitario, producto_nombre')
        .eq('venta_id', ventaId);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<List<Map<String, dynamic>>> catalogoClientes() async {
    final res = await supabase.from('clientes').select();
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<List<Map<String, dynamic>>> catalogoProductosConStock() async {
    final res = await supabase.from('productos').select().gt('stock', 0);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<void> registrarVenta({int? clienteId, required List<Map<String, dynamic>> items}) {
    return supabase.rpc('registrar_venta', params: {
      'items': items,
      'cliente_id': clienteId,
    });
  }
}
