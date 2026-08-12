abstract class ProveedoresRepository {
  Future<List<Map<String, dynamic>>> listar();
  Future<void> crear(Map<String, dynamic> data);
  Future<void> desactivar(int id);
}
