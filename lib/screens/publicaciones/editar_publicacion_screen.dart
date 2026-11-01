import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../services/publicacion_service.dart';

class EditarPublicacionScreen extends StatefulWidget {
  final Map<String, dynamic> publicacion;

  const EditarPublicacionScreen({super.key, required this.publicacion});

  @override
  State<EditarPublicacionScreen> createState() =>
      _EditarPublicacionScreenState();
}

class _EditarPublicacionScreenState extends State<EditarPublicacionScreen> {
  final _servicio = PublicacionService();
  late final TextEditingController _descCtrl;
  late final String _descripcionOriginal;

  Uint8List? _fotoNueva;
  String? _fotoNuevaBase64;
  double? _lat;
  double? _lng;
  bool _obteniendoUbicacion = false;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _descripcionOriginal = '${widget.publicacion['descripcion'] ?? ''}';
    _descCtrl = TextEditingController(text: _descripcionOriginal);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Uint8List? _bytesFotoActual() {
    final foto = widget.publicacion['foto'];
    if (foto is String && foto.isNotEmpty) {
      try {
        return base64Decode(foto);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _elegirFoto() async {
    try {
      final archivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 80,
      );
      if (archivo == null) return;
      final bytes = await archivo.readAsBytes();
      if (!mounted) return;
      setState(() {
        _fotoNueva = bytes;
        _fotoNuevaBase64 = base64Encode(bytes);
      });
    } catch (e) {
      _mensaje('No se pudo cargar la foto');
    }
  }

  Future<void> _obtenerUbicacion() async {
    setState(() => _obteniendoUbicacion = true);
    try {
      final activo = await Geolocator.isLocationServiceEnabled();
      if (!activo) {
        throw Exception('Activa los servicios de ubicación');
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación denegado');
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _obteniendoUbicacion = false);
    }
  }

  Future<void> _guardar() async {
    final descripcion = _descCtrl.text.trim();
    if (descripcion.isEmpty) {
      setState(() => _error = 'La descripción no puede estar vacía');
      return;
    }

    final cambioDescripcion = descripcion != _descripcionOriginal;
    final cambioFoto = _fotoNuevaBase64 != null;
    final cambioUbicacion = _lat != null && _lng != null;

    if (!cambioDescripcion && !cambioFoto && !cambioUbicacion) {
      setState(() => _error = 'No hiciste ningún cambio');
      return;
    }

    setState(() {
      _error = null;
      _guardando = true;
    });

    try {
      await _servicio.editar(
        publicacionId: (widget.publicacion['id'] as num).toInt(),
        descripcion: cambioDescripcion ? descripcion : null,
        foto: _fotoNuevaBase64,
        latitud: _lat,
        longitud: _lng,
      );
      if (!mounted) return;
      _mensaje('Publicación actualizada');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _vistaFoto() {
    final bytes = _fotoNueva ?? _bytesFotoActual();
    return InkWell(
      onTap: _elegirFoto,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: bytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(bytes, fit: BoxFit.cover),
                  const Positioned(
                    right: 8,
                    bottom: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.edit, color: Colors.white),
                    ),
                  ),
                ],
              )
            : const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo, size: 40, color: AppColors.primary),
                    SizedBox(height: 8),
                    Text('Agregar foto'),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pub = widget.publicacion;
    return Scaffold(
      appBar: AppBar(title: const Text('Editar publicación')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _vistaFoto(),
          const SizedBox(height: 16),
          Text(
            '${pub['especie'] ?? ''} · ${pub['tipo'] ?? ''}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _obteniendoUbicacion ? null : _obtenerUbicacion,
            icon: Icon(
              _lat != null ? Icons.check_circle : Icons.my_location,
              color: AppColors.primary,
            ),
            label: Text(
              _lat != null
                  ? 'Nueva ubicación lista ✓'
                  : 'Actualizar a mi ubicación actual (opcional)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }
}