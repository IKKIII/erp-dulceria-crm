import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'core/supabase_client.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX', null);
  await initThemeMode();

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(const _ConfiguracionFaltanteApp());
    return;
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const ErpDulceriaApp());
}

/// Se muestra si se corrió `flutter run` sin pasar --dart-define con las
/// credenciales de Supabase — evita un error críptico y confuso.
class _ConfiguracionFaltanteApp extends StatelessWidget {
  const _ConfiguracionFaltanteApp();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF8E5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_outlined, size: 48, color: Color(0xFF8B6F47)),
                const SizedBox(height: 16),
                const Text(
                  'Faltan las credenciales de Supabase',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF8B6F47)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Corre la app con:\n\nflutter run --dart-define-from-file=env.json\n\n'
                  '(ver LEEME_INSTALACION.md para crear ese archivo)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8B6F47)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ErpDulceriaApp extends StatelessWidget {
  const ErpDulceriaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'ERP Dulcería',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          darkTheme: buildDarkAppTheme(),
          themeMode: mode,
          home: const AuthGate(),
        );
      },
    );
  }
}

/// Escucha el estado de sesión de Supabase y decide qué pantalla mostrar.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        if (session == null) {
          return const LoginScreen();
        }
        return const HomeShell();
      },
    );
  }
}
