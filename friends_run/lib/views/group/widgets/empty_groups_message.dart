import 'package:flutter/material.dart';
import 'package:friends_run/core/utils/colors.dart'; // Suas cores

class EmptyGroupsMessage extends StatelessWidget {
  const EmptyGroupsMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_outlined, size: 80, color: AppColors.greyLight.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              "Você ainda não participa de nenhum grupo.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.greyLight, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "Crie um grupo ou procure por grupos públicos para participar!",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.greyLight, fontSize: 14),
            ),
            // Opcional: Botão para ir direto para criação?
            // const SizedBox(height: 20),
            // ElevatedButton.icon(
            //   onPressed: () { /* Navegar para CreateGroupView */ },
            //   icon: const Icon(Icons.add),
            //   label: const Text("Criar Grupo"),
            // )
          ],
        ),
      ),
    );
  }
}