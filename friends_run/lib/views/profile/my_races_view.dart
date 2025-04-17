import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Importações Essenciais ---
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/utils/colors.dart';

// --- Importações de Widgets da UI ---
import 'package:friends_run/views/home/widgets/empty_list_message.dart'; // Usando o widget genérico
import 'package:friends_run/views/home/widgets/my_race_card.dart'; 
import 'package:friends_run/views/home/widgets/races_error.dart'; // Assumindo que este widget existe

//---------------------------------------------------
//       VISÃO "MINHAS CORRIDAS" (Com Botão Voltar)
//---------------------------------------------------

class MyRacesView extends ConsumerWidget {
  const MyRacesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final myRacesAsync = ref.watch(myRacesProvider);

    // Listener para erros de ações (como sair da corrida)
    ref.listen<RaceActionState>(raceNotifierProvider, (_, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(raceNotifierProvider.notifier).clearError();
      }
      // Você pode adicionar um listener para mensagens de SUCESSO aqui também
      // if (next.successMessage != null && next.successMessage!.isNotEmpty) { ... }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // Botão de Voltar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          tooltip: 'Voltar',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Minhas Corridas',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: myRacesAsync.when(
        //--------------------------------------
        // Estado: Dados Carregados com Sucesso
        //--------------------------------------
        data: (races) {
          final currentUser = currentUserAsync.valueOrNull;
          // Verifica se o usuário está logado antes de mostrar a lista
          if (currentUser == null) {
            // --- Mensagem para Usuário Deslogado ---
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Faça login para ver as corridas em que você está participando.',
                  // Usar opacidade para consistência com outros textos
                  style: TextStyle(color: AppColors.white.withAlpha(204), fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Verifica se a lista de corridas está vazia
          if (races.isEmpty) {
            // --- Mensagem para Lista Vazia ---
            return const EmptyListMessage(
              message: 'Você ainda não está participando de nenhuma corrida.',
              icon: Icons.emoji_events_outlined, // Ícone de troféu/evento vazio
            );
          }

          // --- Exibe a Lista de Corridas ---
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myRacesProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.primaryRed,
            backgroundColor: AppColors.background,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: races.length,
              itemBuilder: (context, index) {
                // Usa o novo MyRaceCard
                return MyRaceCard(race: races[index]);
              },
            ),
          );
        },
        //--------------------------------------
        // Estado: Carregando Dados
        //--------------------------------------
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
        //--------------------------------------
        // Estado: Erro ao Carregar Dados
        //--------------------------------------
        error: (error, stackTrace) => RacesErrorWidget( // Passa os parâmetros necessários
          error: error,
          onRetry: () => ref.invalidate(myRacesProvider), // Ação para tentar novamente
        ),
      ),
    );
  }
}