import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/register_screen.dart';

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
      home: const RegisterScreen(),
    );
  }
}