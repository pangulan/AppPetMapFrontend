import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'publicacion_service.dart';
import 'session_storage.dart';

class AvisoEstado {
  const AvisoEstado({
    required this.especie,
    required this.estado,
    this.motivo,
  });

  final String especie;
  final String estado; // APROBADA o RECHAZADA
  final String? motivo;
}

class AvisoCercano {
  const AvisoCercano({
    required this.pub,
    required this.km,
    required this.nuevo,
  });

  final Map<String, dynamic> pub;
  final double km;
  final bool nuevo;
}

class ResultadoAvisos {
  const ResultadoAvisos({
    required this.estados,
    required this.cercanos,
    required this.ubicacionActiva,
    required this.estadosActuales,
    required this.idsCercanos,
  });

  final List<AvisoEstado> estados;
  final List<AvisoCercano> cercanos;
  final bool ubicacionActiva;
  final Map<String, String> estadosActuales;
  final List<int> idsCercanos;

  int get pendientes => estados.length + cercanos.where((c) => c.nuevo).length;
}

class NotificacionesService {
  static const double radioKm = 5;

  final _publicaciones = PublicacionService();
  final _session = SessionStorage();

  Future<String> _claveUsuario() async {
    final u = await _session.leerUsuario();
    return '${u?['id'] ?? 'x'}';
  }

  Future<LatLng?> _ubicacion({required bool pedir}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied && pedir) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso != LocationPermission.whileInUse &&
          permiso != LocationPermission.always) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<ResultadoAvisos> calcular({bool pedirUbicacion = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final usuario = await _claveUsuario();
    final claveEstados = 'avisos_estados_$usuario';
    final claveCercanas = 'avisos_cercanas_$usuario';

    // ---- HU016: cambios de estado de mis publicaciones ----
    final mias = await _publicaciones.misPublicaciones();
    final actuales = <String, String>{
      for (final p in mias) '${p['id']}': '${p['estado']}',
    };
    final rawEstados = prefs.getString(claveEstados);
    final avisosEstado = <AvisoEstado>[];
    if (rawEstados == null) {
      // Primera vez: se toma una foto del estado actual, sin avisar.
      await prefs.setString(claveEstados, jsonEncode(actuales));
    } else {
      final vistos = (jsonDecode(rawEstados) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, '$v'));
      for (final p in mias) {
        final id = '${p['id']}';
        final estado = '${p['estado']}';
        if (vistos[id] == estado) continue;
        if (estado == 'APROBADA' || estado == 'RECHAZADA') {
          avisosEstado.add(AvisoEstado(
            especie: '${p['especie']}',
            estado: estado,
            motivo: p['motivoRechazo'] as String?,
          ));
        }
      }
    }

    // ---- HU017: publicaciones aprobadas cerca de mí ----
    final misIds = mias.map((p) => (p['id'] as num).toInt()).toSet();
    final posicion = await _ubicacion(pedir: pedirUbicacion);
    final cercanos = <AvisoCercano>[];
    final idsCercanos = <int>[];
    if (posicion != null) {
      final aprobadas = await _publicaciones.aprobadas();
      final rawVistas = prefs.getString(claveCercanas);
      final vistas = rawVistas == null
          ? null
          : (jsonDecode(rawVistas) as List)
              .map((e) => (e as num).toInt())
              .toSet();
      for (final p in aprobadas) {
        final id = (p['id'] as num).toInt();
        if (misIds.contains(id)) continue;
        final destino = LatLng(
          (p['latitud'] as num).toDouble(),
          (p['longitud'] as num).toDouble(),
        );
        final km =
            const Distance().as(LengthUnit.Kilometer, posicion, destino);
        if (km > radioKm) continue;
        idsCercanos.add(id);
        cercanos.add(AvisoCercano(
          pub: p,
          km: km,
          nuevo: vistas != null && !vistas.contains(id),
        ));
      }
      cercanos.sort((a, b) => a.km.compareTo(b.km));
      if (rawVistas == null) {
        await prefs.setString(claveCercanas, jsonEncode(idsCercanos));
      }
    }

    return ResultadoAvisos(
      estados: avisosEstado,
      cercanos: cercanos,
      ubicacionActiva: posicion != null,
      estadosActuales: actuales,
      idsCercanos: idsCercanos,
    );
  }

  /// Marca todo como visto, para que la campana vuelva a cero.
  Future<void> marcarVistos(ResultadoAvisos r) async {
    final prefs = await SharedPreferences.getInstance();
    final usuario = await _claveUsuario();
    await prefs.setString(
        'avisos_estados_$usuario', jsonEncode(r.estadosActuales));
    if (r.ubicacionActiva) {
      await prefs.setString(
          'avisos_cercanas_$usuario', jsonEncode(r.idsCercanos));
    }
  }
}