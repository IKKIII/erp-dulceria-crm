class ItemCotizacion {
  final int productoId;
  final String productoNombre;
  int cantidad;
  double precioUnitario;
  ItemCotizacion({
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
  });
  double get subtotal => cantidad * precioUnitario;
}

class Cotizacion {
  final int? id;
  final int? clienteId;
  final String clienteNombre;
  final double total;
  final DateTime fecha;
  final String estado;
  Cotizacion({
    this.id,
    this.clienteId,
    required this.clienteNombre,
    required this.total,
    required this.fecha,
    required this.estado,
  });

  factory Cotizacion.fromMap(Map<String, dynamic> m) => Cotizacion(
        id: m['id'] as int?,
        clienteId: m['cliente_id'] as int?,
        clienteNombre: (m['clientes'] is Map) ? (m['clientes']['nombre'] as String? ?? 'Público General') : 'Público General',
        total: (m['total'] as num?)?.toDouble() ?? 0,
        fecha: DateTime.tryParse((m['fecha'] ?? '').toString()) ?? DateTime.now(),
        estado: (m['estado'] as String?) ?? 'pendiente',
      );
}
