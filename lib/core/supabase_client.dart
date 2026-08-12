import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// Las credenciales YA NO viven aquí en texto plano — se pasan al
// compilar con --dart-define, para que nunca queden guardadas en el
// código fuente (importante si subes este proyecto a GitHub/GitLab).
//
// Cómo correr la app en desarrollo (PowerShell):
//   flutter run --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=TU-ANON-KEY
//
// Para no escribir esto cada vez, crea un archivo de variables (ver
// LEEME_INSTALACION.md para el detalle) y usa:
//   flutter run --dart-define-from-file=env.json
// ============================================================
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Cliente global de Supabase. Es un getter (no una variable ya calculada)
/// para que se resuelva "perezosamente" — evita problemas de orden de
/// inicialización entre Supabase.initialize() y el primer uso.
SupabaseClient get supabase => Supabase.instance.client;
