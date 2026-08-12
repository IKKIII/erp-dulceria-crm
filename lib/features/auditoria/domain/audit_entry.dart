class AuditEntry {
  final int id;
  final String tabla;
  final String registroId;
  final String accion; // INSERT | UPDATE | DELETE
  final String? usuarioNombre;
  final Map<String, dynamic>? datosAnteriores;
  final Map<String, dynamic>? datosNuevos;
  final DateTime fecha;

  AuditEntry({
    required this.id,
    required this.tabla,
    required this.registroId,
    required this.accion,
    required this.usuarioNombre,
    required this.datosAnteriores,
    required this.datosNuevos,
    required this.fecha,
  });

  factory AuditEntry.fromMap(Map<String, dynamic> m) => AuditEntry(
        id: m['id'] as int,
        tabla: m['tabla'] as String,
        registroId: (m['registro_id'] ?? '').toString(),
        accion: m['accion'] as String,
        usuarioNombre: (m['profiles'] is Map) ? m['profiles']['nombre'] as String? : null,
        datosAnteriores: (m['datos_anteriores'] as Map?)?.cast<String, dynamic>(),
        datosNuevos: (m['datos_nuevos'] as Map?)?.cast<String, dynamic>(),
        fecha: DateTime.tryParse((m['fecha'] ?? '').toString()) ?? DateTime.now(),
      );
}
