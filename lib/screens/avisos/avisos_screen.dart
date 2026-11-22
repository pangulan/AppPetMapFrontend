import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/notificaciones_service.dart';

class AvisosScreen extends StatefulWidget {
  const AvisosScreen({super.key});

  @override
  State<AvisosScreen> createState() => _AvisosScreenState();
}

class _AvisosScreenState extends State<AvisosScreen> {
  final _servicio = NotificacionesService();
  ResultadoAvisos? _resultado;
  bool _cargando = true;
  bool _buscando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar({bool pedirUbicacion = false}) async {
    setState(() {
      _cargando = _resultado == null;
      _buscando = pedirUbicacion;
      _error = null;
    });
    try {
      final r = await _servicio.calcular(pedirUbicacion: pedirUbicacion);
      if (!mounted) return;
      setState(() => _resultado = r);
      await _servicio.marcarVistos(r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
          _buscando = false;
        });
      }
    }
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(
          texto,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      );

  Widget _vacio(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          texto,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );

  Widget _avisoEstado(AvisoEstado a) {
    final aprobada = a.estado == 'APROBADA';
    final motivo = (a.motivo ?? '').trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          aprobada ? Icons.check_circle : Icons.cancel,
          color: aprobada ? Colors.green.shade700 : Colors.red.shade700,
          size: 32,
        ),
        title: Text(
          aprobada
              ? 'Tu publicación de ${a.especie} fue aprobada'
              : 'Tu publicación de ${a.especie} fue rechazada',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          aprobada
              ? 'Ya la puede ver toda la comunidad en el mapa.'
              : (motivo.isEmpty ? 'Revisa Mis publicaciones.' : 'Motivo: $motivo'),
        ),
      ),
    );
  }

  Widget _avisoCercano(AvisoCercano c) {
    final tipo = c.pub['tipo'] as String?;
    final color =
        tipo == 'PERDIDA' ? Colors.deepOrange.shade700 : Colors.teal.shade700;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(Icons.location_on, color: color, size: 32),
        title: Text(
          '${c.pub['especie']} · ${tipo == 'PERDIDA' ? 'Perdida' : 'Encontrada'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('A ${c.km.toStringAsFixed(1)} km de ti'),
        trailing: c.nuevo
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Nuevo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _seccionCercanas(ResultadoAvisos r) {
    if (!r.ubicacionActiva) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activa tu ubicación para ver las mascotas reportadas a menos de 5 km de ti.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _buscando ? null : () => _cargar(pedirUbicacion: true),
                icon: _buscando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Activar avisos cercanos'),
              ),
            ],
          ),
        ),
      );
    }
    if (r.cercanos.isEmpty) {
      return _vacio('No hay mascotas reportadas a menos de 5 km de ti.');
    }
    return Column(children: [for (final c in r.cercanos) _avisoCercano(c)]);
  }

  @override
  Widget build(BuildContext context) {
    final r = _resultado;
    Widget cuerpo;
    if (_cargando) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (r == null) {
      cuerpo = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'No se pudieron cargar los avisos',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    } else {
      cuerpo = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _titulo('Tus publicaciones'),
          if (r.estados.isEmpty)
            _vacio('No hay novedades en tus publicaciones.')
          else
            for (final a in r.estados) _avisoEstado(a),
          const SizedBox(height: 8),
          _titulo('Mascotas cerca de ti'),
          _seccionCercanas(r),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : () => _cargar(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: cuerpo,
    );
  }
}