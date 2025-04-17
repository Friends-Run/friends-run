import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Remova imports não mais usados diretamente aqui (como CachedNetworkImage, Geolocator, GoogleMaps...)

import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/utils/colors.dart';

// Importe os novos widgets
import 'widgets/race_image_header.dart';
import 'widgets/race_info_section.dart';
import 'widgets/race_map_view.dart';
import 'widgets/race_participants_list.dart';
import 'widgets/race_action_button.dart';

class RaceDetailsView extends ConsumerWidget {
  final String raceId;

  const RaceDetailsView({required this.raceId, super.key});

  // Remova os métodos _buildInfoRow, _buildMapView, _buildActionButton, _buildParticipantItem

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceAsync = ref.watch(raceDetailsProvider(raceId));

    // Listener para erros do Notifier continua aqui
    ref.listen<RaceActionState>(raceNotifierProvider, (_, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
        // Limpa o erro após mostrar
        ref.read(raceNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          raceAsync.maybeWhen(
            data: (race) => race?.title ?? 'Detalhes da Corrida',
            orElse: () => 'Carregando...',
          ),
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: raceAsync.when(
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
          error:
              (error, stack) => Center(
                // Estado de erro principal
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Erro ao carregar corrida:\n$error",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Tentar Novamente"),
                        onPressed:
                            () => ref.invalidate(raceDetailsProvider(raceId)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          data: (race) {
            if (race == null) {
              // Caso a corrida não exista mais
              return const Center(
                child: Text(
                  "Corrida não encontrada.",
                  style: TextStyle(color: AppColors.greyLight, fontSize: 16),
                ),
              );
            }

            // Remova a lógica do ownerNameWidget e distanceToRaceStartKm daqui

            // Corpo principal usando os novos componentes
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16.0,
                8.0,
                16.0,
                80.0,
              ), // Padding inferior para o botão flutuante ou fixo
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Imagem (se existir)
                  RaceImageHeader(imageUrl: race.imageUrl, raceId: race.id),

                  // 2. Título
                  Text(
                    race.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Seção de Informações
                  RaceInfoSection(race: race),
                  const SizedBox(height: 24),

                  // 4. Mapa
                  const Text(
                    // Título do Mapa
                    "Mapa da Rota:",
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RaceMapView(race: race),
                  const SizedBox(height: 24),

                  // 5. Lista de Participantes
                  RaceParticipantsList(
                    raceId: race.id, // Passa o ID da corrida
                    isPrivate: race.isPrivate, // Passa se é privada
                    participants: race.participants,
                    pendingParticipants:
                        race.pendingParticipants, // Passa a lista de pendentes
                    ownerId: race.ownerId,
                  ),
                  const SizedBox(height: 30), // Espaço antes do botão
                  // 6. Botão de Ação
                  RaceActionButton(
                    race: race,
                    raceId: raceId,
                  ), // Passa race e raceId
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
