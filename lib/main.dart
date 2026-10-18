import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/session_storage.dart';

void main() {
  runApp(const PetMapApp());
}

class PetMapApp extends StatelessWidget {
  const PetMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetMap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _SesionGate(),
    );
  }
}

/// Decide la pantalla inicial: si hay token guardado entra directo,
/// si no, muestra el login.
class _SesionGate extends StatelessWidget {
  const _SesionGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: SessionStorage().leerToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data != null
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}