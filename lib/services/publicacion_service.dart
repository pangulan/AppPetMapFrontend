import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import 'session_storage.dart';

class PublicacionService {
  final _session = SessionStorage();

  Future<int> _autorId() async {
    final usuario = await _session.leerUsuario();
    final id = usuario?['id'];
    if (id == null) {
      throw Exception('Sesión no válida, inicia sesión de nuevo');
    }
    return (id as num).toInt();
  }

  Future<void> crearEncontrada({
    required String especie,
    required String descripcion,
    required String foto,
    required double latitud,
    required double longitud,
    required DateTime fecha,
  }) async {
    final autorId = await _autorId();

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

  Future<List<Map<String, dynamic>>> misPublicaciones() async {
    final autorId = await _autorId();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/publicaciones/mias?autorId=$autorId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(
        'No se pudieron cargar tus publicaciones (${response.statusCode})');
  }

  Future<void> eliminar({
    required int publicacionId,
    required String motivo,
  }) async {
    final autorId = await _autorId();

    final response = await http.post(
      Uri.parse(
          '${ApiConfig.baseUrl}/api/publicaciones/$publicacionId/eliminar'),
      headers: {'Content-Type': 'application/json'},
      body: utf8.encode(jsonEncode({'motivo': motivo, 'autorId': autorId})),
    );

    if (response.statusCode == 204) return;
    if (response.statusCode == 403) {
      throw Exception('Solo el autor puede eliminar esta publicación');
    }
    if (response.statusCode == 404) {
      throw Exception('La publicación no existe');
    }
    if (response.statusCode == 409) {
      throw Exception('La publicación ya fue eliminada');
    }
    if (response.statusCode == 400) {
      throw Exception(_detalleValidacion(response));
    }
    throw Exception('Error inesperado (${response.statusCode})');
  }

  Future<void> crearPerdida({
    required String especie,
    required String descripcion,
    String? foto,
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
      Uri.parse('${ApiConfig.baseUrl}/api/publicaciones/perdida'),
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


    Future<void> editar({
      required int publicacionId,
      String? descripcion,
      String? foto,
      double? latitud,
      double? longitud,
    }) async {
      final cuerpo = <String, dynamic>{};
      if (descripcion != null) cuerpo['descripcion'] = descripcion;
      if (foto != null) cuerpo['foto'] = foto;
      if (latitud != null) cuerpo['latitud'] = latitud;
      if (longitud != null) cuerpo['longitud'] = longitud;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/publicaciones/$publicacionId'),
        headers: {'Content-Type': 'application/json'},
        body: utf8.encode(jsonEncode(cuerpo)),
      );

      if (response.statusCode == 200) return;
      if (response.statusCode == 404) {
        throw Exception('La publicación no existe');
      }
      if (response.statusCode == 409) {
        throw Exception('Esta publicación ya no se puede editar en su estado actual');
      }
      if (response.statusCode == 400) {
        throw Exception(_detalleValidacion(response));
      }
      throw Exception('Error inesperado (${response.statusCode})');
    }

     Future<void> marcarResuelta({required int publicacionId}) async {
       final autorId = await _autorId();

       final response = await http.put(
         Uri.parse(
             '${ApiConfig.baseUrl}/api/publicaciones/$publicacionId/resuelta'),
         headers: {'Content-Type': 'application/json'},
         body: utf8.encode(jsonEncode({'autorId': autorId})),
       );

       if (response.statusCode == 200) return;
       if (response.statusCode == 403) {
         throw Exception('Solo el autor puede marcar esta publicación como resuelta');
       }
       if (response.statusCode == 404) {
         throw Exception('La publicación no existe');
       }
       if (response.statusCode == 409) {
         throw Exception(
             'Solo las publicaciones de mascota perdida se pueden marcar como resueltas');
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