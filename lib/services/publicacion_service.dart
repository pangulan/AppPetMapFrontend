import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import 'session_storage.dart';

class PublicacionService {
  final _session = SessionStorage();

  Future<void> crearEncontrada({
    required String especie,
    required String descripcion,
    required String foto,
    required double latitud,
    required double longitud,
    required DateTime fecha,
  }) async {
    final usuario = await _session.leerUsuario();
    final autorId = usuario?['id'];
    if (autorId == null) {
      throw Exception('Sesión no válida, inicia sesión de nuevo');
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/publicaciones/encontrada'),
      headers: {'Content-Type': 'application/json'},
      body: utf8.encode(jsonEncode({
        'especie': especie,
        'descripcion': descripcion,
        'foto': foto,
        'latitud': latitud,
        'longitud': longitud,
        'fecha': fecha.toIso8601String().substring(0, 10),
        'autorId': autorId,
      })),
    );

    if (response.statusCode == 201) return;
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
        return violations.map((v) => v['message']).join('\n');
      }
    } catch (_) {}
    return 'Revisa los datos ingresados';
  }
}