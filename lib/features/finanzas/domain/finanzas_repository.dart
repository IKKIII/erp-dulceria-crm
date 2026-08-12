abstract class FinanzasRepository {
  Future<List<Map<String, dynamic>>> listarMovimientos();
  Future<void> registrarEgreso({required String concepto, required double monto});

  /// Ventas agrupadas por período ('semana' agrupa por día de la semana
  /// actual, 'mes' agrupa por semana del mes actual).
  Future<List<Map<String, dynamic>>> ventasPorPeriodo(String periodo);
  Future<List<Map<String, dynamic>>> comprasPorPeriodo(String periodo);
}
