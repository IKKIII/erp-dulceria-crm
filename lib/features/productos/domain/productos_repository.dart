abstract class ProductosRepository {
  /// Trae una "página" de productos ordenados por nombre. Úsalo para el
  /// listado normal (sin buscador activo).
  Future<List<Map<String, dynamic>>> listarPagina({required int pagina, int tamanoPagina = 30});

  /// Busca en TODO el catálogo (no solo lo ya cargado), del lado del
  /// servidor — se usa cuando el usuario escribe algo en el buscador.
  Future<List<Map<String, dynamic>>> buscar(String texto);

  /// Todo el catálogo sin paginar — solo para exportar a CSV, no para
  /// mostrar en pantalla (ahí sí se usa listarPagina).
  Future<List<Map<String, dynamic>>> listarTodos();

  Future<void> crear(Map<String, dynamic> data);
  Future<void> actualizar(int id, Map<String, dynamic> data);
  Future<void> eliminar(int id);
}
