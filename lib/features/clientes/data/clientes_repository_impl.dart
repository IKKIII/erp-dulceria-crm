import '../../../core/supabase_client.dart';
import '../domain/clientes_repository.dart';

class ClientesRepositoryImpl implements ClientesRepository {
  @override
  Future<List<Map<String, dynamic>>> listar() async {
    final res = await supabase.from('clientes').select().eq('activo', true).order('id', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<void> crear(Map<String, dynamic> data) => supabase.from('clientes').insert(data);

  @override
  Future<void> desactivar(int id) => supabase.from('clientes').update({'activo': false}).eq('id', id);

  @override
  Future<List<Map<String, dynamic>>> topCompradores({int limite = 10}) async {
    // Se agrega del lado del cliente: para un catálogo de este tamaño es
    // suficiente y evita crear otra función RPC en Postgres.
    final ventas = await supabase.from('ventas').select('cliente_id, total, clientes(nombre)');
    final Map<int, Map<String, dynamic>> acumulado = {};
    for (final v in List<Map<String, dynamic>>.from(ventas)) {
      final clienteId = v['cliente_id'] as int?;
      if (clienteId == null) continue; // venta a "Público General"
      final nombre = (v['clientes'] is Map) ? v['clientes']['nombre'] as String? : null;
      final total = (v['total'] as num?)?.toDouble() ?? 0;
      acumulado.update(
        clienteId,
        (actual) => {'cliente_id': clienteId, 'nombre': nombre, 'total': (actual['total'] as double) + total},
        ifAbsent: () => {'cliente_id': clienteId, 'nombre': nombre, 'total': total},
      );
    }
    final lista = acumulado.values.toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
    return lista.take(limite).toList();
  }
}
