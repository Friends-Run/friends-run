import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/providers/group_provider.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/views/group/edit_group_view.dart';
// Importe os novos widgets de item
import 'package:friends_run/views/group/widgets/member_list_item.dart';
import 'package:friends_run/views/group/widgets/pending_member_item.dart';
// Importe a futura tela de edição (opcional)
// import 'package:friends_run/views/group/edit_group_view.dart';

class GroupManagementView extends ConsumerWidget {
  final String groupId;
  const GroupManagementView({required this.groupId, super.key});

  // Função auxiliar para confirmar remoção de membro
  Future<bool> _confirmRemoveMember(
    BuildContext context,
    String memberName,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text("Remover Membro"),
                content: Text(
                  "Tem certeza que deseja remover $memberName do grupo?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancelar"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      "Remover",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false; // Retorna false se o diálogo for fechado
  }

  // Função auxiliar para confirmar deleção do grupo
  Future<bool> _confirmDeleteGroup(
    BuildContext context,
    String groupName,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text("Deletar Grupo"),
                content: Text(
                  "ATENÇÃO: Esta ação é irreversível!\nTem certeza que deseja deletar o grupo \"$groupName\"? Todas as corridas associadas podem ser perdidas.",
                  style: TextStyle(color: Colors.red.shade900),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancelar"),
                  ),
                  ElevatedButton(
                    // Botão de confirmação destacado
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      "DELETAR GRUPO",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailsProvider(groupId));
    final currentUserId = ref.watch(currentUserProvider).asData?.value?.uid;
    // Pode observar um notifier de ação de grupo aqui se criado

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          groupAsync.maybeWhen(
            data: (g) => g?.name ?? 'Gerenciar',
            orElse: () => 'Carregando...',
          ),
          style: const TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: groupAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
        error:
            (err, stack) => Center(
              child: Text(
                "Erro ao carregar dados do grupo: $err",
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
        data: (group) {
          if (group == null) {
            return const Center(
              child: Text(
                "Grupo não encontrado.",
                style: TextStyle(color: AppColors.greyLight),
              ),
            );
          }

          // Segurança extra: Verifica se quem abriu a tela é realmente o admin
          if (currentUserId == null || currentUserId != group.adminId) {
            return const Center(
              child: Text(
                "Acesso negado.",
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Seção Editar Detalhes ---
                ListTile(
                  leading: const Icon(
                    Icons.edit_note,
                    color: AppColors.primaryRed,
                  ),
                  title: const Text(
                    "Editar Informações",
                    style: TextStyle(color: AppColors.white, fontSize: 16),
                  ),
                  subtitle: const Text(
                    "Nome, descrição, imagem, privacidade",
                    style: TextStyle(color: AppColors.greyLight),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.greyLight,
                  ),
                  tileColor: AppColors.underBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditGroupView(group: group),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // --- Seção Membros Atuais ---
                Text(
                  "Membros Atuais (${group.memberIds.length})",
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
                    color: AppColors.underBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      group.memberIds.isEmpty
                          ? const Text(
                            "Apenas você.",
                            style: TextStyle(color: AppColors.greyLight),
                          ) // Se só o admin está
                          : Column(
                            children:
                                group.memberIds
                                    .map(
                                      (userId) => MemberListItem(
                                        userId: userId,
                                        adminId: group.adminId,
                                        // Passa a função de remover APENAS se não for o admin
                                        onRemove:
                                            userId == group.adminId
                                                ? null
                                                : () async {
                                                  // Pega o nome do usuário para confirmação
                                                  final userToRemove = await ref
                                                      .read(
                                                        userProvider(
                                                          userId,
                                                        ).future,
                                                      );
                                                  final confirm =
                                                      await _confirmRemoveMember(
                                                        context,
                                                        userToRemove?.name ??
                                                            'este membro',
                                                      );
                                                  if (confirm &&
                                                      context.mounted) {
                                                    try {
                                                      await ref
                                                          .read(
                                                            groupServiceProvider,
                                                          )
                                                          .removeOrRejectMember(
                                                            groupId,
                                                            userId,
                                                            isPending: false,
                                                          );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            '${userToRemove?.name ?? 'Membro'} removido.',
                                                          ),
                                                          backgroundColor:
                                                              Colors.orange,
                                                        ),
                                                      );
                                                      ref.invalidate(
                                                        groupDetailsProvider(
                                                          groupId,
                                                        ),
                                                      ); // Atualiza dados
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            "Erro ao remover: ${e.toString().replaceFirst("Exception: ", "")}",
                                                          ),
                                                          backgroundColor:
                                                              Colors.redAccent,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                      ),
                                    )
                                    .toList(),
                          ),
                ),
                const SizedBox(height: 24),

                // --- Seção Solicitações Pendentes (Se houver) ---
                if (group.pendingMemberIds.isNotEmpty && !group.isPublic) ...[
                  Text(
                    "Solicitações Pendentes (${group.pendingMemberIds.length})",
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
                      color: AppColors.underBackground.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orangeAccent.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          group.pendingMemberIds
                              .map(
                                (userId) => PendingMemberItem(
                                  pendingUserId: userId,
                                  groupId: groupId,
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else if (!group.isPublic) ...[
                  // Mensagem se não houver pendentes
                  Text(
                    "Solicitações Pendentes",
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

                // --- Zona de Perigo ---
                const Divider(color: AppColors.greyDark, height: 30),
                const Text(
                  "Zona de Perigo",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_forever),
                    label: const Text("Deletar Grupo"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final confirm = await _confirmDeleteGroup(
                        context,
                        group.name,
                      );
                      if (confirm && context.mounted) {
                        try {
                          await ref
                              .read(groupServiceProvider)
                              .deleteGroup(groupId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Grupo deletado com sucesso."),
                              backgroundColor: Colors.blueGrey,
                            ),
                          );
                          ref.invalidate(
                            allGroupsProvider,
                          ); // Invalida lista geral
                          ref.invalidate(
                            userGroupsProvider,
                          ); // Invalida lista do usuário
                          Navigator.pop(
                            context,
                          ); // Volta da tela de gerenciamento
                          Navigator.pop(
                            context,
                          ); // Volta da tela de detalhes (pode precisar de ajuste se a navegação for diferente)
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Erro ao deletar grupo: ${e.toString().replaceFirst("Exception: ", "")}",
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
