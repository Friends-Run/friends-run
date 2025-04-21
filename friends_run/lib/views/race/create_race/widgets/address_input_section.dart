import 'package:flutter/material.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'address_field.dart';

class AddressInputSection extends StatelessWidget {
  final TextEditingController startController;
  final TextEditingController endController;
  final bool isGeocodingStart;
  final bool isGeocodingEnd;
  final Function({required bool isStartPoint}) onGeocode;
  final bool enabled;

  const AddressInputSection({
    required this.startController,
    required this.endController,
    required this.isGeocodingStart,
    required this.isGeocodingEnd,
    required this.onGeocode,
    required this.enabled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Endereços (Início e Fim):",
          style: TextStyle(color: AppColors.white, fontSize: 16),
        ),
        const SizedBox(height: 12),
        AddressField(
          controller: startController,
          label: 'Endereço de Início *',
          hint: 'Ex: Pq. Ibirapuera ou R. Paulista, 100',
          icon: Icons.flag_outlined,
          isLoading: isGeocodingStart,
          onSearchPressed: () => onGeocode(isStartPoint: true),
          enabled: enabled,
        ),
        const SizedBox(height: 12),
        AddressField(
          controller: endController,
          label: 'Endereço de Chegada *',
          hint: 'Ex: Metrô Consolação ou Av. Brasil, 500',
          icon: Icons.location_on_outlined,
          isLoading: isGeocodingEnd,
          onSearchPressed: () => onGeocode(isStartPoint: false),
          enabled: enabled,
        ),
      ],
    );
  }
}