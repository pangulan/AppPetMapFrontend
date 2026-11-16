import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/comunidad_service.dart';
import '../../services/session_storage.dart';

class ComentariosSeccion extends StatefulWidget {
  const ComentariosSeccion({super.key, required this.publicacionId});

  final int publicacionId;

  @override
  State<ComentariosSeccion> createState() => _ComentariosSeccionState();
}

class _ComentariosSeccionState extends State<ComentariosSeccion> {
  final _servicio = ComunidadService();
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _cargando = true;
  bool _enviando = false;
  bool _esAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _leerRol();
    _cargar();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _leerRol() async {
    final usuario = await SessionStorage().leerUsuario();
    if (mounted) {
      setState(() => _esAdmin = usuario?['rol'] == 'ADMINISTRADOR');
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final items = await _servicio.comentarios(widget.publicacionId);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _enviar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      await _servicio.comentar(
          publicacionId: widget.publicacionId, texto: texto);
      _ctrl.clear();
      await _cargar();
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _borrar(Map<String, dynamic> c) async {
    try {
      await _servicio.borrarComentario((c['id'] as num).toInt());
      await _cargar();
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _fecha(dynamic valor) {
    final t = '$valor';
    return t.length >= 16 ? t.substring(0, 16).replaceFirst('T', ' ') : t;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _cargando ? 'Comentarios' : 'Comentarios (${_items.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (_cargando)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Text(_error!, style: const TextStyle(color: AppColors.error))
        else if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Todavía no hay comentarios. ¡Sé el primero!',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          for (final c in _items)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              decoration: BoxDecoration(
                color: const Color(0x0F000000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c['autor']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text('${c['texto']}'),
                        const SizedBox(height: 2),
                        Text(
                          _fecha(c['fecha']),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (c['mio'] == true || _esAdmin)
                    IconButton(
                      tooltip: 'Borrar',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: AppColors.error),
                      onPressed: () => _borrar(c),
                    ),
                ],
              ),
            ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLength: 300,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Escribe un comentario…',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            _enviando
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    tooltip: 'Enviar',
                    onPressed: _enviar,
                    icon: const Icon(Icons.send, color: AppColors.primary),
                  ),
          ],
        ),
      ],
    );
  }
}