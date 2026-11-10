import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/publicacion_service.dart';

class ActivasScreen extends StatefulWidget {
  const ActivasScreen({super.key});

  @override
  State<ActivasScreen> createState() => _ActivasScreenState();
}

class _ActivasScreenState extends State<ActivasScreen> {
  final _servicio = PublicacionService();
  final Set<int> _procesando = {};
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

  Future<void> _retirar(Map<String, dynamic> pub) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _MotivoRetiroDialog(),
    );
    if (motivo == null) return;

    final id = (pub['id'] as num).toInt();
    setState(() => _procesando.add(id));
    try {
      await _servicio.retirar(publicacionId: id, motivo: motivo);
      _mensaje('Publicación retirada');
      await _cargar();
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _procesando.remove(id));
    }
  }

  Widget _tarjeta(Map<String, dynamic> pub) {
    final id = (pub['id'] as num).toInt();
    final tipo = pub['tipo'] as String?;
    final color =
        tipo == 'PERDIDA' ? Colors.deepOrange.shade700 : Colors.teal.shade700;
    final ocupado = _procesando.contains(id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tipo == 'PERDIDA' ? 'Perdida' : 'Encontrada',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
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
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${pub['fecha']}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: ocupado ? null : () => _retirar(pub),
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Retirar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
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
          child: Text(
            'No hay publicaciones activas',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
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
      appBar: AppBar(title: const Text('Publicaciones activas')),
      body: cuerpo,
    );
  }
}

class _MotivoRetiroDialog extends StatefulWidget {
  const _MotivoRetiroDialog();

  @override
  State<_MotivoRetiroDialog> createState() => _MotivoRetiroDialogState();
}

class _MotivoRetiroDialogState extends State<_MotivoRetiroDialog> {
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
      title: const Text('Retirar publicación'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Explica por qué se retira. El motivo queda registrado.'),
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
          child: const Text('Retirar', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}