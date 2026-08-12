/// Validaciones de formulario reutilizables en todo el ERP.

/// Correo OBLIGATORIO y con formato válido (para el registro del admin).
String? validarCorreo(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'El correo es requerido.';
  final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
  if (!regex.hasMatch(valor.trim())) return 'Correo inválido.';
  return null;
}

/// Correo OPCIONAL — si se deja vacío no marca error, pero si se escribe
/// algo, debe tener formato válido. Para Clientes/Proveedores, donde el
/// correo no es obligatorio.
String? validarCorreoOpcional(String? valor) {
  if (valor == null || valor.trim().isEmpty) return null;
  final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
  if (!regex.hasMatch(valor.trim())) return 'Correo inválido.';
  return null;
}

/// Teléfono OPCIONAL — si se escribe algo, debe ser exactamente 10 dígitos
/// (formato mexicano). Se permiten espacios/guiones al escribir, pero se
/// cuentan solo los dígitos.
String? validarTelefonoOpcional(String? valor) {
  if (valor == null || valor.trim().isEmpty) return null;
  final soloDigitos = valor.replaceAll(RegExp(r'[^0-9]'), '');
  if (soloDigitos.length != 10) {
    return 'El teléfono debe tener 10 dígitos.';
  }
  return null;
}

String? validarRequerido(String? valor, {String campo = 'Este campo'}) {
  if (valor == null || valor.trim().isEmpty) return '$campo es requerido.';
  return null;
}

/// Nombre OBLIGATORIO: solo letras, espacios, acentos, apóstrofes y
/// guiones (para nombres compuestos tipo "Pérez-Gómez" o "O'Brien").
/// Bloquea números y símbolos, exige mínimo 3 caracteres, y rechaza
/// cadenas con más de 4 consonantes seguidas (heurística contra
/// machaqueo de teclado tipo "qojdbwksoidud"). No es infalible —
/// no existe forma de verificar al 100% que un nombre es "real" sin
/// un diccionario o IA — pero bloquea la gran mayoría de basura.
String? validarNombreValido(String? valor, {String campo = 'Este campo'}) {
  if (valor == null || valor.trim().isEmpty) return '$campo es requerido.';
  final texto = valor.trim();
  if (texto.length < 3) return '$campo debe tener al menos 3 caracteres.';

  final soloLetras = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿÑñ\s'\-]+$");
  if (!soloLetras.hasMatch(texto)) {
    return '$campo solo debe contener letras.';
  }

  const vocales = 'aeiouáéíóúüAEIOUÁÉÍÓÚÜ';
  final letras = texto.replaceAll(RegExp(r"[\s'\-]"), '');
  int consecutivas = 0;
  for (final ch in letras.split('')) {
    if (vocales.contains(ch)) {
      consecutivas = 0;
    } else {
      consecutivas++;
      if (consecutivas > 4) return '$campo no parece un nombre válido.';
    }
  }
  return null;
}

/// Número decimal obligatorio y no negativo (precios, costos).
String? validarNumeroNoNegativo(String? valor, {String campo = 'Este campo'}) {
  if (valor == null || valor.trim().isEmpty) return '$campo es requerido.';
  final n = double.tryParse(valor.trim());
  if (n == null) return '$campo debe ser un número válido.';
  if (n < 0) return '$campo no puede ser negativo.';
  return null;
}

/// Número entero obligatorio y no negativo (stock, cantidades).
String? validarEnteroNoNegativo(String? valor, {String campo = 'Este campo'}) {
  if (valor == null || valor.trim().isEmpty) return '$campo es requerido.';
  final n = int.tryParse(valor.trim());
  if (n == null) return '$campo debe ser un número entero válido.';
  if (n < 0) return '$campo no puede ser negativo.';
  return null;
}

/// Número entero obligatorio y mayor a cero (cantidades en ventas/compras).
String? validarEnteroPositivo(String? valor, {String campo = 'La cantidad'}) {
  if (valor == null || valor.trim().isEmpty) return '$campo es requerida.';
  final n = int.tryParse(valor.trim());
  if (n == null) return '$campo debe ser un número entero válido.';
  if (n <= 0) return '$campo debe ser mayor a 0.';
  return null;
}

/// Distancia de Levenshtein entre dos cadenas: número mínimo de ediciones
/// (insertar, borrar, cambiar una letra) para convertir una en la otra.
int _distanciaLevenshtein(String a, String b) {
  final m = a.length, n = b.length;
  final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
  for (var i = 0; i <= m; i++) dp[i][0] = i;
  for (var j = 0; j <= n; j++) dp[0][j] = j;
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      final costo = a[i - 1] == b[j - 1] ? 0 : 1;
      final borrar = dp[i - 1][j] + 1;
      final insertar = dp[i][j - 1] + 1;
      final cambiar = dp[i - 1][j - 1] + costo;
      dp[i][j] = [borrar, insertar, cambiar].reduce((x, y) => x < y ? x : y);
    }
  }
  return dp[m][n];
}

/// Compara dos nombres de producto y determina si son sospechosamente
/// parecidos (posible duplicado con variación de escritura, como
/// "Paleta Payaso" vs "Paletas Payaso"). Normaliza a minúsculas antes
/// de comparar y usa un umbral relativo al largo del nombre: nombres
/// cortos exigen coincidencia casi exacta, nombres largos toleran un
/// poco más de diferencia.
bool sonNombresParecidos(String a, String b) {
  final x = a.trim().toLowerCase();
  final y = b.trim().toLowerCase();
  if (x.isEmpty || y.isEmpty) return false;
  if (x == y) return true;
  final distancia = _distanciaLevenshtein(x, y);
  final largoMax = x.length > y.length ? x.length : y.length;
  final umbral = (largoMax * 0.25).ceil().clamp(1, 4);
  return distancia <= umbral;
}

