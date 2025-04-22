import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Models e Providers
import 'package:friends_run/models/race/race_model.dart';
import 'package:friends_run/models/group/race_group.dart';
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/providers/group_provider.dart';

// Utils e Widgets
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/views/home/widgets/race_card.dart';
import 'package:friends_run/views/group/widgets/member_list_item.dart';
import 'package:friends_run/views/group/widgets/pending_member_item.dart';
import 'package:friends_run/views/group/group_management_view.dart';
import 'package:friends_run/views/race/create_race/create_race_view.dart';

// Provider para buscar as corridas de um grupo específico
final groupRacesProvider = StreamProvider.autoDispose
    .family<List<Race>, String>((ref, groupId) {
  if (groupId.isEmpty) return Stream.value([]);
  final raceService = ref.watch(raceServiceProvider);
  return raceService.getRacesByGroup(groupId);
});

class GroupDetailsView extends ConsumerWidget {
  final String groupId;
  const GroupDetailsView({required this.groupId, super.key});

  // Helper _buildInfoRow
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

  // Helper para o botão de Ação do Grupo
  Widget _buildGroupActionButton(
    BuildContext context,
    WidgetRef ref,
    RaceGroup group,
  ) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final bool isLoadingAction = ref.watch(raceNotifierProvider).isLoading;

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.login, size: 20),
              label: const Text("Faça login para interagir"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greyDark,
                foregroundColor: AppColors.white.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("TODO: Navegar para Login")),
                );
              },
            ),
          );
        }

        final String currentUserId = currentUser.uid;
        final bool isAdmin = group.adminId == currentUserId;
        final bool isMember = group.memberIds.contains(currentUserId);
        final bool isPending = group.pendingMemberIds.contains(currentUserId);

        String buttonText = "";
        Color buttonColor = AppColors.greyDark;
        IconData? buttonIcon;
        VoidCallback? onPressed;
        bool canInteract = false;

        if (isAdmin) {
          buttonText = "Gerenciar Grupo";
          buttonIcon = Icons.settings;
          buttonColor = AppColors.primaryRed;
          onPressed = () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupManagementView(groupId: group.id),
              ),
            );
          };
          canInteract = true;
        } else if (isMember) {
          buttonText = "Sair do Grupo";
          buttonColor = Colors.redAccent.shade700;
          buttonIcon = Icons.exit_to_app;
          onPressed = () async {
            bool? confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Confirmar Saída"),
                content: Text(
                    "Tem certeza que deseja sair do grupo \"${group.name}\"?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancelar"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      "Sair",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              try {
                await ref
                    .read(groupServiceProvider)
                    .leaveGroup(group.id, currentUserId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Você saiu do grupo."),
                    backgroundColor: Colors.blueGrey,
                  ),
                );
                ref.invalidate(userGroupsProvider);
                ref.invalidate(groupDetailsProvider(group.id));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Erro ao sair do grupo: ${e.toString().replaceFirst("Exception: ", "")}",
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          };
          canInteract = true;
        } else if (isPending) {
          buttonText = "Solicitação Enviada";
          buttonIcon = Icons.hourglass_top;
          canInteract = false;
        } else {
          if (group.isPublic) {
            buttonText = "Entrar no Grupo";
            buttonColor = AppColors.primaryRed;
            buttonIcon = Icons.group_add_outlined;
            onPressed = () async {
              try {
                await ref
                    .read(groupServiceProvider)
                    .joinPublicGroup(group.id, currentUserId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Você entrou no grupo "${group.name}"!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                ref.invalidate(userGroupsProvider);
                ref.invalidate(groupDetailsProvider(group.id));
                ref.invalidate(allGroupsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Erro ao entrar no grupo: ${e.toString().replaceFirst("Exception: ", "")}",
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            };
            canInteract = true;
          } else {
            buttonText = "Solicitar Entrada";
            buttonColor = Colors.orange.shade700;
            buttonIcon = Icons.vpn_key_outlined;
            onPressed = () async {
              try {
                await ref
                    .read(groupServiceProvider)
                    .requestToJoinGroup(group.id, currentUserId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solicitação enviada!'),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                }
                ref.invalidate(groupDetailsProvider(group.id));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Erro ao solicitar entrada: ${e.toString().replaceFirst("Exception: ", "")}",
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            };
            canInteract = true;
          }
        }

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: isLoadingAction && canInteract
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(buttonIcon, size: 20),
            label: Text(
              buttonText,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              disabledBackgroundColor: buttonColor.withOpacity(0.5),
              disabledForegroundColor: Colors.white.withOpacity(0.7),
            ),
            onPressed: isLoadingAction || !canInteract ? null : onPressed,
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 50,
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      ),
      error: (e, s) => const Center(
        child: Text(
          "Erro ao verificar usuário.",
          style: TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailsProvider(groupId));
    final currentUserId = ref.watch(currentUserProvider).asData?.value?.uid;

    ref.listen<RaceActionState>(raceNotifierProvider, (_, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro: ${next.error!}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          groupAsync.maybeWhen(
            data: (g) => g?.name ?? 'Grupo',
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
        child: groupAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
          error: (error, stack) => Center(
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
                    "Erro ao carregar grupo:\n$error",
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
                    onPressed: () => ref.invalidate(groupDetailsProvider(groupId)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (group) {
            if (group == null) {
              return const Center(
                child: Text(
                  "Grupo não encontrado.",
                  style: TextStyle(color: AppColors.greyLight, fontSize: 16),
                ),
              );
            }

            final bool isCurrentUserAdmin =
                currentUserId != null && currentUserId == group.adminId;
            final bool isCurrentUserMember =
                currentUserId != null && group.memberIds.contains(currentUserId);

            final adminNameWidget = Consumer(
              builder: (context, ownerRef, child) {
                final ownerAsync = ownerRef.watch(userProvider(group.adminId));
                return ownerAsync.when(
                  data: (ownerUser) => Text(
                    ownerUser?.name ?? '...',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  loading: () => const Text(
                    '...',
                    style: TextStyle(
                      color: AppColors.greyLight,
                      fontSize: 15,
                    ),
                  ),
                  error: (e, s) => const Text(
                    'Erro',
                    style: TextStyle(color: Colors.redAccent, fontSize: 15),
                  ),
                );
              },
            );

            final groupRacesAsync = ref.watch(groupRacesProvider(groupId));

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações do Grupo
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (group.description != null &&
                                group.description!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                group.description!,
                                style: const TextStyle(
                                  color: AppColors.greyLight,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              context,
                              Icons.shield_outlined,
                              "Admin",
                              adminNameWidget,
                            ),
                            _buildInfoRow(
                              context,
                              group.isPublic
                                  ? Icons.lock_open_outlined
                                  : Icons.lock_outline,
                              "Visibilidade",
                              Text(
                                group.isPublic ? "Público" : "Privado",
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botão de Ação Principal
                  _buildGroupActionButton(context, ref, group),
                  const SizedBox(height: 24),

                  // Lista de Membros Confirmados
                  Text(
                    "Membros (${group.memberIds.length}):",
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.underBackground.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: group.memberIds.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "Nenhum membro ainda.",
                              style: TextStyle(color: AppColors.greyLight),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: group.memberIds
                                .map(
                                  (userId) => MemberListItem(
                                    userId: userId,
                                    adminId: group.adminId,
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Seção de Membros Pendentes
                  if (isCurrentUserAdmin &&
                      group.pendingMemberIds.isNotEmpty &&
                      !group.isPublic) ...[
                    Text(
                      "Solicitações Pendentes (${group.pendingMemberIds.length}):",
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.underBackground.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: group.pendingMemberIds
                            .map(
                              (userId) => PendingMemberItem(
                                pendingUserId: userId,
                                groupId: group.id,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else if (isCurrentUserAdmin && !group.isPublic) ...[
                    const Text(
                      "Solicitações Pendentes:",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.underBackground.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Nenhuma solicitação pendente.",
                        style: TextStyle(
                          color: AppColors.greyLight,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Novo Botão Criar Corrida para o Grupo
                  if (isCurrentUserMember || isCurrentUserAdmin) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_road, size: 18),
                          label: const Text("Nova Corrida do Grupo"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.primaryRed.withOpacity(0.9),
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateRaceView(
                                  groupId: group.id,
                                  groupName: group.name,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const Divider(
                      color: AppColors.greyDark,
                      height: 24,
                      thickness: 0.5,
                    ),
                  ],

                  // Lista de Corridas do Grupo
                  const Text(
                    "Corridas do Grupo:",
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  groupRacesAsync.when(
                    data: (races) {
                      if (races.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.underBackground.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Nenhuma corrida agendada para este grupo.",
                            style: TextStyle(
                              color: AppColors.greyLight,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Column(
                        children: races
                            .map(
                              (race) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: RaceCard(race: race),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: CircularProgressIndicator(
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                    error: (e, s) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.redAccent.withOpacity(0.5)),
                      ),
                      child: Text(
                        "Erro ao carregar corridas: ${e.toString()}",
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}