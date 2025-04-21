import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Para ler estado global de loading
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/utils/colors.dart';

class PrivacyToggle extends ConsumerWidget {
  final bool isPrivate;
  final ValueChanged<bool>? onChanged; // Nullable para desabilitar

  const PrivacyToggle({required this.isPrivate, this.onChanged, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     final actionState = ref.watch(raceNotifierProvider);

     return SwitchListTile(
        title: const Text("Corrida Privada?", style: TextStyle(color: AppColors.white)),
        subtitle: Text(isPrivate ? "Apenas convidados poderão ver." : "Visível para todos no app.", style: const TextStyle(color: AppColors.greyLight)),
        value: isPrivate,
        onChanged: actionState.isLoading ? null : onChanged, // Usa loading global
        activeColor: AppColors.primaryRed,
        tileColor: AppColors.underBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
     );
  }
}