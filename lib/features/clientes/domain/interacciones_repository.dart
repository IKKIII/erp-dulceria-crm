abstract class InteraccionesRepository {
  Future<List<Map<String, dynamic>>> listar(int clienteId);
  Future<void> crear(Map<String, dynamic> data);
}
