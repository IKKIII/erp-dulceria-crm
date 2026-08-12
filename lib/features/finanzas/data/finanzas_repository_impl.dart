import '../../../core/supabase_client.dart';
import '../domain/finanzas_repository.dart';

class FinanzasRepositoryImpl implements FinanzasRepository {
  @override
  Future<List<Map<String, dynamic>>> listarMovimientos() async {
    final res = await supabase.from('finanzas').select().order('id', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<void> registrarEgreso({required String concepto, required double monto}) {
    return supabase.from('finanzas').insert({
      'tipo': 'egreso',
      'concepto': concepto,
      'monto': monto,
      'referencia': 'manual',
    });
  }

  DateTime _inicioPeriodo(String periodo) {
    final ahora = DateTime.now();
    if (periodo == 'semana') {
      return DateTime(ahora.year, ahora.month, ahora.day).subtract(Duration(days: ahora.weekday - 1));
    }
    // 'mes': desde el día 1 del mes actual
    return DateTime(ahora.year, ahora.month, 1);
  }

  List<Map<String, dynamic>> _agrupar(List<Map<String, dynamic>> filas, String periodo) {
    final Map<String, double> acumulado = {};
    for (final f in filas) {
      final fecha = DateTime.tryParse((f['fecha'] ?? '').toString());
      if (fecha == null) continue;
      final total = (f['total'] as num?)?.toDouble() ?? 0;
      final clave = periodo == 'semana'
          ? const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][fecha.weekday - 1]
          : 'Semana ${((fecha.day - 1) / 7).floor() + 1}';
      acumulado.update(clave, (v) => v + total, ifAbsent: () => total);
    }
    return acumulado.entries.map((e) => {'etiqueta': e.key, 'total': e.value}).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> ventasPorPeriodo(String periodo) async {
    final desde = _inicioPeriodo(periodo);
    final res = await supabase.from('ventas').select('total, fecha').gte('fecha', desde.toIso8601String());
    return _agrupar(List<Map<String, dynamic>>.from(res), periodo);
  }

  @override
  Future<List<Map<String, dynamic>>> comprasPorPeriodo(String periodo) async {
    final desde = _inicioPeriodo(periodo);
    final res = await supabase.from('compras').select('total, fecha').gte('fecha', desde.toIso8601String());
    return _agrupar(List<Map<String, dynamic>>.from(res), periodo);
  }
}
