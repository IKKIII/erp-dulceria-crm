abstract class ClientesRepository {
  Future<List<Map<String, dynamic>>> listar();
  Future<void> crear(Map<String, dynamic> data);
  Future<void> desactivar(int id);
  /// Clientes ordenados por monto total comprado (para la vista de
  /// "clientes que más compran"). Se calcula agregando la tabla ventas.
  Future<List<Map<String, dynamic>>> topCompradores({int limite = 10});
}
