import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:friends_run/models/race/race_model.dart';
import 'package:friends_run/core/providers/auth_provider.dart'; // Assumindo que userProvider está aqui
import 'package:friends_run/core/providers/location_provider.dart';
import 'package:friends_run/core/utils/colors.dart'; // Importe suas cores

class RaceInfoSection extends ConsumerWidget {
  final Race race;

  const RaceInfoSection({required this.race, super.key});

  // Move _buildInfoRow para dentro ou o torna uma função estática/global se preferir
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    Widget valueWidget,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.greyLight,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                valueWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lógica do nome do organizador movida para cá
    final ownerAsync = ref.watch(userProvider(race.ownerId));
    final ownerNameWidget = ownerAsync.when(
      data: (ownerUser) => Text(
        ownerUser?.name ?? 'Organizador não encontrado',
        style: const TextStyle(color: AppColors.white, fontSize: 15),
        overflow: TextOverflow.ellipsis,
      ),
      loading: () => const Text(
        'Carregando...',
        style: TextStyle(
          color: AppColors.greyLight,
          fontSize: 15,
          fontStyle: FontStyle.italic,
        ),
      ),
      error: (e, s) => const Text(
        'Erro',
        style: TextStyle(color: Colors.redAccent, fontSize: 15),
      ),
    );

    // Lógica da distância movida para cá
    double? distanceToRaceStartKm;
    final currentLocationAsync = ref.watch(currentLocationProvider);
    if (currentLocationAsync is AsyncData<Position?> &&
        currentLocationAsync.value != null) {
      distanceToRaceStartKm = Geolocator.distanceBetween(
            currentLocationAsync.value!.latitude,
            currentLocationAsync.value!.longitude,
            race.startLatitude,
            race.startLongitude,
          ) /
          1000.0;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            Icons.calendar_today_outlined,
            "Data e Hora",
            Text(
              race.formattedDate,
              style: const TextStyle(color: AppColors.white, fontSize: 15),
            ),
          ),
          const Divider(color: AppColors.greyDark, height: 16, thickness: 0.5),
          _buildInfoRow(
            context,
            Icons.straighten_outlined,
            "Distância Total",
            Text(
              race.formattedDistance,
              style: const TextStyle(color: AppColors.white, fontSize: 15),
            ),
          ),
          const Divider(color: AppColors.greyDark, height: 16, thickness: 0.5),
           _buildInfoRow(
            context,
            Icons.flag_outlined,
            "Início",
            Text(
              race.startAddress.isNotEmpty
                  ? race.startAddress
                  : "Endereço não disponível",
              style: const TextStyle(color: AppColors.white, fontSize: 15),
            ),
          ),
          const Divider(color: AppColors.greyDark, height: 16, thickness: 0.5),
          _buildInfoRow(
            context,
            Icons.location_on_outlined,
            "Fim",
             Text(
               race.endAddress.isNotEmpty
                   ? race.endAddress
                   : "Endereço não disponível",
               style: const TextStyle(color: AppColors.white, fontSize: 15),
             ),
          ),
          const Divider(color: AppColors.greyDark, height: 16, thickness: 0.5),
          _buildInfoRow(
            context,
            Icons.person_outline,
            "Organizador",
            ownerNameWidget, // Usa o widget criado acima
          ),
          const Divider(color: AppColors.greyDark, height: 16, thickness: 0.5),
          if (distanceToRaceStartKm != null) ...[
            _buildInfoRow(
              context,
              Icons.social_distance_outlined,
              "Distância de Você",
              Text(
                "${distanceToRaceStartKm.toStringAsFixed(1)} km",
                style: const TextStyle(color: AppColors.white, fontSize: 15),
              ),
            ),
            const Divider(color: AppColors.greyDark, height: 16, thickness: 0.5),
          ],
          _buildInfoRow(
            context,
            race.isPrivate ? Icons.lock_outline : Icons.lock_open_outlined,
            "Visibilidade",
            Text(
              race.isPrivate ? 'Privada' : 'Pública',
              style: const TextStyle(color: AppColors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}