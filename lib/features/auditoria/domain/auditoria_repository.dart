import 'audit_entry.dart';

abstract class AuditoriaRepository {
  Future<List<AuditEntry>> listar({int limite = 200});
}
