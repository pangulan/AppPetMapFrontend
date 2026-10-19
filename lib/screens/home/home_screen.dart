import 'package:flutter/material.dart';
import '../../services/session_storage.dart';
import '../auth/login_screen.dart';
import '../publicaciones/crear_encontrada_screen.dart';
import '../publicaciones/crear_perdida_screen.dart';
import '../publicaciones/mis_publicaciones_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _session = SessionStorage();
  Map<String, dynamic>? _usuario;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final usuario = await _session.leerUsuario();
    if (mounted) setState(() => _usuario = usuario);
  }

  Future<void> _cerrarSesion() async {
    await _session.cerrar();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PetMap')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hola, ${_usuario?['nombre'] ?? ''}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('Rol: ${_usuario?['rol'] ?? ''}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CrearEncontradaScreen(),
                  ),
                ),
                child: const Text('Reportar mascota encontrada'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CrearPerdidaScreen(),
                  ),
                ),
                child: const Text('Reportar mascota perdida'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MisPublicacionesScreen(),
                  ),
                ),
                child: const Text('Mis publicaciones'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _cerrarSesion,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}