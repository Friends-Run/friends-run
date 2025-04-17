import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/core/utils/validationsUtils.dart';
import 'package:intl/intl.dart';

class RaceTitleField extends ConsumerWidget {
  final TextEditingController controller;
  
  const RaceTitleField({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextFormField(
      controller: controller,
      enabled: !ref.read(raceNotifierProvider).isLoading,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: 'Título da Corrida *',
        labelStyle: TextStyle(color: AppColors.greyLight),
        filled: true,
        fillColor: AppColors.underBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: Icon(Icons.flag, color: AppColors.primaryRed),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Título é obrigatório' : null,
    );
  }
}

class DateTimePickerField extends ConsumerWidget {
  final DateTime? selectedDateTime;
  final VoidCallback onTap;
  
  const DateTimePickerField({
    super.key,
    required this.selectedDateTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: AppColors.underBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      leading: const Icon(Icons.calendar_today, color: AppColors.primaryRed),
      title: Text(
        selectedDateTime == null
            ? 'Data e Hora da Corrida *'
            : DateFormat('dd/MM/yyyy \'às\' HH:mm').format(selectedDateTime!),
        style: TextStyle(
          color: selectedDateTime == null ? AppColors.greyLight : AppColors.white,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(Icons.edit, color: AppColors.greyLight, size: 18),
      onTap: ref.read(raceNotifierProvider).isLoading ? null : onTap,
    );
  }
}

class AddressField extends ConsumerWidget {
  final TextEditingController controller;
  final bool isStartPoint;
  final bool isLoading;
  final VoidCallback onSearchPressed;
  
  const AddressField({
    super.key,
    required this.controller,
    required this.isStartPoint,
    required this.isLoading,
    required this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextFormField(
      controller: controller,
      enabled: !ref.read(raceNotifierProvider).isLoading,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: isStartPoint ? 'Endereço de Início *' : 'Endereço de Chegada *',
        labelStyle: const TextStyle(color: AppColors.greyLight),
        filled: true,
        fillColor: AppColors.underBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: Icon(
          isStartPoint ? Icons.flag : Icons.location_on,
          color: AppColors.primaryRed,
        ),
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
            : IconButton(
                icon: const Icon(Icons.location_searching, color: AppColors.greyLight),
                onPressed: onSearchPressed,
              ),
      ),
      validator: ValidationUtils.validateAddress,
    );
  }
}

class DistanceIndicator extends StatelessWidget {
  final double distanceKm;
  
  const DistanceIndicator({super.key, required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.straighten, color: AppColors.primaryRed, size: 20),
          const SizedBox(width: 8),
          Text(
            "Distância: ${distanceKm.toStringAsFixed(1)} km",
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyToggle extends ConsumerWidget {
  final bool isPrivate;
  final ValueChanged<bool> onChanged;
  
  const PrivacyToggle({
    super.key,
    required this.isPrivate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      title: const Text("Corrida Privada?", style: TextStyle(color: AppColors.white)),
      subtitle: Text(
        isPrivate ? "Apenas convidados podem ver." : "Visível para todos.",
        style: const TextStyle(color: AppColors.greyLight),
      ),
      value: isPrivate,
      onChanged: ref.read(raceNotifierProvider).isLoading ? null : onChanged,
      activeColor: AppColors.primaryRed,
      tileColor: AppColors.underBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
    );
  }
}

class CreateRaceButton extends ConsumerWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  
  const CreateRaceButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.check, color: AppColors.white),
      label: const Text('Criar Corrida', style: TextStyle(fontSize: 16, color: AppColors.white)),
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryRed,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}