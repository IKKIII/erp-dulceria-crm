import '../../../core/supabase_client.dart';
import '../domain/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  @override
  Future<Map<String, dynamic>> obtenerKpis() async {
    final res = await supabase.rpc('get_dashboard_kpis');
    return Map<String, dynamic>.from(res as Map);
  }
}
