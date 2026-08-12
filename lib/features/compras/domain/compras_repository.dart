abstract class ComprasRepository {
  Future<List<Map<String, dynamic>>> listar();
  Future<List<Map<String, dynamic>>> catalogoProveedores();
  Future<List<Map<String, dynamic>>> catalogoProductos();
  Future<void> registrarCompra({required int proveedorId, required List<Map<String, dynamic>> items});
}
