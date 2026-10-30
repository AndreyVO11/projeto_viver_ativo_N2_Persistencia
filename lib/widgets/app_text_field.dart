import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto padronizado (fonte mínima 18pt, RNF001), reutilizado nos
/// formulários de cadastro/login/perfil/equipamento.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.inputFormatters,
    this.helperText,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final String? helperText;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _ocultar = true;

  @override
  Widget build(BuildContext context) {
    final isSenha = widget.obscureText;
    return TextFormField(
      controller: widget.controller,
      obscureText: isSenha ? _ocultar : false,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      maxLines: isSenha ? 1 : widget.maxLines,
      inputFormatters: widget.inputFormatters,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: 3,
        suffixIcon: isSenha
            ? IconButton(
                icon: Icon(_ocultar ? Icons.visibility_off : Icons.visibility),
                tooltip: _ocultar ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => _ocultar = !_ocultar),
              )
            : null,
      ),
    );
  }
}
