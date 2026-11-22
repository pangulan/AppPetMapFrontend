import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import 'session_storage.dart';

class ComunidadService {
  final _session = SessionStorage();

  Future<Map<String, String>> _cabeceras() async {
    final token = await _session.leerToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Exception? _errorAcceso(http.Response r) {
    if (r.statusCode == 401) {
      return Exception('Tu sesión venció. Cierra sesión y vuelve a entrar.');
    }
    if (r.statusCode == 403) {
      return Exception('No tienes permiso para esta acción.');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> comentarios(int publicacionId) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConfig.baseUrl}/api/comentarios?publicacionId=$publicacionId'),
      headers: await _cabeceras(),
    );
    final acceso = _errorAcceso(response);
    if (acceso != null) throw acceso;
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(
        'No se pudieron cargar los comentarios (${response.statusCode})');
  }

  Future<void> comentar({
    required int publicacionId,
    required String texto,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/comentarios'),
      headers: await _cabeceras(),
      body: utf8.encode(
          jsonEncode({'publicacionId': publicacionId, 'texto': texto})),
    );
    final acceso = _errorAcceso(response);
    if (acceso != null) throw acceso;
    if (response.statusCode == 201) return;
    if (response.statusCode == 400) {
      throw Exception('Escribe un comentario de hasta 300 caracteres');
    }
    if (response.statusCode == 404) {
      throw Exception('La publicación ya no está disponible');
    }
    if (response.statusCode == 409) {
      throw Exception('Solo se puede comentar en publicaciones aprobadas');
    }
    throw Exception('Error inesperado (${response.statusCode})');
  }

  Future<void> borrarComentario(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/comentarios/$id'),
      headers: await _cabeceras(),
    );
    final acceso = _errorAcceso(response);
    if (acceso != null) throw acceso;
    if (response.statusCode == 204) return;
    if (response.statusCode == 404) {
      throw Exception('El comentario ya no existe');
    }
    throw Exception('Error inesperado (${response.statusCode})');
  }

  Future<void> actualizarPerfil({
    required String nombre,
    String? telefono,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/perfil'),
      headers: await _cabeceras(),
      body: utf8.encode(jsonEncode({'nombre': nombre, 'telefono': telefono})),
    );
    final acceso = _errorAcceso(response);
    if (acceso != null) throw acceso;
    if (response.statusCode == 400) {
      throw Exception('Revisa los datos: el nombre es obligatorio');
    }
    if (response.statusCode != 200) {
      throw Exception('Error inesperado (${response.statusCode})');
    }

    // Se actualizan los datos guardados en el celular.
    final nuevos =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final token = await _session.leerToken();
    final actual = await _session.leerUsuario() ?? <String, dynamic>{};
    if (token != null) {
      await _session.guardar(token: token, usuario: {...actual, ...nuevos});
    }
  }
}