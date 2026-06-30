import 'package:shared_preferences/shared_preferences.dart';

class BackendConfig {
  static const String _claveUrl = 'backend_url';

  /// Texto de ejemplo, solo visual (no se usa como valor real de conexión).
  static const String placeholderEjemplo = '0.0.0.0:5000';

  /// Obtiene la URL guardada. Devuelve cadena vacía si el usuario nunca configuró nada.
  static Future<String> obtenerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_claveUrl) ?? '';
  }

  /// Guarda una nueva URL de forma persistente.
  static Future<void> guardarUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    String urlLimpia = url.trim();
    if (urlLimpia.endsWith('/')) {
      urlLimpia = urlLimpia.substring(0, urlLimpia.length - 1);
    }
    await prefs.setString(_claveUrl, urlLimpia);
  }
}
