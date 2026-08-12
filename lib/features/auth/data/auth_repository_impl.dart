import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';
import '../domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<void> iniciarSesion({required String correo, required String password}) {
    return supabase.auth.signInWithPassword(email: correo, password: password);
  }

  @override
  Future<void> iniciarSesionConGoogle() {
    return supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.erpdulceria://login-callback/',
    );
  }

  @override
  Future<void> cerrarSesion() => supabase.auth.signOut();

  @override
  Future<String> registrarUsuario({required String correo, required String password}) async {
    String? uid;
    try {
      final res = await supabase.auth.signUp(email: correo, password: password);
      uid = res.user?.id;
    } catch (_) {
      // Aunque falle (ej. "email rate limit exceeded"), Supabase puede haber
      // creado igual al usuario y dejado sesión activa. Revisamos antes de
      // rendirnos.
      uid = supabase.auth.currentUser?.id;
      if (uid == null) rethrow;
    }
    if (uid == null) {
      throw Exception('No se pudo crear el usuario.');
    }
    return uid;
  }

  @override
  Future<void> crearPerfil({
    required String uid,
    required String nombre,
    required String correo,
    required String empresa,
    required String role,
  }) async {
    try {
      await supabase.from('profiles').insert({
        'id': uid,
        'nombre': nombre,
        'correo': correo,
        'role': role,
        'empresa': empresa,
      });
    } on PostgrestException catch (e) {
      // 23505 = llave única duplicada: el perfil ya existía. Lo tratamos
      // como éxito (pasa si hubo un intento anterior parcial).
      if (e.code != '23505') rethrow;
    }
  }

  @override
  Future<void> recuperarContrasena(String correo) {
    return supabase.auth.resetPasswordForEmail(correo);
  }
}
