import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const _tokenKey = 'token';
  static const _usuarioKey = 'usuario';

  Future<void> guardar({
    required String token,
    required Map<String, dynamic> usuario,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usuarioKey, jsonEncode(usuario));
  }

  Future<String?> leerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>?> leerUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usuarioKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> cerrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usuarioKey);
  }
}