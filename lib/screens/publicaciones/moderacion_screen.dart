import 'dart:convert';
import 'dart:typed_data';
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
  final Set<int> _procesando = {};
  final Map<int, Uint8List> _fotos = {};
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
      _fotos.clear();
      for (final p in items) {
        final foto = p['foto'] as String?;
        if (foto == null || foto.isEmpty) continue;
        try {
          // Se decodifica una sola vez, no en cada redibujado.
          _fotos[(p['id'] as num).toInt()] = base64Decode(foto);
        } catch (_) {
          // La foto no es base64 (datos de prueba antiguos).
        }
      }
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
    final id = (pub['id'] as num).toInt();
    setState(() => _procesando.add(id));
    try {
      await _servicio.aprobar(publicacionId: id);
      _mensaje('Publicación aprobada');
      await _cargar();
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _procesando.remove(id));
    }
  }

  Future<void> _rechazar(Map<String, dynamic> pub) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _MotivoRechazoDialog(),
    );
    if (motivo == null) return;

    final id = (pub['id'] as num).toInt();
    setState(() => _procesando.add(id));
    try {
      await _servicio.rechazar(publicacionId: id, motivo: motivo);
      _mensaje('Publicación rechazada');
      await _cargar();
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _procesando.remove(id));
    }
  }

  // ---------- Aspecto ----------

  Widget _chip(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _foto(int id) {
    final placeholder = Container(
      height: 170,
      width: double.infinity,
      color: const Color(0x1AFF7A59),
      child: const Icon(Icons.pets, size: 56, color: AppColors.primary),
    );
    final bytes = _fotos[id];
    if (bytes == null) return placeholder;
    return Image.memory(
      bytes,
      height: 170,
      width: double.infinity,
      fit: BoxFit.cover,
      cacheWidth: 800,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  Widget _tarjeta(Map<String, dynamic> pub) {
    final id = (pub['id'] as num).toInt();
    final tipo = pub['tipo'] as String?;
    final ocupado = _procesando.contains(id);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _foto(id),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _chip(
                      tipo == 'PERDIDA' ? 'Perdida' : 'Encontrada',
                      tipo == 'PERDIDA'
                          ? Colors.deepOrange.shade700
                          : Colors.teal.shade700,
                    ),
                    _chip('Por revisar', Colors.orange.shade800),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${pub['especie']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pub['descripcion']}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: ocupado ? null : () => _rechazar(pub),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: ocupado ? null : () => _aprobar(pub),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                    child: ocupado
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Aprobar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      cuerpo = const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.task_alt, size: 72, color: AppColors.secondary),
              SizedBox(height: 16),
              Text(
                'No hay publicaciones pendientes por revisar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    } else {
      cuerpo = RefreshIndicator(
        onRefresh: _cargar,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _items.length == 1
                      ? '1 publicación por revisar'
                      : '${_items.length} publicaciones por revisar',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }
            return _tarjeta(_items[i - 1]);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Moderación')),
      body: cuerpo,
    );
  }
}

class _MotivoRechazoDialog extends StatefulWidget {
  const _MotivoRechazoDialog();

  @override
  State<_MotivoRechazoDialog> createState() => _MotivoRechazoDialogState();
}

class _MotivoRechazoDialogState extends State<_MotivoRechazoDialog> {
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
      title: const Text('Rechazar publicación'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Explica por qué no se aprueba. El motivo queda registrado.'),
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
          child: const Text('Rechazar', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}