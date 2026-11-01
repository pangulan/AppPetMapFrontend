import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/publicacion_service.dart';

class ModeracionScreen extends StatefulWidget {
  const ModeracionScreen({super.key});

  @override
  State<ModeracionScreen> createState() => _ModeracionScreenState();
}

class _ModeracionScreenState extends State<ModeracionScreen> {
  final _servicio = PublicacionService();
  List<Map<String, dynamic>> _items = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final items = await _servicio.pendientes();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _aprobar(Map<String, dynamic> pub) async {
    try {
      await _servicio.aprobar(publicacionId: (pub['id'] as num).toInt());
      _mensaje('Publicación aprobada');
      await _cargar();
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _rechazar(Map<String, dynamic> pub) async {
    final ctrl = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar publicación'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Motivo (obligatorio)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final texto = ctrl.text.trim();
              if (texto.isEmpty) return;
              Navigator.pop(ctx, texto);
            },
            child: const Text('Rechazar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (motivo == null) return;

    try {
      await _servicio.rechazar(
        publicacionId: (pub['id'] as num).toInt(),
        motivo: motivo,
      );
      _mensaje('Publicación rechazada');
      await _cargar();
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _miniatura(String? foto) {
    const icono = Icon(Icons.pets, size: 40, color: AppColors.primary);
    if (foto != null && foto.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(foto),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => icono,
          ),
        );
      } catch (_) {}
    }
    return icono;
  }

  @override
  Widget build(BuildContext context) {
    Widget cuerpo;
    if (_cargando) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      cuerpo = Center(
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
    } else if (_items.isEmpty) {
      cuerpo = const Center(child: Text('No hay publicaciones pendientes'));
    } else {
      cuerpo = RefreshIndicator(
        onRefresh: _cargar,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (context, i) {
            final pub = _items[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: _miniatura(pub['foto'] as String?),
                title: Text('${pub['especie']} · ${pub['tipo']}'),
                subtitle: Text(
                  '${pub['descripcion']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check_circle_outline,
                          color: Colors.green.shade700),
                      tooltip: 'Aprobar',
                      onPressed: () => _aprobar(pub),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined,
                          color: AppColors.error),
                      tooltip: 'Rechazar',
                      onPressed: () => _rechazar(pub),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Moderar publicaciones')),
      body: cuerpo,
    );
  }
}