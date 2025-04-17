import 'package:flutter/material.dart';
import 'package:friends_run/core/utils/colors.dart'; // Supondo que use AppColors

class EmptyListMessage extends StatelessWidget {
  final String message;
  final IconData? icon; // Ícone opcional

  const EmptyListMessage({
    super.key,
    required this.message,
    this.icon, // Deixe o ícone opcional
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column( // Usar Column permite adicionar o ícone facilmente
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) // Mostra o ícone apenas se fornecido
              Icon(
                icon,
                size: 60, // Tamanho de exemplo
                color: AppColors.white.withAlpha(153), // ~60% opacidade
              ),
            if (icon != null) // Adiciona espaço apenas se houver ícone
              const SizedBox(height: 16), 
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white.withAlpha(204), // ~80% opacidade
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}