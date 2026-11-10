import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/session_storage.dart';
import '../auth/login_screen.dart';
import '../admin/activas_screen.dart';
import '../admin/resumen_admin.dart';
import '../publicaciones/crear_encontrada_screen.dart';
import '../publicaciones/crear_perdida_screen.dart';
import '../publicaciones/mis_publicaciones_screen.dart';
import '../publicaciones/moderacion_screen.dart';
import '../mapa/mapa_screen.dart';

String _iniciales(String? nombre) {
  final partes = (nombre ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes[0][0].toUpperCase();
  return (partes[0][0] + partes[1][0]).toUpperCase();
}

String _primerNombre(String? nombre) {
  final primero = (nombre ?? '').trim().split(RegExp(r'\s+')).first;
  if (primero.isEmpty) return '';
  return primero[0].toUpperCase() + primero.substring(1).toLowerCase();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _session = SessionStorage();
  Map<String, dynamic>? _usuario;
  int _tab = 0;
  int _refrescoResumen = 0;

  bool get _esAdmin => _usuario?['rol'] == 'ADMINISTRADOR';

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final usuario = await _session.leerUsuario();
    if (mounted) setState(() => _usuario = usuario);
  }

  Future<void> _confirmarCierre() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await _session.cerrar();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _abrir(Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  // Abre una pantalla del administrador y, al volver, actualiza los contadores.
  Future<void> _abrirYRefrescar(Widget pantalla) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => pantalla));
    if (mounted) setState(() => _refrescoResumen++);
  }

  void _elegirTipoReporte() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                '¿Qué pasó con la mascota?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search, color: AppColors.primary),
              title: const Text('La perdí'),
              subtitle: const Text(
                  'Publica sus datos para que te ayuden a encontrarla'),
              onTap: () {
                Navigator.pop(ctx);
                _abrir(const CrearPerdidaScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets, color: AppColors.secondary),
              title: const Text('La encontré'),
              subtitle: const Text('Ayuda a que su dueño la encuentre'),
              onTap: () {
                Navigator.pop(ctx);
                _abrir(const CrearEncontradaScreen());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _usuario?['nombre'] as String?;

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          _InicioTab(
            nombre: nombre,
            esAdmin: _esAdmin,
            refrescoResumen: _refrescoResumen,
            onReportar: _elegirTipoReporte,
            onMisPublicaciones: () => _abrir(const MisPublicacionesScreen()),
            onModerar: () => _abrirYRefrescar(const ModeracionScreen()),
            onActivas: () => _abrirYRefrescar(const ActivasScreen()),
          ),
          _tab == 1 ? const MapaScreen() : const SizedBox.shrink(),
          _PerfilTab(usuario: _usuario, onCerrarSesion: _confirmarCierre),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        indicatorColor: const Color(0x33FF7A59),
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: AppColors.primary),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ---------- Piezas reutilizables ----------

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.hijo});

  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 24,
        24,
        32,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: hijo,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.texto, this.radio = 28});

  final String texto;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radio,
      backgroundColor: Colors.white,
      child: Text(
        texto,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: radio * 0.7,
        ),
      ),
    );
  }
}

class _AccionCard extends StatelessWidget {
  const _AccionCard({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatoTile extends StatelessWidget {
  const _DatoTile({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icono, color: AppColors.primary),
        title: Text(
          etiqueta,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        subtitle: Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ---------- Pestañas ----------

class _InicioTab extends StatelessWidget {
  const _InicioTab({
    required this.nombre,
    required this.esAdmin,
    required this.refrescoResumen,
    required this.onReportar,
    required this.onMisPublicaciones,
    required this.onModerar,
    required this.onActivas,
  });

  final String? nombre;
  final bool esAdmin;
  final int refrescoResumen;
  final VoidCallback onReportar;
  final VoidCallback onMisPublicaciones;
  final VoidCallback onModerar;
  final VoidCallback onActivas;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Encabezado(
          hijo: Row(
            children: [
              _Avatar(texto: _iniciales(nombre)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${_primerNombre(nombre)} 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      esAdmin ? 'Modo administrador' : '¿A quién ayudamos hoy?',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                esAdmin ? 'Panel de administración' : '¿Qué quieres hacer?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (esAdmin) ...[
                ResumenAdmin(key: ValueKey(refrescoResumen)),
                const SizedBox(height: 20),
                _AccionCard(
                  icono: Icons.admin_panel_settings,
                  color: Colors.orange.shade800,
                  titulo: 'Moderar publicaciones',
                  descripcion: 'Aprueba o rechaza lo que reporta la comunidad.',
                  onTap: onModerar,
                ),
                const SizedBox(height: 12),
                _AccionCard(
                  icono: Icons.inventory_2_outlined,
                  color: AppColors.secondary,
                  titulo: 'Publicaciones activas',
                  descripcion: 'Revisa lo publicado y retira lo que no corresponda.',
                  onTap: onActivas,
                ),
              ] else ...[
                _AccionCard(
                  icono: Icons.pets,
                  color: AppColors.primary,
                  titulo: 'Reportar mascota',
                  descripcion: 'Cuéntanos si perdiste o encontraste una mascota.',
                  onTap: onReportar,
                ),
                const SizedBox(height: 12),
                _AccionCard(
                  icono: Icons.list_alt,
                  color: AppColors.secondary,
                  titulo: 'Mis publicaciones',
                  descripcion: 'Revisa su estado, edítalas o elimínalas.',
                  onTap: onMisPublicaciones,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PerfilTab extends StatelessWidget {
  const _PerfilTab({required this.usuario, required this.onCerrarSesion});

  final Map<String, dynamic>? usuario;
  final VoidCallback onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final nombre = usuario?['nombre'] as String?;
    final correo = usuario?['correo'] as String? ?? '';
    final telefono = usuario?['telefono'] as String?;
    final rol = usuario?['rol'] as String? ?? '';

    return Column(
      children: [
        _Encabezado(
          hijo: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(texto: _iniciales(nombre), radio: 40),
              const SizedBox(height: 12),
              Text(
                nombre ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(correo, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _DatoTile(icono: Icons.badge_outlined, etiqueta: 'Rol', valor: rol),
              if (telefono != null && telefono.isNotEmpty)
                _DatoTile(
                  icono: Icons.phone_outlined,
                  etiqueta: 'Teléfono',
                  valor: telefono,
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onCerrarSesion,
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}