import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/error_utils.dart';
import '../../../core/widgets/dialog_header.dart';
import '../data/auth_repository_impl.dart';
import 'setup_screen.dart';

/// Después de este número de intentos fallidos seguidos, se bloquea el
/// botón de login por un rato — capa extra de protección del lado de la
/// app (Supabase ya limita los intentos también del lado del servidor).
const _maxIntentosFallidos = 5;
const _bloqueoSegundos = 60;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _repo = AuthRepositoryImpl();
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int _intentosFallidos = 0;
  int _segundosBloqueo = 0;
  Timer? _timerBloqueo;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _timerBloqueo?.cancel();
    super.dispose();
  }

  void _iniciarBloqueo() {
    setState(() => _segundosBloqueo = _bloqueoSegundos);
    _timerBloqueo?.cancel();
    _timerBloqueo = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _segundosBloqueo--;
        if (_segundosBloqueo <= 0) {
          _segundosBloqueo = 0;
          _intentosFallidos = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _login() async {
    if (_segundosBloqueo > 0) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repo.iniciarSesion(correo: _correoCtrl.text.trim(), password: _passCtrl.text);
      _intentosFallidos = 0;
      // No navegamos manualmente: AuthGate reacciona solo al cambio de sesión.
    } on AuthException catch (e) {
      _intentosFallidos++;
      setState(() => _error = e.message);
      if (_intentosFallidos >= _maxIntentosFallidos) _iniciarBloqueo();
    } catch (e) {
      _intentosFallidos++;
      setState(() => _error = friendlyError(e));
      if (_intentosFallidos >= _maxIntentosFallidos) _iniciarBloqueo();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginConGoogle() async {
    setState(() => _error = null);
    try {
      await _repo.iniciarSesionConGoogle();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = friendlyError(e));
    }
  }

  void _abrirRecuperarContrasena() {
    final correoCtrl = TextEditingController(text: _correoCtrl.text.trim());
    showDialog(
      context: context,
      builder: (dialogContext) => _RecuperarContrasenaDialog(repo: _repo, correoInicial: correoCtrl.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: kYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: kOrange, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🍬', style: TextStyle(fontSize: 36)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ERP Dulcería',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: kBrown, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inicia sesión para continuar',
                        style: TextStyle(color: kBrown.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Correo'),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Contraseña'),
                        validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _abrirRecuperarContrasena,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      if (_segundosBloqueo > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFCCC7)),
                          ),
                          child: Text(
                            'Demasiados intentos fallidos. Intenta de nuevo en $_segundosBloqueo s.',
                            style: const TextStyle(color: kRed, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ] else if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFCCC7)),
                          ),
                          child: Text(_error!, style: const TextStyle(color: kRed, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_loading || _segundosBloqueo > 0) ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_segundosBloqueo > 0 ? 'Bloqueado ($_segundosBloqueo s)' : 'Iniciar sesión'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _loginConGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text('Continuar con Google'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SetupScreen()),
                        ),
                        child: const Text('Registrar mi empresa (primera vez)'),
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

class _RecuperarContrasenaDialog extends StatefulWidget {
  final AuthRepositoryImpl repo;
  final String correoInicial;
  const _RecuperarContrasenaDialog({required this.repo, required this.correoInicial});

  @override
  State<_RecuperarContrasenaDialog> createState() => _RecuperarContrasenaDialogState();
}

class _RecuperarContrasenaDialogState extends State<_RecuperarContrasenaDialog> {
  late final TextEditingController _correoCtrl = TextEditingController(text: widget.correoInicial);
  bool _enviando = false;
  bool _enviado = false;
  String? _error;

  Future<void> _enviar() async {
    if (!_correoCtrl.text.contains('@')) {
      setState(() => _error = 'Ingresa un correo válido.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await widget.repo.recuperarContrasena(_correoCtrl.text.trim());
      setState(() => _enviado = true);
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DialogHeader(icon: Icons.lock_reset_outlined, text: 'Recuperar contraseña'),
      content: SizedBox(
        width: dialogWidth(context),
        child: _enviado
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.mark_email_read_outlined, color: kGreen),
                  SizedBox(width: 10),
                  Expanded(child: Text('Listo, revisa tu correo para continuar.')),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Te enviaremos un enlace para restablecer tu contraseña.'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: kRed)),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_enviado ? 'Cerrar' : 'Cancelar'),
        ),
        if (!_enviado)
          ElevatedButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Enviar enlace'),
          ),
      ],
    );
  }
}
