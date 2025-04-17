import 'dart:io';

import 'package:flutter/material.dart';
import 'package:friends_run/core/utils/colors.dart';

/// Botão reutilizável para ações principais
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = AppColors.primaryRed,
    this.textColor = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 18, color: textColor),
        ),
      ),
    );
  }
}

/// Botão para login social (exemplo: Google)
class SocialLoginButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.iconPath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Image.asset(iconPath, height: 24),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18, color: AppColors.black),
        ),
      ),
    );
  }
}

/// Divisor com texto no meio
class DividerWithText extends StatelessWidget {
  final String text;

  const DividerWithText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.greyLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: const TextStyle(color: AppColors.greyLight),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.greyLight)),
      ],
    );
  }
}

/// Campo de entrada reutilizável para formulários de autenticação
class AuthTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? Function(String?)? validator;
  final bool isPassword;
  final Function(String)? onChanged;

  const AuthTextField({
    super.key,
    this.controller,
    required this.label,
    this.validator,
    this.isPassword = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.greyLight),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.greyLight),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryRed),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}


/// Componente para upload de imagem (Foto de perfil)
class ProfileImagePicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;

  const ProfileImagePicker({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: AppColors.greyLight,
        child: imagePath != null
            ? ClipOval(
          child: Image.file(
            File(imagePath!), // Mostra a imagem capturada/selecionada
            fit: BoxFit.cover,
            width: 100,
            height: 100,
          ),
        )
            : const Icon(Icons.camera_alt, color: AppColors.white, size: 40),
      ),
    );
  }
}
