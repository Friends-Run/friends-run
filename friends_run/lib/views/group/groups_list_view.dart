import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/providers/group_provider.dart'; // Contém ambos os providers
import 'package:friends_run/core/utils/colors.dart';
// Widgets componentes
import 'package:friends_run/views/group/widgets/group_list.dart';
import 'package:friends_run/views/group/widgets/empty_groups_message.dart';
import 'package:friends_run/views/group/widgets/groups_error.dart';
import 'package:friends_run/views/group/create_group_view.dart';

class GroupsListView extends ConsumerWidget {
  final bool showAllGroups; // Parâmetro para controlar qual lista mostrar
  
  const GroupsListView({super.key, this.showAllGroups = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa o provider apropriado baseado no parâmetro
    final groupsAsync = showAllGroups 
        ? ref.watch(allGroupsProvider) 
        : ref.watch(userGroupsProvider);

    // Opcional: Listener para erros de ações (como solicitar entrada)
    // ref.listen<RaceActionState>(raceNotifierProvider, (_, next) { /* ... (Igual HomeView) */ });

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
                ? const Center(child: Text("Nenhum grupo encontrado no momento.", style: TextStyle(color: AppColors.greyLight)))
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