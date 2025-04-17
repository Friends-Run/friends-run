import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/models/race/race_model.dart';
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/utils/colors.dart'; // Suas cores

class RaceActionButton extends ConsumerWidget {
  final Race race;
  final String raceId; // Passar o raceId explicitamente

  const RaceActionButton({required this.race, required this.raceId, super.key});

   // Função auxiliar para o diálogo de confirmação (pode ser movida para utils se usada em mais lugares)
   Future<bool?> _showLeaveConfirmationDialog(BuildContext context, String raceTitle) {
     return showDialog<bool>(
       context: context,
       builder: (context) => AlertDialog(
         backgroundColor: AppColors.underBackground, // Cor de fundo do diálogo
         title: const Text('Confirmar Saída', style: TextStyle(color: AppColors.white)),
         content: Text(
           'Tem certeza que deseja sair da corrida "$raceTitle"?',
            style: const TextStyle(color: AppColors.greyLight)
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context, false),
             child: const Text('Cancelar', style: TextStyle(color: AppColors.greyLight)),
           ),
           TextButton(
             onPressed: () => Navigator.pop(context, true),
             child: const Text(
               'Sair',
               style: TextStyle(color: Colors.redAccent),
             ),
           ),
         ],
       ),
     );
   }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final actionState = ref.watch(raceNotifierProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) {
          // Botão para fazer login
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.login, size: 20),
              label: const Text("Faça login para interagir"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greyDark,
                foregroundColor: AppColors.white.withOpacity(0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                // TODO: Implementar navegação para tela de login
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text("Navegar para Login (implementar)")),
                 );
              },
            ),
          );
        }

        // Lógica principal do botão (exatamente como no _buildActionButton original)
        final currentUserId = currentUser.uid;
        final isParticipant = race.participants.any((p) => p.uid == currentUserId);
        final isPending = race.pendingParticipants.any((p) => p.uid == currentUserId);
        final isOwner = race.ownerId == currentUserId;

        String buttonText = "";
        Color buttonColor = AppColors.greyDark;
        IconData buttonIcon = Icons.help_outline;
        VoidCallback? onPressedAction;
        bool canInteract = false; // Se o botão deve ser clicável (desconsiderando loading)
        bool showLoading = false; // Se deve mostrar indicador de loading

        if (isOwner) {
          buttonText = "Você é o Dono";
          buttonIcon = Icons.shield_outlined;
          buttonColor = AppColors.underBackground;
          canInteract = false; // Dono não tem ação primária aqui
        } else if (isParticipant) {
          buttonText = "Sair da Corrida";
          buttonColor = Colors.redAccent.shade700;
          buttonIcon = Icons.directions_run; // Ícone diferente para sair? Talvez exit_to_app?
          canInteract = true;
          showLoading = actionState.isLoading && actionState.actionType == RaceActionType.leave;
          onPressedAction = () async {
            bool? confirm = await _showLeaveConfirmationDialog(context, race.title);
            if (confirm == true) {
               final success = await ref
                   .read(raceNotifierProvider.notifier)
                   .leaveRace(raceId, currentUserId); // Usa raceId
               if (success && context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Você saiu da corrida."),
                      backgroundColor: Colors.blueGrey,
                    ),
                  );
                 ref.invalidate(raceDetailsProvider(raceId)); // Invalida o provider da view
                 ref.invalidate(nearbyRacesProvider); // Invalida lista de corridas
               }
            }
          };
        } else if (isPending) {
          buttonText = "Solicitação Pendente";
          buttonIcon = Icons.hourglass_top_outlined;
          canInteract = false; // Não pode interagir enquanto pendente
          // Talvez adicionar opção de cancelar solicitação? (ficaria mais complexo)
        } else { // Nem dono, nem participante, nem pendente
          buttonText = race.isPrivate ? "Solicitar Participação" : "Participar da Corrida";
          buttonColor = AppColors.primaryRed;
          buttonIcon = race.isPrivate ? Icons.vpn_key_outlined : Icons.add_circle_outline;
          canInteract = true;
           showLoading = actionState.isLoading && (
             actionState.actionType == RaceActionType.join ||
             actionState.actionType == RaceActionType.request
           );
          onPressedAction = () {
            if (race.isPrivate) {
               ref
                  .read(raceNotifierProvider.notifier)
                  .addParticipationRequest(raceId, currentUserId) // Usa raceId
                  .then((success) {
                 if (success && context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Solicitação enviada!'),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                   ref.invalidate(raceDetailsProvider(raceId)); // Atualiza a view
                 }
               });
            } else {
               ref
                  .read(raceNotifierProvider.notifier)
                  .addParticipant(raceId, currentUserId) // Usa raceId
                  .then((success) {
                 if (success && context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Você agora participa de "${race.title}"!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                   ref.invalidate(raceDetailsProvider(raceId)); // Atualiza a view
                   ref.invalidate(nearbyRacesProvider); // Atualiza lista
                 }
               });
            }
          };
        }

        final isLoading = showLoading; // Usa a flag específica

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(buttonIcon, size: 20),
            label: Text(
              buttonText,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              disabledBackgroundColor: buttonColor.withOpacity(0.5), // Estilo desabilitado
              disabledForegroundColor: Colors.white.withOpacity(0.7),
            ),
            onPressed: isLoading || !canInteract ? null : onPressedAction,
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14.0),
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        )
      ),
      error: (err, stack) => Center(
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Text("Erro: $err", style: const TextStyle(color: Colors.redAccent)),
         )
      ),
    );
  }
}