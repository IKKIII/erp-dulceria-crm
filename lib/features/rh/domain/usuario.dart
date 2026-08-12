class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String role;
  Usuario({required this.id, required this.nombre, required this.correo, required this.role});

  factory Usuario.fromMap(Map<String, dynamic> m) => Usuario(
        id: m['id'] as String,
        nombre: (m['nombre'] ?? '') as String,
        correo: (m['correo'] ?? '') as String,
        role: (m['role'] ?? '') as String,
      );
}
