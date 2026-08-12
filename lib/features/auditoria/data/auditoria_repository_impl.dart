import '../../../core/supabase_client.dart';
import '../domain/audit_entry.dart';
import '../domain/auditoria_repository.dart';

class AuditoriaRepositoryImpl implements AuditoriaRepository {
  @override
  Future<List<AuditEntry>> listar({int limite = 200}) async {
    final res = await supabase
        .from('audit_log')
        .select('id, tabla, registro_id, accion, fecha, datos_anteriores, datos_nuevos, profiles(nombre)')
        .order('fecha', ascending: false)
        .limit(limite);
    return List<Map<String, dynamic>>.from(res).map(AuditEntry.fromMap).toList();
  }
}
