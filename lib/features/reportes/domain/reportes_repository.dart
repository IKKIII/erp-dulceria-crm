abstract class ReportesRepository {
  Future<Map<String, dynamic>> obtenerKpis();
  Future<List<Map<String, dynamic>>> comprasRecientes();
  Future<List<Map<String, dynamic>>> ventasRecientes();
  Future<List<Map<String, dynamic>>> movimientosFinancieros();
}
