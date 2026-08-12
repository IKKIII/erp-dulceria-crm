/// Contrato de autenticación — la capa de presentación solo conoce esto,
/// nunca llama a Supabase directamente.
abstract class AuthRepository {
  Future<void> iniciarSesion({required String correo, required String password});
  Future<void> iniciarSesionConGoogle();
  Future<void> cerrarSesion();

  /// Crea el usuario en Auth. Si Supabase lanza una excepción (ej. rate
  /// limit de correo) pero el usuario terminó creándose de todos modos,
  /// regresa el uid en vez de propagar el error.
  Future<String> registrarUsuario({required String correo, required String password});

  Future<void> crearPerfil({
    required String uid,
    required String nombre,
    required String correo,
    required String empresa,
    required String role,
  });

  /// Envía un correo con enlace para restablecer la contraseña.
  Future<void> recuperarContrasena(String correo);
}
