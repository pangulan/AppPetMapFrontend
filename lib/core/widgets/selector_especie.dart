import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SelectorEspecie extends StatefulWidget {
  const SelectorEspecie({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<SelectorEspecie> createState() => _SelectorEspecieState();
}

class _SelectorEspecieState extends State<SelectorEspecie> {
  static const _opciones = <String, String>{
    'Perro': '🐶',
    'Gato': '🐱',
    'Ave': '🐦',
    'Conejo': '🐰',
    'Hámster': '🐹',
  };
  static const _otro = 'Otro';

  String? _seleccion;
  final _otroCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final actual = widget.controller.text.trim();
    if (actual.isNotEmpty) {
      if (_opciones.containsKey(actual)) {
        _seleccion = actual;
      } else {
        _seleccion = _otro;
        _otroCtrl.text = actual;
      }
    }
  }

  @override
  void dispose() {
    _otroCtrl.dispose();
    super.dispose();
  }

  void _elegir(String valor, FormFieldState<String> campo) {
    setState(() => _seleccion = valor);
    widget.controller.text = valor == _otro ? _otroCtrl.text.trim() : valor;
    campo.didChange(widget.controller.text);
    if (campo.hasError) campo.validate();
  }

  Widget _chip(String etiqueta, String valor, FormFieldState<String> campo) {
    final seleccionado = _seleccion == valor;
    return ChoiceChip(
      label: Text(etiqueta),
      selected: seleccionado,
      showCheckmark: false,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: seleccionado ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => _elegir(valor, campo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) =>
          widget.controller.text.trim().isEmpty ? 'Elige la especie' : null,
      builder: (campo) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Especie',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final e in _opciones.entries)
                _chip('${e.value} ${e.key}', e.key, campo),
              _chip('🐾 Otro', _otro, campo),
            ],
          ),
          if (_seleccion == _otro) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otroCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Escribe la especie'),
              onChanged: (v) {
                widget.controller.text = v.trim();
                campo.didChange(widget.controller.text);
                if (campo.hasError) campo.validate();
              },
            ),
          ],
          if (campo.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                campo.errorText!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}