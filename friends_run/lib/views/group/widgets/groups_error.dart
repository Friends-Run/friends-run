import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/providers/group_provider.dart'; // Importa o provider da lista de grupos
import 'package:friends_run/core/utils/colors.dart';

class GroupsErrorWidget extends ConsumerWidget {
  final Object error; // Recebe o erro
  const GroupsErrorWidget({required this.error, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
            const SizedBox(height: 16),
            const Text(
              "Erro ao carregar seus grupos:",
              style: TextStyle(color: AppColors.white, fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
             Text(
              error.toString().replaceFirst("Exception: ", ""), // Mostra a mensagem de erro
              style: TextStyle(color: Colors.redAccent.withOpacity(0.9), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Tentar Novamente"),
              onPressed: () => ref.invalidate(userGroupsProvider), // Invalida para tentar recarregar
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}