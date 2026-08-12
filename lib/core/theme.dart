import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Paleta de marca — misma que erp-app.css / auth-live-server.css del ERP original.
const kBrown = Color(0xFF8B6F47);
const kOrange = Color(0xFFFFB347);
const kYellow = Color(0xFFFFD966);
const kCream = Color(0xFFFFF8E5);
const kRed = Color(0xFFB42318);
const kGreen = Color(0xFF1F7A41);
const kFieldBg = Color(0xFFFFFDF4);

// Paleta oscura — mismos acentos (naranja/amarillo/rojo/verde), pero sobre
// tonos "chocolate oscuro" en vez de negro genérico, para mantener la
// identidad de marca también en modo oscuro.
const kDarkBg = Color(0xFF241C14);
const kDarkSurface = Color(0xFF3A2E20);
const kDarkFieldBg = Color(0xFF2E2419);

/// Controla el modo de tema (claro/oscuro) de toda la app. Se guarda en
/// shared_preferences para recordarlo entre sesiones (ver initThemeMode()
/// y setThemeMode(), llamadas desde main.dart y el switch del drawer).
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

const _prefThemeMode = 'theme_mode_dark';

/// Léelo una vez al arrancar la app (en main.dart) para restaurar la
/// preferencia guardada la última vez.
Future<void> initThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final esOscuro = prefs.getBool(_prefThemeMode) ?? false;
  themeModeNotifier.value = esOscuro ? ThemeMode.dark : ThemeMode.light;
}

/// Cambia el tema y lo recuerda para la próxima vez que se abra la app.
Future<void> setThemeMode(ThemeMode mode) async {
  themeModeNotifier.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefThemeMode, mode == ThemeMode.dark);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kCream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kOrange,
      primary: kOrange,
      secondary: kBrown,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: kYellow,
      foregroundColor: kBrown,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: kBrown, fontSize: 18, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: kBrown),
    ),
    // Regla del entorno: SIEMPRE CardThemeData, NUNCA CardTheme.
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kYellow.withValues(alpha: 0.7)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kFieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kYellow),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kYellow),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kOrange, width: 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      elevation: 6,
      shadowColor: kBrown.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// Versión oscura del tema. Los acentos de marca (naranja, amarillo, rojo,
/// verde) se mantienen igual — solo cambian los fondos y superficies a
/// tonos "chocolate oscuro", así los botones y alertas siguen viéndose
/// igual de reconocibles.
ThemeData buildDarkAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kDarkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kOrange,
      brightness: Brightness.dark,
      primary: kOrange,
      secondary: kYellow,
      surface: kDarkSurface,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: kDarkSurface,
      foregroundColor: kYellow,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(color: kYellow, fontSize: 18, fontWeight: FontWeight.bold),
      iconTheme: const IconThemeData(color: kYellow),
    ),
    cardTheme: CardThemeData(
      color: kDarkSurface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kBrown.withValues(alpha: 0.4)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kDarkFieldBg,
      hintStyle: TextStyle(color: kYellow.withValues(alpha: 0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kBrown.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kBrown.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kOrange, width: 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kDarkSurface,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kOrange,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// Ancho seguro para el `content` de un AlertDialog: nunca más ancho que
/// la pantalla (evita el overflow en celulares angostos), pero tampoco
/// exagerado en pantallas grandes/tablets/web.
double dialogWidth(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  return (screenWidth - 64).clamp(260.0, 420.0);
}

/// Formatea montos como pesos mexicanos explícitos: "$1,234.50 MXN"
/// (mismo formato que ya usa erp-app.js en la versión web).
String money(num? n) {
  final v = (n ?? 0).toDouble();
  final s = v.toStringAsFixed(2);
  final parts = s.split('.');
  final negativo = parts[0].startsWith('-');
  final soloDigitos = negativo ? parts[0].substring(1) : parts[0];
  final conComas = soloDigitos.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '${negativo ? '-' : ''}\$$conComas.${parts[1]} MXN';
}



