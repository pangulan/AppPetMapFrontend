import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../services/publicacion_service.dart';
import 'comentarios_seccion.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _servicio = PublicacionService();
  List<Map<String, dynamic>> _items = [];
  bool _cargando = true;
  String? _error;
  bool _verMapa = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final items = await _servicio.aprobadas();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Color _colorTipo(String? tipo) =>
      tipo == 'PERDIDA' ? Colors.deepOrange.shade700 : Colors.teal.shade700;

  String _textoTipo(String? tipo) => tipo == 'PERDIDA' ? 'Perdida' : 'Encontrada';

  LatLng _punto(Map<String, dynamic> p) => LatLng(
        (p['latitud'] as num).toDouble(),
        (p['longitud'] as num).toDouble(),
      );

  void _abrirDetalle(Map<String, dynamic> pub) {
    final tipo = pub['tipo'] as String?;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DetalleSheet(
        pub: pub,
        servicio: _servicio,
        colorTipo: _colorTipo(tipo),
        textoTipo: _textoTipo(tipo),
      ),
    );
  }

  Widget _mapa() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: _punto(_items.first),
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.petmap_frontend',
        ),
        MarkerLayer(
          markers: [
            for (final p in _items)
              Marker(
                point: _punto(p),
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () => _abrirDetalle(p),
                  child: Icon(
                    Icons.location_on,
                    size: 44,
                    color: _colorTipo(p['tipo'] as String?),
                  ),
                ),
              ),
          ],
        ),
        RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  Widget _lista() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final p = _items[i];
        final tipo = p['tipo'] as String?;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => _abrirDetalle(p),
            leading: Icon(Icons.location_on, color: _colorTipo(tipo), size: 36),
            title: Text('${p['especie']} · ${_textoTipo(tipo)}'),
            subtitle: Text(
              '${p['descripcion']}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _contenido() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 72, color: AppColors.secondary),
              SizedBox(height: 16),
              Text(
                'Todavía no hay publicaciones aprobadas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return _verMapa ? _mapa() : _lista();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            24,
            MediaQuery.of(context).padding.top + 24,
            12,
            24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mascotas reportadas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cargando
                          ? 'Cargando…'
                          : '${_items.length} publicaciones activas',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: _cargando ? null : _cargar,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Mapa'),
                icon: Icon(Icons.map_outlined),
              ),
              ButtonSegment(
                value: false,
                label: Text('Lista'),
                icon: Icon(Icons.list),
              ),
            ],
            selected: {_verMapa},
            onSelectionChanged: (s) => setState(() => _verMapa = s.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(child: _contenido()),
      ],
    );
  }
}

class _DetalleSheet extends StatefulWidget {
  const _DetalleSheet({
    required this.pub,
    required this.servicio,
    required this.colorTipo,
    required this.textoTipo,
  });

  final Map<String, dynamic> pub;
  final PublicacionService servicio;
  final Color colorTipo;
  final String textoTipo;

  @override
  State<_DetalleSheet> createState() => _DetalleSheetState();
}

class _DetalleSheetState extends State<_DetalleSheet> {
  Future<String?>? _futuroFoto;
  Future<Map<String, dynamic>>? _futuroContacto;

  @override
  void initState() {
    super.initState();
    if (widget.pub['tieneFoto'] == true) {
      _futuroFoto = widget.servicio.fotoDe((widget.pub['id'] as num).toInt());
    }
  }

  Widget _foto(String? foto) {
    final placeholder = Container(
      height: 200,
      width: double.infinity,
      color: const Color(0x1AFF7A59),
      child: const Icon(Icons.pets, size: 56, color: AppColors.primary),
    );
    if (foto == null || foto.isEmpty) return placeholder;
    try {
      return Image.memory(
        base64Decode(foto),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } catch (_) {
      return placeholder;
    }
  }

  Widget _fila(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(texto, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaContacto(Map<String, dynamic> c) {
    final telefono = (c['telefono'] as String?) ?? '';
    final correo = (c['correo'] as String?) ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x144ECDC4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${c['nombre'] ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (telefono.isNotEmpty) _fila(Icons.phone_outlined, telefono),
          if (correo.isNotEmpty) _fila(Icons.email_outlined, correo),
          const SizedBox(height: 6),
          const Text(
            'Mantén presionado un dato para copiarlo.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pub = widget.pub;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _futuroFoto == null
                  ? _foto(null)
                  : FutureBuilder<String?>(
                      future: _futuroFoto,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _foto(snap.data);
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.colorTipo.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.textoTipo,
                style: TextStyle(
                  color: widget.colorTipo,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${pub['especie']}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${pub['descripcion']}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${pub['fecha']}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_futuroContacto == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() {
                    _futuroContacto = widget.servicio
                        .contactoDe((widget.pub['id'] as num).toInt());
                  }),
                  icon: const Icon(Icons.contact_phone_outlined),
                  label: const Text('Ver contacto de quien publicó'),
                ),
              )
            else
              FutureBuilder<Map<String, dynamic>>(
                future: _futuroContacto,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return Text(
                      snap.error.toString().replaceFirst('Exception: ', ''),
                      style: const TextStyle(color: AppColors.error),
                    );
                  }
                  return _tarjetaContacto(snap.data!);
                },
              ),
                          const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            ComentariosSeccion(publicacionId: (pub['id'] as num).toInt()),
          ],
        ),
      ),
    );
  }
}