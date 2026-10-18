import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import 'session_storage.dart';

class AuthService {
  final _session = SessionStorage();

  Future<void> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
    String? telefono,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/usuarios/registro'),
      headers: {'Content-Type': 'application/json'},
      body: utf8.encode(jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
        'telefono': telefono,
      })),
    );

    if (response.statusCode == 201) return;
    if (response.statusCode == 409) {
      throw Exception('El correo ya está registrado');
    }
    if (response.statusCode == 400) {
      throw Exception(_detalleValidacion(response));
    }
    throw Exception('Error inesperado (${response.statusCode})');
  }

  Future<Map<String, dynamic>> login({
    required String correo,
    required String contrasena,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/usuarios/login'),
      headers: {'Content-Type': 'application/json'},
      body: utf8.encode(jsonEncode({
        'correo': correo,
        'contrasena': contrasena,
      })),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final usuario = data['usuario'] as Map<String, dynamic>;
      await _session.guardar(token: data['token'] as String, usuario: usuario);
      return usuario;
    }
    if (response.statusCode == 401) {
      throw Exception('Correo o contraseña incorrectos');
    }
    if (response.statusCode == 400) {
      throw Exception(_detalleValidacion(response));
    }
    throw Exception('Error inesperado (${response.statusCode})');
  }

  String _detalleValidacion(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final violations = data['violations'] as List?;
      if (violations != null && violations.isNotEmpty) {
        return violations
            .map((v) => '${v['field']}: ${v['message']}')
            .join('\n');
      }
    } catch (_) {}
    return 'Revisa los datos ingresados';
  }
}