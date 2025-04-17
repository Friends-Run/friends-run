import 'package:flutter/material.dart';
import 'package:friends_run/models/group/race_group.dart';
import 'package:friends_run/views/group/widgets/group_list_item.dart';

class GroupList extends StatelessWidget {
  final List<RaceGroup> groups;
  // --- NOVO PARÂMETRO ---
  final bool showAllGroups; // Indica se esta lista é a geral ou "meus grupos"

  const GroupList({
    required this.groups,
    required this.showAllGroups, // Requer o parâmetro
    super.key
  });
  // --------------------

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        // --- PASSA O PARÂMETRO PARA O ITEM ---
        return GroupListItem(
            group: groups[index],
            showAllGroups: showAllGroups, // Repassa o valor recebido
        );
        // ------------------------------------
      },
    );
  }
}