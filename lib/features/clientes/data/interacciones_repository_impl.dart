import '../../../core/supabase_client.dart';
import '../domain/interacciones_repository.dart';

class InteraccionesRepositoryImpl implements InteraccionesRepository {
  @override
  Future<List<Map<String, dynamic>>> listar(int clienteId) async {
    final res = await supabase
        .from('interacciones_cliente')
        .select()
        .eq('cliente_id', clienteId)
        .order('fecha', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<void> crear(Map<String, dynamic> data) => supabase.from('interacciones_cliente').insert(data);
}
