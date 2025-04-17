import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/providers/location_provider.dart'; // Importa o provider de localização
import 'package:friends_run/core/utils/colors.dart';

class EmptyRacesMessage extends ConsumerWidget {
  const EmptyRacesMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Verifica o estado da localização para dar a mensagem correta
    final locationState = ref.watch(currentLocationProvider);

    String message = 'Nenhuma corrida próxima encontrada.'; // Padrão

    locationState.whenOrNull( // Usa whenOrNull para simplificar
      data: (position) {
        if (position == null) {
          message = 'Não foi possível obter sua localização.\nVerifique as permissões.';
        }
      },
      error: (err, stack) {
         message = 'Não foi possível obter sua localização.\nVerifique as permissões e a conexão.';
      },
       // Não precisa de 'loading', pois a HomeView já mostra um loading geral
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
           // Corrigido: use withAlpha para opacidade
          style: TextStyle(
            color: AppColors.white.withAlpha(204), // (0.8 * 255).round()
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}