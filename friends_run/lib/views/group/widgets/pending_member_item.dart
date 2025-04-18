import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/providers/group_provider.dart';
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/utils/colors.dart';

class PendingMemberItem extends ConsumerWidget {
  final String pendingUserId;
  final String groupId;

  const PendingMemberItem({
    required this.pendingUserId,
    required this.groupId,
    super.key,
  });

  Future<void> _approveMember(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(groupServiceProvider).approveMember(groupId, pendingUserId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$pendingUserId aprovado(a)!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      ref.invalidate(groupDetailsProvider(groupId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro ao aprovar: ${e.toString().replaceFirst("Exception: ", "")}",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _rejectMember(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(groupServiceProvider).removeOrRejectMember(
        groupId,
        pendingUserId,
        isPending: true,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitação de $pendingUserId rejeitada.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      ref.invalidate(groupDetailsProvider(groupId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro ao rejeitar: ${e.toString().replaceFirst("Exception: ", "")}",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isLoadingAction = ref.watch(raceNotifierProvider).isLoading;
    final userAsync = ref.watch(userProvider(pendingUserId));

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.greyDark,
            ),
            title: Text(
              'Usuário pendente não encontrado',
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
                backgroundImage: (user.profileImageUrl != null && 
                                user.profileImageUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(user.profileImageUrl!)
                    : null,
                child: (user.profileImageUrl == null || 
                       user.profileImageUrl!.isEmpty)
                    ? const Icon(
                        Icons.person_outline,
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
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.greenAccent,
                  ),
                  iconSize: 22,
                  tooltip: "Aprovar",
                  padding: EdgeInsets.zero,
                  onPressed: isLoadingAction ? null : () => _approveMember(context, ref),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.redAccent,
                  ),
                  iconSize: 22,
                  tooltip: "Rejeitar",
                  padding: EdgeInsets.zero,
                  onPressed: isLoadingAction ? null : () => _rejectMember(context, ref),
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
              'Erro',
              style: TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}