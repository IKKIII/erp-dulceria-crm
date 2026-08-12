import '../../../core/supabase_client.dart';
import '../domain/compras_repository.dart';

class ComprasRepositoryImpl implements ComprasRepository {
  @override
  Future<List<Map<String, dynamic>>> listar() async {
    final res = await supabase
        .from('compras')
        .select('id, total, fecha, proveedores(nombre)')
        .order('id', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<List<Map<String, dynamic>>> catalogoProveedores() async {
    final res = await supabase.from('proveedores').select();
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<List<Map<String, dynamic>>> catalogoProductos() async {
    final res = await supabase.from('productos').select();
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<void> registrarCompra({required int proveedorId, required List<Map<String, dynamic>> items}) {
    return supabase.rpc('registrar_compra', params: {
      'items': items,
      'proveedor_id': proveedorId,
    });
  }
}
