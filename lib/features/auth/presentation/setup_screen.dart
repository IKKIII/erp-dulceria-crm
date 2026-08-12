import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../data/auth_repository_impl.dart';

/// Registro inicial: crea la cuenta de Supabase Auth y su perfil con rol
/// 'admin'. Separa "crear usuario" de "crear perfil" porque pueden fallar
/// de forma independiente (ej. rate limit de correo no significa que el
/// usuario no se haya creado).
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _repo = AuthRepositoryImpl();
  final _formKey = GlobalKey<FormState>();
  final _empresaCtrl = TextEditingController(text: 'Dulcería Sanrio');
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _uidPendiente;

  @override
  void dispose() {
    _empresaCtrl.dispose();
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    if (_uidPendiente != null) {
      await _crearPerfil(_uidPendiente!);
      return;
    }

    try {
      final uid = await _repo.registrarUsuario(correo: _correoCtrl.text.trim(), password: _passCtrl.text);
      await _crearPerfil(uid);
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo crear el usuario: $e';
        _loading = false;
      });
    }
  }

  Future<void> _crearPerfil(String uid) async {
    try {
      await _repo.crearPerfil(
        uid: uid,
        nombre: _nombreCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        empresa: _empresaCtrl.text.trim(),
        role: 'admin',
      );
      _uidPendiente = null;
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _uidPendiente = uid;
      setState(() => _error = 'El usuario se creó, pero no se pudo guardar el '
          'perfil: $e. Toca "Reintentar" para intentarlo de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro inicial')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Registra tu empresa y el primer administrador',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: kBrown, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _empresaCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre de la empresa'),
                        validator: (v) => validarNombreValido(v, campo: 'El nombre de la empresa'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre del administrador'),
                        validator: (v) => validarNombreValido(v, campo: 'El nombre del administrador'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _correoCtrl,
                        enabled: _uidPendiente == null,
                        decoration: const InputDecoration(labelText: 'Correo del administrador'),
                        keyboardType: TextInputType.emailAddress,
                        validator: validarCorreo,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passCtrl,
                        enabled: _uidPendiente == null,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Contraseña (mínimo 6 caracteres)'),
                        validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: kRed, fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loading ? null : _registrar,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_uidPendiente == null
                                ? 'Registrar empresa e iniciar sesión'
                                : 'Reintentar guardar perfil'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

