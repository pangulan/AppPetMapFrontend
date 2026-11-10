import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/publicacion_service.dart';

class ResumenAdmin extends StatefulWidget {
  const ResumenAdmin({super.key});

  @override
  State<ResumenAdmin> createState() => _ResumenAdminState();
}

class _ResumenAdminState extends State<ResumenAdmin> {
  final _servicio = PublicacionService();
  Map<String, int>? _datos;
  String? _error;
  bool _cargando = true;

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
      final datos = await _servicio.resumen();
      if (!mounted) return;
      setState(() => _datos = datos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_datos == null) {
      if (_cargando) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Column(
        children: [
          Text(_error ?? 'No se pudo cargar el resumen',
              textAlign: TextAlign.center),
          TextButton(onPressed: _cargar, child: const Text('Reintentar')),
        ],
      );
    }

    final d = _datos!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _Dato(
          icono: Icons.hourglass_top,
          color: Colors.orange.shade800,
          numero: d['pendientes'] ?? 0,
          etiqueta: 'Por revisar',
        ),
        _Dato(
          icono: Icons.check_circle,
          color: Colors.green.shade700,
          numero: d['aprobadas'] ?? 0,
          etiqueta: 'Publicadas',
        ),
        _Dato(
          icono: Icons.search,
          color: Colors.deepOrange.shade700,
          numero: d['perdidas'] ?? 0,
          etiqueta: 'Perdidas activas',
        ),
        _Dato(
          icono: Icons.pets,
          color: Colors.teal.shade700,
          numero: d['encontradas'] ?? 0,
          etiqueta: 'Encontradas activas',
        ),
        _Dato(
          icono: Icons.cancel,
          color: Colors.red.shade700,
          numero: d['rechazadas'] ?? 0,
          etiqueta: 'Rechazadas',
        ),
        _Dato(
          icono: Icons.task_alt,
          color: Colors.blueGrey.shade600,
          numero: d['resueltas'] ?? 0,
          etiqueta: 'Resueltas',
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.color,
    required this.numero,
    required this.etiqueta,
  });

  final IconData icono;
  final Color color;
  final int numero;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 22),
              const Spacer(),
              Text(
                '$numero',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            etiqueta,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}