import '../../../core/supabase_client.dart';
import '../domain/rh_repository.dart';
import '../domain/usuario.dart';

class RhRepositoryImpl implements RhRepository {
  @override
  Future<List<Usuario>> listarUsuarios() async {
    final res = await supabase.from('profiles').select().order('nombre');
    return List<Map<String, dynamic>>.from(res).map(Usuario.fromMap).toList();
  }

  @override
  Future<void> actualizarRol(String userId, String nuevoRol) {
    return supabase.from('profiles').update({'role': nuevoRol}).eq('id', userId);
  }

  @override
  Future<List<Map<String, dynamic>>> ventasPorVendedor() async {
    // Requiere migración 2 (columna ventas.vendedor_id -> profiles.id).
    final res = await supabase.from('ventas').select('total, profiles(nombre)');
    final Map<String, Map<String, dynamic>> acumulado = {};
    for (final v in List<Map<String, dynamic>>.from(res)) {
      final nombre = (v['profiles'] is Map) ? (v['profiles']['nombre'] as String? ?? 'Sin asignar') : 'Sin asignar';
      final total = (v['total'] as num?)?.toDouble() ?? 0;
      acumulado.update(
        nombre,
        (a) => {'nombre': nombre, 'ventas': (a['ventas'] as int) + 1, 'total': (a['total'] as double) + total},
        ifAbsent: () => {'nombre': nombre, 'ventas': 1, 'total': total},
      );
    }
    final lista = acumulado.values.toList()..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
    return lista;
  }
}
