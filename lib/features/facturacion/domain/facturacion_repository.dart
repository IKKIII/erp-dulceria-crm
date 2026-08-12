import 'cotizacion.dart';

abstract class FacturacionRepository {
  Future<List<Cotizacion>> listarCotizaciones();
  Future<int> crearCotizacion({int? clienteId, required List<ItemCotizacion> items});
  Future<List<Map<String, dynamic>>> detalleCotizacion(int cotizacionId);

  Future<List<Map<String, dynamic>>> catalogoClientes();
  Future<List<Map<String, dynamic>>> catalogoProductos();

  /// Datos completos de una venta ya registrada, para emitir su factura
  /// (cliente completo + líneas de producto).
  Future<Map<String, dynamic>> obtenerVentaParaFactura(int ventaId);
  Future<List<Map<String, dynamic>>> ventasFacturables();
}
