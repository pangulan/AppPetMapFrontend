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

  Future<void> _marcarResuelta(Map<String, dynamic> pub) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como resuelta'),
        content: const Text(
            '¿Ya encontraste a tu mascota? La publicación quedará como resuelta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, resuelta'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _servicio.marcarResuelta(
        publicacionId: (pub['id'] as num).toInt(),
      );
      _mensaje('Publicación marcada como resuelta');
      await _cargar();
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    }
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

  // ---------- Aspecto ----------

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange.shade800;
      case 'APROBADA':
        return Colors.green.shade700;
      case 'RECHAZADA':
        return Colors.red.shade700;
      case 'RESUELTA':
        return Colors.blue.shade700;
      default:
        return Colors.blueGrey.shade600;
    }
  }

  String _textoEstado(String? estado) {
    switch (estado) {
      case 'PENDIENTE':
        return 'Pendiente de revisión';
      case 'APROBADA':
        return 'Aprobada';
      case 'RECHAZADA':
        return 'Rechazada';
      case 'RESUELTA':
        return 'Resuelta';
      case 'CERRADA':
        return 'Cerrada';
      default:
        return estado ?? '';
    }
  }

  String _textoTipo(String? tipo) => tipo == 'PERDIDA' ? 'Perdida' : 'Encontrada';

  Color _colorTipo(String? tipo) =>
      tipo == 'PERDIDA' ? Colors.deepOrange.shade700 : Colors.teal.shade700;

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

  Widget _foto(String? foto) {
    final placeholder = Container(
      height: 170,
      width: double.infinity,
      color: const Color(0x1AFF7A59),
      child: const Icon(Icons.pets, size: 56, color: AppColors.primary),
    );
    if (foto != null && foto.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(foto),
          height: 170,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
        );
      } catch (_) {
        // La foto no es base64 (datos de prueba antiguos).
      }
    }
    return placeholder;
  }

  Widget _tarjeta(Map<String, dynamic> pub) {
    final estado = pub['estado'] as String?;
    final tipo = pub['tipo'] as String?;
    final activa = estado == 'PENDIENTE' || estado == 'APROBADA';
    final puedeResolver = tipo == 'PERDIDA' && activa;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _foto(pub['foto'] as String?),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _chip(_textoTipo(tipo), _colorTipo(tipo)),
                    _chip(_textoEstado(estado), _colorEstado(estado)),
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
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Wrap(
              alignment: WrapAlignment.end,
              children: [
                if (puedeResolver)
                  TextButton.icon(
                    onPressed: () => _marcarResuelta(pub),
                    icon: Icon(Icons.check_circle_outline,
                        color: Colors.green.shade700),
                    label: Text('Ya apareció',
                        style: TextStyle(color: Colors.green.shade700)),
                  ),
                if (activa)
                  TextButton.icon(
                    onPressed: () => _editar(pub),
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.primary),
                    label: const Text('Editar',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                TextButton.icon(
                  onPressed: () => _eliminar(pub),
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                  label: const Text('Eliminar',
                      style: TextStyle(color: AppColors.error)),
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
              Icon(Icons.inbox_outlined, size: 72, color: AppColors.secondary),
              SizedBox(height: 16),
              Text(
                'Aún no has publicado nada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Cuando reportes una mascota, la verás aquí con su estado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
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
          itemCount: _items.length,
          itemBuilder: (context, i) => _tarjeta(_items[i]),
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