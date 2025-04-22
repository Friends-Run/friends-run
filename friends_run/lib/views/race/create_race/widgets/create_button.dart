import 'package:flutter/material.dart';
import 'package:friends_run/core/utils/colors.dart';

class CreateRaceButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const CreateRaceButton({required this.isLoading, this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
     return ElevatedButton.icon(
        icon: const Icon(Icons.check, color: AppColors.white),
        label: const Text('Criar Corrida', style: TextStyle(fontSize: 16, color: AppColors.white)),
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            disabledBackgroundColor: AppColors.primaryRed.withOpacity(0.5),
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        ),
     );
  }
}