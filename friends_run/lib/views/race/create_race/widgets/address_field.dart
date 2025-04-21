import 'package:flutter/material.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/core/utils/validationsUtils.dart';

class AddressField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onSearchPressed;
  final bool enabled;

  const AddressField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isLoading,
    this.onSearchPressed,
    required this.enabled,
    super.key,
  });

  InputDecoration _buildInputDecoration(BuildContext context) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.greyLight),
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.greyLight.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: AppColors.primaryRed, size: 20),
      suffixIcon: isLoading
          ? const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryRed,
                ),
              ),
            )
          : (onSearchPressed != null
              ? IconButton(
                  tooltip: "Buscar localização no mapa",
                  icon: const Icon(Icons.location_searching, color: AppColors.greyLight),
                  onPressed: (enabled && controller.text.trim().isNotEmpty) 
                      ? onSearchPressed 
                      : null,
                )
              : null),
      filled: true,
      fillColor: AppColors.underBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(color: AppColors.white),
      decoration: _buildInputDecoration(context),
      validator: ValidationUtils.validateAddress,
      // Adiciona listener para atualizar o estado do botão
      onChanged: (value) {
        if (onSearchPressed != null) {
          (context as Element).markNeedsBuild();
        }
      },
    );
  }
}