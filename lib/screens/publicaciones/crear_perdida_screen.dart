import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../services/publicacion_service.dart';

class CrearPerdidaScreen extends StatefulWidget {
  const CrearPerdidaScreen({super.key});

  @override
  State<CrearPerdidaScreen> createState() => _CrearPerdidaScreenState();
}

class _CrearPerdidaScreenState extends State<CrearPerdidaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _especieCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _servicio = PublicacionService();
  final _picker = ImagePicker();

  DateTime? _fecha;
  Uint8List? _fotoBytes;
  double? _latitud;
  double? _longitud;
  bool _obteniendoUbicacion = false;
  bool _cargando = false;

  @override
  void dispose() {
    _especieCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // ---------- Foto (opcional) ----------
  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(ctx);
                _elegirFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _elegirFoto(ImageSource.camera);
              },
            ),
            if (_fotoBytes != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Quitar foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _fotoBytes = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _elegirFoto(ImageSource origen) async {
    try {
      final imagen = await _picker.pickImage(
        source: origen,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (imagen == null) return;
      final bytes = await imagen.readAsBytes();
      if (!mounted) return;
      setState(() => _fotoBytes = bytes);
    } catch (_) {
      _mensaje('No se pudo cargar la foto');
    }
  }

  // ---------- Ubicación ----------
  Future<void> _obtenerUbicacion() async {
    setState(() => _obteniendoUbicacion = true);
    try {
      final activo = await Geolocator.isLocationServiceEnabled();
      if (!activo) {
        _mensaje('Activa la ubicación del dispositivo');
        return;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        _mensaje('Necesitamos el permiso de ubicación para continuar');
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() {
        _latitud = posicion.latitude;
        _longitud = posicion.longitude;
      });
    } catch (_) {
      _mensaje('No se pudo obtener la ubicación. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _obteniendoUbicacion = false);
    }
  }

  // ---------- Fecha ----------
  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      firstDate: DateTime(hoy.year - 1),
      lastDate: hoy,
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  // ---------- Publicar ----------
  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitud == null || _longitud == null) {
      _mensaje('Toca "Usar mi ubicación actual"');
      return;
    }
    if (_fecha == null) {
      _mensaje('Selecciona la fecha en que se perdió');
      return;
    }

    setState(() => _cargando = true);
    try {
      await _servicio.crearPerdida(
        especie: _especieCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        foto: _fotoBytes == null ? null : base64Encode(_fotoBytes!),
        latitud: _latitud!,
        longitud: _longitud!,
        fecha: _fecha!,
      );
      if (!mounted) return;
      _mensaje('Publicación enviada. Quedó pendiente de revisión.');
      Navigator.of(context).pop();
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textoFecha = _fecha == null
        ? 'Selecciona la fecha en que se perdió'
        : _fecha!.toIso8601String().substring(0, 10);
    final ubicacionLista = _latitud != null && _longitud != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Mascota perdida')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              InkWell(
                onTap: _mostrarOpcionesFoto,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: _fotoBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 40, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text('Agregar foto (opcional)'),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _fotoBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _especieCtrl,
                decoration:
                    const InputDecoration(labelText: 'Especie (perro, gato...)'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'La especie es obligatoria'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'La descripción es obligatoria'
                    : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _elegirFecha,
                icon: const Icon(Icons.calendar_today),
                label: Text(textoFecha),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _obteniendoUbicacion ? null : _obtenerUbicacion,
                icon: _obteniendoUbicacion
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        ubicacionLista ? Icons.check_circle : Icons.my_location,
                        color: ubicacionLista ? AppColors.secondary : null,
                      ),
                label: Text(ubicacionLista
                    ? 'Ubicación obtenida ✓'
                    : 'Usar mi ubicación actual'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _publicar,
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Publicar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}