import '../../../core/supabase_client.dart';
import '../domain/proveedores_repository.dart';

class ProveedoresRepositoryImpl implements ProveedoresRepository {
  @override
  Future<List<Map<String, dynamic>>> listar() async {
    final res = await supabase.from('proveedores').select().eq('activo', true).order('id', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<void> crear(Map<String, dynamic> data) => supabase.from('proveedores').insert(data);

  @override
  Future<void> desactivar(int id) => supabase.from('proveedores').update({'activo': false}).eq('id', id);
}
