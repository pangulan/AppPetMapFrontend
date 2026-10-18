import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class AuthService {
  Future<void> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
    String? telefono,
  }) async {
    final cuerpo = jsonEncode({
      'nombre': nombre,
      'correo': correo,
      'contrasena': contrasena,
      'telefono': telefono,
    });
    debugPrint('>>> POST registro: $cuerpo');

      final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/usuarios/registro'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: utf8.encode(cuerpo),
    );

    final respuesta = utf8.decode(response.bodyBytes);
    debugPrint('<<< ${response.statusCode}: $respuesta');

    if (response.statusCode == 201) return;

    if (response.statusCode == 409) {
      throw Exception('El correo ya está registrado');
    }

    if (response.statusCode == 400) {
      throw Exception('400 -> $respuesta');
    }

    throw Exception('Error inesperado (${response.statusCode})');
  }
}