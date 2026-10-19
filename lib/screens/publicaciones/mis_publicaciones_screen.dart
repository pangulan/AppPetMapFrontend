import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/publicacion_service.dart';
import 'editar_publicacion_screen.dart';

class MisPublicacionesScreen extends StatefulWidget {
  const MisPublicacionesScreen({super.key});

  @override
  State<MisPublicacionesScreen> createState() => _MisPublicacionesScreenState();
}

class _MisPublicacionesScreenState extends State<MisPublicacionesScreen> {
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
      final items = await _servicio.misPublicaciones();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

    Future<void> _editar(Map<String, dynamic> pub) async {
      final cambio = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EditarPublicacionScreen(publicacion: pub),
        ),
      );
      if (cambio == true) await _cargar();
    }



  Future<void> _eliminar(Map<String, dynamic> pub) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _MotivoDialog(),
    );
    if (motivo == null) return;

    try {
      await _servicio.eliminar(
        publicacionId: (pub['id'] as num).toInt(),
        motivo: motivo,
      );
      _mensaje('Publicación eliminada');
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
            errorBuilder: (_, __, ___) => icono,
          ),
        );
      } catch (_) {
        // La foto no es base64 (datos de prueba antiguos).
      }
    }
    return icono;
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange.shade800;
      case 'APROBADA':
        return Colors.green.shade700;
      case 'RECHAZADA':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
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
      cuerpo = const Center(child: Text('Aún no has publicado nada'));
    } else {
      cuerpo = RefreshIndicator(
        onRefresh: _cargar,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (context, i) {
            final pub = _items[i];
            final estado = pub['estado'] as String?;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: _miniatura(pub['foto'] as String?),
                title: Text('${pub['especie']} · ${pub['tipo']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pub['descripcion']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      estado ?? '',
                      style: TextStyle(
                        color: _colorEstado(estado),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (estado == 'PENDIENTE' || estado == 'APROBADA')
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: AppColors.primary),
                                      tooltip: 'Editar',
                                      onPressed: () => _editar(pub),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: AppColors.error),
                                    tooltip: 'Eliminar',
                                    onPressed: () => _eliminar(pub),
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
      appBar: AppBar(title: const Text('Mis publicaciones')),
      body: cuerpo,
    );
  }
}

class _MotivoDialog extends StatefulWidget {
  const _MotivoDialog();

  @override
  State<_MotivoDialog> createState() => _MotivoDialogState();
}

class _MotivoDialogState extends State<_MotivoDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar publicación'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cuéntanos por qué la eliminas. El motivo queda registrado.'),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Motivo (obligatorio)',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final texto = _ctrl.text.trim();
            if (texto.isEmpty) {
              setState(() => _error = 'El motivo es obligatorio');
              return;
            }
            Navigator.pop(context, texto);
          },
          child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}