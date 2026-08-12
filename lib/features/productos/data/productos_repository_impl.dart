import '../../../core/supabase_client.dart';
import '../domain/productos_repository.dart';

class ProductosRepositoryImpl implements ProductosRepository {
  @override
  Future<List<Map<String, dynamic>>> listarPagina({required int pagina, int tamanoPagina = 30}) async {
    final desde = pagina * tamanoPagina;
    final hasta = desde + tamanoPagina - 1;
    final res = await supabase.from('productos').select().order('nombre').range(desde, hasta);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<List<Map<String, dynamic>>> buscar(String texto) async {
    final res = await supabase
        .from('productos')
        .select()
        .or('nombre.ilike.%$texto%,categoria.ilike.%$texto%')
        .order('nombre')
        .limit(100);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<List<Map<String, dynamic>>> listarTodos() async {
    final res = await supabase.from('productos').select().order('nombre');
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<void> crear(Map<String, dynamic> data) => supabase.from('productos').insert(data);

  @override
  Future<void> actualizar(int id, Map<String, dynamic> data) =>
      supabase.from('productos').update(data).eq('id', id);

  @override
  Future<void> eliminar(int id) => supabase.from('productos').delete().eq('id', id);
}
