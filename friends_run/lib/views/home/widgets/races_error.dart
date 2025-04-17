import 'package:flutter/material.dart';
import 'package:friends_run/core/utils/colors.dart';

class RacesErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry; // Função para tentar novamente

  const RacesErrorWidget({
    required this.error,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
            const SizedBox(height: 16),
            Text(
              // Tenta extrair uma mensagem mais útil do erro
              'Erro ao carregar corridas:\n${error is Exception ? error.toString().replaceFirst("Exception: ", "") : error.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
