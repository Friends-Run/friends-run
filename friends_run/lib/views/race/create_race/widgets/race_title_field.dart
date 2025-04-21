import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/utils/colors.dart';

class RaceTitleField extends ConsumerWidget {
  final TextEditingController controller;
  final bool enabled;

  const RaceTitleField({
    required this.controller,
    required this.enabled,
    super.key
  });

  // Helper interno para InputDecoration
  InputDecoration _buildInputDecoration() {
     return InputDecoration(
        labelText: 'Título da Corrida *',
        labelStyle: const TextStyle(color: AppColors.greyLight),
        prefixIcon: const Icon(Icons.flag_outlined, color: AppColors.primaryRed, size: 20),
        filled: true, fillColor: AppColors.underBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide( color: AppColors.primaryRed, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide( color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
   }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextFormField(
      controller: controller,
      enabled: enabled, // Usa o parâmetro passado
      style: const TextStyle(color: AppColors.white),
      decoration: _buildInputDecoration(),
      validator: (value) => (value == null || value.trim().isEmpty) ? 'Título é obrigatório' : null,
    );
  }
}