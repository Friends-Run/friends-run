import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/models/group/race_group.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/providers/group_provider.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/views/group/group_details_view.dart';
import 'package:friends_run/views/group/widgets/empty_groups_message.dart';
import 'package:friends_run/views/group/widgets/group_list.dart';
import 'package:friends_run/views/group/widgets/groups_error.dart';
import 'package:friends_run/views/group/create_group_view.dart';

class GroupsListView extends ConsumerWidget {
  final bool showAllGroups; // Parâmetro para controlar qual lista mostrar
  
  const GroupsListView({super.key, this.showAllGroups = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa o provider apropriado baseado no parâmetro
    final groupsAsync = showAllGroups 
        ? ref.watch(allGroupsProvider) 
        : ref.watch(userGroupsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          showAllGroups ? "Explorar Grupos" : "Meus Grupos", 
          style: const TextStyle(color: AppColors.white)
        ),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            tooltip: "Atualizar Lista",
            onPressed: () => showAllGroups 
                ? ref.invalidate(allGroupsProvider)
                : ref.invalidate(userGroupsProvider),
          ),
        ]
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return showAllGroups
                ? const Center(
                    child: Text(
                      "Nenhum grupo encontrado no momento.", 
                      style: TextStyle(color: AppColors.greyLight, fontSize: 16)
                    )
                  )
                : const EmptyGroupsMessage();
          } else {
            return GroupList(groups: groups, showAllGroups: showAllGroups);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
        error: (error, stack) {
          return GroupsErrorWidget(error: error);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Criar Grupo"),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.white,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupView()));
        },
      ),
    );
  }
}

class GroupListItem extends ConsumerWidget {
  final RaceGroup group;
  final bool showAllGroups;

  const GroupListItem({
    required this.group, 
    this.showAllGroups = false,
    super.key
  });

  Widget _buildActionWidget(BuildContext context, WidgetRef ref, String? currentUserId) {
    // Se não for a lista de exploração ou usuário deslogado, mostra só a seta
    if (!showAllGroups || currentUserId == null) {
      return const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.greyLight);
    }

    // Verifica o status do usuário em relação ao grupo
    final bool isAdmin = group.adminId == currentUserId;
    final bool isMember = group.memberIds.contains(currentUserId);
    final bool isPending = group.pendingMemberIds.contains(currentUserId);
    // Verifica se alguma ação de grupo/corrida está em andamento
    final bool isLoadingAction = ref.watch(raceNotifierProvider).isLoading;

    // Se for admin ou membro, mostra apenas a seta para detalhes
    if (isAdmin || isMember) {
      return const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.greyLight);
    }
    // Se a solicitação está pendente
    else if (isPending) {
      return Chip(
        label: const Text("Solicitado", style: TextStyle(fontSize: 11, color: AppColors.white)),
        backgroundColor: AppColors.greyDark,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        visualDensity: VisualDensity.compact,
      );
    }
    // Se for visitante (não admin, não membro, não pendente)
    else {
      if (group.isPublic) {
        // Botão para ENTRAR DIRETAMENTE em grupo público
        return SizedBox(
          height: 30,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.group_add_outlined, size: 16),
            label: const Text("Entrar"),
            onPressed: isLoadingAction ? null : () async {
              try {
                await ref.read(groupServiceProvider).joinPublicGroup(group.id, currentUserId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Você entrou no grupo "${group.name}"!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                // Invalida providers para atualizar a UI
                ref.invalidate(userGroupsProvider);
                ref.invalidate(allGroupsProvider);
                ref.invalidate(groupDetailsProvider(group.id));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao entrar: ${e.toString().replaceFirst("Exception: ", "")}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        );
      } else {
        // Botão para SOLICITAR ENTRADA em grupo privado
        return SizedBox(
          height: 30,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.vpn_key_outlined, size: 16),
            label: const Text("Solicitar"),
            onPressed: isLoadingAction ? null : () async {
              try {
                await ref.read(groupServiceProvider).requestToJoinGroup(group.id, currentUserId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solicitação enviada!'),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                }
                ref.invalidate(allGroupsProvider);
                ref.invalidate(groupDetailsProvider(group.id));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao solicitar: ${e.toString().replaceFirst("Exception: ", "")}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserProvider).asData?.value?.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.underBackground.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GroupDetailsView(groupId: group.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.greyDark,
                backgroundImage: (group.imageUrl != null && group.imageUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(group.imageUrl!)
                  : null,
                child: (group.imageUrl == null || group.imageUrl!.isEmpty)
                  ? const Icon(Icons.group, size: 28, color: AppColors.greyLight)
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        color: AppColors.white, 
                        fontSize: 17, 
                        fontWeight: FontWeight.bold
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.description?.isNotEmpty == true ? group.description! : 'Sem descrição',
                      style: TextStyle(color: AppColors.greyLight, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_alt_outlined, size: 16, color: AppColors.greyLight),
                        const SizedBox(width: 4),
                        Text(
                          "${group.memberIds.length} membro(s)",
                          style: const TextStyle(color: AppColors.greyLight, fontSize: 13),
                        ),
                        if (!showAllGroups) ...[
                          const SizedBox(width: 10),
                          Icon(
                            group.isPublic ? Icons.lock_open_outlined : Icons.lock_outline,
                            size: 14,
                            color: AppColors.greyLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            group.isPublic ? 'Público' : 'Privado',
                            style: const TextStyle(color: AppColors.greyLight, fontSize: 13),
                          ),
                        ],
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildActionWidget(context, ref, currentUserId),
            ],
          ),
        ),
      ),
    );
  }
}