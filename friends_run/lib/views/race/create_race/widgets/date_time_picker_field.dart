import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:friends_run/core/providers/race_provider.dart'; // Para estado de loading
import 'package:friends_run/core/utils/colors.dart';

class DateTimePickerField extends ConsumerWidget {
  final DateTime? selectedDateTime;
  final VoidCallback? onTap; // Callback para abrir o seletor

  const DateTimePickerField({this.selectedDateTime, this.onTap, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isLoading =
        ref.watch(raceNotifierProvider).isLoading; // Observa loading global

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: AppColors.underBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 4.0,
      ),
      leading: const Icon(Icons.calendar_today, color: AppColors.primaryRed),
      title: Text(
        selectedDateTime == null
            ? 'Data e Hora da Corrida *'
            : DateFormat('dd/MM/yyyy \'às\' HH:mm').format(selectedDateTime!),
        style: TextStyle(
          color:
              selectedDateTime == null ? AppColors.greyLight : AppColors.white,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(Icons.edit, color: AppColors.greyLight, size: 18),
      onTap: isLoading ? null : onTap, // Desabilita se estiver carregando
    );
  }
}
