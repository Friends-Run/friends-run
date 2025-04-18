import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/utils/colors.dart';

class MemberListItem extends ConsumerWidget {
  final String userId;
  final String adminId;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  const MemberListItem({
    required this.userId,
    required this.adminId,
    this.onRemove,
    this.showRemoveButton = true,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));
    final currentUserId = ref.watch(currentUserProvider).asData?.value?.uid;
    final bool isSelf = currentUserId == userId;
    final bool isLoadingAction = ref.watch(raceNotifierProvider).isLoading;

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
              'Usuário não encontrado',
              style: TextStyle(
                color: AppColors.greyLight,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          );
        }

        final bool isAdmin = user.uid == adminId;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.greyDark,
                backgroundImage: (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(user.profileImageUrl!)
                    : null,
                child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
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
              if (isAdmin)
                Tooltip(
                  message: "Admin",
                  child: Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: AppColors.primaryRed.withOpacity(0.8),
                  ),
                ),
              if (showRemoveButton && onRemove != null && !isAdmin && !isSelf)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    icon: const Icon(
                      Icons.person_remove_alt_1_outlined,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    tooltip: "Remover Membro",
                    padding: EdgeInsets.zero,
                    onPressed: isLoadingAction ? null : onRemove,
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
      error: (e, s) => Padding(
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