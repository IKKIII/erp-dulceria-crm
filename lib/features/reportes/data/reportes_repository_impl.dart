import '../../../core/supabase_client.dart';
import '../domain/reportes_repository.dart';

class ReportesRepositoryImpl implements ReportesRepository {
  @override
  Future<Map<String, dynamic>> obtenerKpis() async {
    final res = await supabase.rpc('get_dashboard_kpis');
    return Map<String, dynamic>.from(res as Map);
  }

  @override
  Future<List<Map<String, dynamic>>> comprasRecientes() async {
    final res = await supabase
        .from('compras')
        .select('id, total, fecha, proveedores(nombre)')
        .order('id', ascending: false)
        .limit(12);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<List<Map<String, dynamic>>> ventasRecientes() async {
    final res = await supabase
        .from('ventas')
        .select('id, total, fecha, clientes(nombre)')
        .order('id', ascending: false)
        .limit(12);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<List<Map<String, dynamic>>> movimientosFinancieros() async {
    final res = await supabase.from('finanzas').select().order('id', ascending: false).limit(14);
    return List<Map<String, dynamic>>.from(res);
  }
}
