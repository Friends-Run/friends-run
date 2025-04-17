import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/providers/location_provider.dart'  hide nearbyRacesProvider;
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/models/race/race_model.dart';
import 'package:friends_run/models/user/app_user.dart';
import 'package:geolocator/geolocator.dart';
// --- IMPORT DA TELA DE DETALHES (da versão "nova") ---
import 'package:friends_run/views/race/race_details/race_details_view.dart';
// ----------------------------------------------------

class RaceCard extends ConsumerWidget {
  final Race race;
  const RaceCard({required this.race, super.key});

  // --- Método auxiliar para linhas de informação ---
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.white.withAlpha(230), // ~90% opacity
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- Diálogo de confirmação/solicitação (da versão "antiga" - completa) ---
  void _showJoinConfirmationDialog(BuildContext context, WidgetRef ref, String userId) {
    if (race.isPrivate) {
      // --- Lógica para Solicitar Participação (Corrida Privada) ---
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Solicitar Participação', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
          content: Text('Esta é uma corrida privada. Deseja solicitar participação em "${race.title}"?', style: const TextStyle(color: AppColors.black)),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.greyDark)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref.read(raceNotifierProvider.notifier).addParticipationRequest(race.id, userId);
                if (context.mounted && success) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Solicitação enviada! Aguardando aprovação.'), backgroundColor: Colors.orangeAccent),
                   );
                 }
                 // Erro tratado pelo listener global
              },
              child: const Text('Solicitar'),
            ),
          ],
        ),
      );
    } else {
      // --- Lógica para Entrar Diretamente (Corrida Pública) ---
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Confirmar participação', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
          content: Text('Deseja participar da corrida pública "${race.title}"?', style: const TextStyle(color: AppColors.black)),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.greyDark)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                 backgroundColor: AppColors.primaryRed,
                 foregroundColor: AppColors.white,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref.read(raceNotifierProvider.notifier).addParticipant(race.id, userId);
                 if (context.mounted && success) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Você agora está participando de "${race.title}"!'), backgroundColor: Colors.green),
                   );
                   ref.invalidate(nearbyRacesProvider); // Atualiza a lista
                 }
                 // Erro tratado pelo listener global
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Observa os providers necessários ---
    final currentUserAsync = ref.watch(currentUserProvider);
    // uid é nullable, então usamos ?.
    final actionState = ref.watch(raceNotifierProvider);
    final currentLocationAsync = ref.watch(currentLocationProvider);

    // --- Lógica de estado do botão ---
    // Usamos currentUserId (nullable) diretamente nas verificações

    bool canInteract = false; // Assume que não pode interagir inicialmente
    String buttonText = "Carregando...";
    VoidCallback? onPressedAction;

    // Determina o estado do botão APENAS quando o usuário está carregado (AsyncData)
    if (currentUserAsync is AsyncData<AppUser?>) {
        final user = currentUserAsync.value;

        if (user == null) {
            // Usuário não logado
            buttonText = "Faça login para interagir";
            canInteract = false;
            onPressedAction = null; // Poderia navegar para login aqui, se desejado
        } else {
            // Usuário logado, verifica participação/pendência
            final currentUserIdChecked = user.uid; // Temos certeza que não é nulo aqui
            final bool isParticipantChecked = race.participants.any((p) => p.uid == currentUserIdChecked);
            final bool isPendingChecked = race.pendingParticipants.any((p) => p.uid == currentUserIdChecked);
            canInteract = !isParticipantChecked && !isPendingChecked; // Pode interagir se não for participante nem pendente

            if (isParticipantChecked) {
                buttonText = "Já Participando";
                onPressedAction = null;
            } else if (isPendingChecked) {
                buttonText = "Solicitação Pendente";
                onPressedAction = null;
            } else {
                // Não participa e não está pendente -> pode interagir
                buttonText = race.isPrivate ? "Solicitar Participação" : "Participar da Corrida";
                // Define a ação SÓ SE PUDER INTERAGIR
                onPressedAction = () => _showJoinConfirmationDialog(context, ref, currentUserIdChecked);
            }
        }
    } else if (currentUserAsync is AsyncError) {
         // Erro ao carregar usuário
         buttonText = "Erro (Usuário)";
         canInteract = false;
         onPressedAction = null;
    }
    // Se ainda estiver em AsyncLoading, buttonText continua "Carregando..." e canInteract é false

    // --- Cálculo da distância (opcional) ---
    double? distanceToRaceStartKm;
    if (currentLocationAsync is AsyncData<Position?> && currentLocationAsync.value != null) {
       final userPos = currentLocationAsync.value!;
       distanceToRaceStartKm = Geolocator.distanceBetween(
          userPos.latitude,
          userPos.longitude,
          race.startLatitude,
          race.startLongitude,
       ) / 1000.0;
    }

    // --- Construção do Card ---
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.white.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell( // InkWell para tornar o card clicável
        borderRadius: BorderRadius.circular(12),
        // --- AÇÃO onTap ATUALIZADA (da versão "nova") ---
        onTap: () {
          print("Navegando para detalhes da corrida: ${race.id}");
          Navigator.push(
            context,
            MaterialPageRoute(
              // Constrói a RaceDetailsView passando o ID da corrida atual
              builder: (_) => RaceDetailsView(raceId: race.id),
            ),
          );
        },
        // ---------------------------------------------
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Imagem da Corrida (com Hero) ---
            if (race.imageUrl != null && race.imageUrl!.isNotEmpty)
              Hero(
                tag: 'race_image_${race.id}', // Tag para animação Hero
                child: CachedNetworkImage(
                   imageUrl: race.imageUrl!,
                   height: 180,
                   width: double.infinity,
                   fit: BoxFit.cover,
                   placeholder: (context, url) => Container(
                        height: 180,
                        color: AppColors.underBackground,
                        child: const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
                   ),
                   errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: AppColors.underBackground,
                      child: const Center(child: Icon(Icons.running_with_errors_rounded, color: AppColors.greyLight, size: 50)),
                   ),
                 ),
              ),
             // --- Conteúdo de Texto e Botão ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Título e Distância da Corrida ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          race.title,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          race.formattedDistance,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- Linhas de Informação ---
                  _buildInfoRow(Icons.calendar_today_outlined, race.formattedDate),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    (race.startAddress.isNotEmpty && race.endAddress.isNotEmpty)
                      ? '${race.startAddress} → ${race.endAddress}'
                      : 'De [${race.startLatitude.toStringAsFixed(2)}, ${race.startLongitude.toStringAsFixed(2)}] para [${race.endLatitude.toStringAsFixed(2)}, ${race.endLongitude.toStringAsFixed(2)}]'
                  ),
                  if (distanceToRaceStartKm != null)
                     _buildInfoRow(Icons.social_distance_outlined, '${distanceToRaceStartKm.toStringAsFixed(1)} km de distância'),
                  _buildInfoRow(Icons.people_outline, '${race.participants.length} participante(s)'),
                   _buildInfoRow(
                      race.isPrivate ? Icons.lock_outline : Icons.lock_open_outlined,
                      race.isPrivate ? 'Corrida Privada' : 'Corrida Pública',
                    ),
                  const SizedBox(height: 16),

                  // --- Botão de Ação ---
                  SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                       style: ButtonStyle(
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.disabled)) {
                                return AppColors.greyLight.withAlpha(150);
                              }
                              return AppColors.primaryRed;
                            },
                          ),
                          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.disabled)) {
                                return AppColors.background.withAlpha(180);
                              }
                              return AppColors.white;
                            },
                          ),
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return AppColors.white.withOpacity(0.1);
                              }
                              return null;
                            },
                          ),
                          elevation: WidgetStateProperty.resolveWith<double?>(
                             (Set<WidgetState> states) {
                                if (states.contains(WidgetState.disabled)) return 0;
                                return 2;
                             },
                           ),
                       ),
                       // Desabilita se ação estiver em loading OU não puder interagir (definido acima) OU usuário não carregou
                       onPressed: actionState.isLoading || !canInteract || currentUserAsync is! AsyncData
                           ? null
                           : onPressedAction, // onPressedAction já é null se !canInteract
                       child: actionState.isLoading && canInteract && currentUserAsync is AsyncData
                           ? const SizedBox(
                               width: 20,
                               height: 20,
                               child: CircularProgressIndicator(
                                 strokeWidth: 2.5,
                                 color: AppColors.white,
                               ),
                             )
                           : Text(
                               buttonText,
                               style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                             ),
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}