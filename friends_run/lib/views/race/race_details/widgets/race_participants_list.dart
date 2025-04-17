import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/models/user/app_user.dart';

class RaceParticipantsList extends ConsumerWidget {
  final String raceId;
  final bool isPrivate;
  final List<AppUser> participants;
  final List<AppUser> pendingParticipants;
  final String ownerId;

  const RaceParticipantsList({
    required this.raceId,
    required this.isPrivate,
    required this.participants,
    required this.pendingParticipants,
    required this.ownerId,
    super.key,
  });

  Widget _buildParticipantItem(
    BuildContext context,
    WidgetRef ref,
    String userId,
    bool isOwnerParam,
  ) {
    final userAsync = ref.watch(userProvider(userId));

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return ListTile(
            dense: true,
            leading: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.greyDark,
              child: Icon(Icons.question_mark, size: 18),
            ),
            title: const Text(
              'Usuário não encontrado',
              style: TextStyle(
                color: AppColors.greyLight,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.greyDark,
                backgroundImage:
                    user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(user.profileImageUrl!)
                        : null,
                child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 18,
                        color: AppColors.greyLight,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.name.isNotEmpty ? user.name : 'Usuário Anônimo',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user.uid == ownerId)
                Tooltip(
                  message: "Organizador",
                  child: Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: AppColors.primaryRed.withOpacity(0.8),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.greyDark,
            ),
            const SizedBox(width: 12),
            Container(
              height: 10,
              width: 100,
              color: AppColors.greyDark.withOpacity(0.5),
            ),
          ],
        ),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.redAccent,
              child: Icon(
                Icons.error_outline,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Erro ao carregar',
              style: TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingItem(
    BuildContext context,
    WidgetRef ref,
    String pendingUserId,
    String currentUserId,
  ) {
    final actionState = ref.watch(raceNotifierProvider);
    final userAsync = ref.watch(userProvider(pendingUserId));

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return ListTile(
            dense: true,
            leading: const CircleAvatar(
                radius: 18, backgroundColor: AppColors.greyDark),
            title: const Text('Usuário Pendente Não Encontrado',
                style: TextStyle(color: AppColors.greyLight, fontSize: 14)),
          );
        }

        final bool isApproving = actionState.isLoading &&
            actionState.actionType == RaceActionType.approve;
        final bool isRejecting = actionState.isLoading &&
            actionState.actionType == RaceActionType.reject;
        final bool disableButtons = actionState.isLoading;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.greyDark,
                backgroundImage: user.profileImageUrl != null &&
                        user.profileImageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null ||
                        user.profileImageUrl!.isEmpty
                    ? const Icon(Icons.person, size: 18, color: AppColors.greyLight)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.name.isNotEmpty ? user.name : 'Usuário Anônimo',
                  style: const TextStyle(color: AppColors.white, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (currentUserId == ownerId) ...[
                SizedBox(
                  width: 36,
                  height: 36,
                  child: isApproving
                      ? const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.green,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                          iconSize: 20,
                          tooltip: "Aprovar",
                          padding: EdgeInsets.zero,
                          onPressed: disableButtons ? null : () async {
                            final success = await ref
                                .read(raceNotifierProvider.notifier)
                                .approveParticipant(raceId, pendingUserId);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${user.name} aprovado(a)!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              ref.invalidate(raceDetailsProvider(raceId));
                            }
                          },
                        ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: isRejecting
                      ? const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.redAccent,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                          iconSize: 20,
                          tooltip: "Rejeitar",
                          padding: EdgeInsets.zero,
                          onPressed: disableButtons ? null : () async {
                            final success = await ref
                                .read(raceNotifierProvider.notifier)
                                .rejectParticipationRequest(raceId, pendingUserId);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Solicitação de ${user.name} rejeitada.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              ref.invalidate(raceDetailsProvider(raceId));
                            }
                          },
                        ),
                ),
              ]
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.greyDark,
            ),
            const SizedBox(width: 12),
            Container(
              height: 10,
              width: 100,
              color: AppColors.greyDark.withOpacity(0.5),
            ),
          ],
        ),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.redAccent,
              child: Icon(
                Icons.error_outline,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Erro ao carregar',
              style: TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserProvider).maybeWhen(
          data: (user) => user?.uid,
          orElse: () => null,
        );

    final bool isCurrentUserOwner = currentUserId != null && currentUserId == ownerId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Participantes (${participants.length}):",
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.underBackground.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: participants.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Nenhum participante confirmado ainda.",
                    style: TextStyle(color: AppColors.greyLight),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: participants
                      .map((p) => _buildParticipantItem(context, ref, p.uid, p.uid == ownerId))
                      .toList(),
                ),
        ),

        if (isPrivate && isCurrentUserOwner && pendingParticipants.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            "Solicitações Pendentes (${pendingParticipants.length}):",
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.underBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: pendingParticipants
                  .map((p) => _buildPendingItem(context, ref, p.uid, currentUserId))
                  .toList(),
            ),
          ),
        ] else if (isPrivate && isCurrentUserOwner && pendingParticipants.isEmpty) ...[
          const SizedBox(height: 24),
          Text(
            "Solicitações Pendentes:",
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.underBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Nenhuma solicitação pendente no momento.",
              style: TextStyle(color: AppColors.greyLight, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ]
      ],
    );
  }
}