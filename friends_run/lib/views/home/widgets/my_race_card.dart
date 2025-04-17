import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/providers/location_provider.dart'
    hide nearbyRacesProvider; // Esconder se não usar nearbyRacesProvider
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/models/race/race_model.dart';
import 'package:friends_run/models/user/app_user.dart';
import 'package:geolocator/geolocator.dart';
import 'package:friends_run/views/race/race_details/race_details_view.dart';

// TODO: Adicionar um provider para gerenciar o estado das notificações
// Exemplo: final notificationPreferenceProvider = StateProvider.family<bool, String>((ref, raceId) => false);
// Ou armazenar essa preferência no Firestore (ex: subcoleção no usuário ou campo no participante da corrida)

class MyRaceCard extends ConsumerStatefulWidget {
  // Mudou para ConsumerStatefulWidget
  final Race race;
  const MyRaceCard({required this.race, super.key});

  @override
  ConsumerState<MyRaceCard> createState() => _MyRaceCardState();
}

class _MyRaceCardState extends ConsumerState<MyRaceCard> {
  // Estado local para o botão de notificação (idealmente viria de um provider)
  bool _isNotificationEnabled =
      false; // TODO: Carregar estado inicial de um provider/serviço

  // --- Método auxiliar para linhas de informação (igual ao RaceCard) ---
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.white.withAlpha(230),
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- Ação: Ligar/Desligar Notificações ---
  void _toggleNotification() {
    setState(() {
      _isNotificationEnabled = !_isNotificationEnabled;
    });
    // TODO: Chamar um método no provider/serviço para salvar a preferência de notificação
    // ex: ref.read(notificationManagerProvider).setNotificationForRace(widget.race.id, _isNotificationEnabled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isNotificationEnabled
              ? 'Notificações ativadas para "${widget.race.title}"'
              : 'Notificações desativadas para "${widget.race.title}"',
        ),
        backgroundColor:
            _isNotificationEnabled ? Colors.green : Colors.orangeAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- Ação: Sair da Corrida (com confirmação) ---
  void _showLeaveConfirmationDialog(String userId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Sair da Corrida',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Tem certeza que deseja sair da corrida "${widget.race.title}"?',
              style: const TextStyle(color: AppColors.black),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.greyDark),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primaryRed, // Ou uma cor de "perigo"
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context); // Fecha o diálogo
                  final success = await ref
                      .read(raceNotifierProvider.notifier)
                      .leaveRace(widget.race.id, userId);
                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Você saiu da corrida "${widget.race.title}".',
                        ),
                        backgroundColor: Colors.blueGrey,
                      ),
                    );
                    // Invalida o provider de "Minhas Corridas" para atualizar a lista na tela anterior
                    ref.invalidate(myRacesProvider);
                  }
                  // Erro já é tratado pelo listener global na MyRacesView
                },
                child: const Text('Confirmar Saída'),
              ),
            ],
          ),
    );
  }

  // --- Ação: Compartilhar Corrida ---
  void _handleShare() {
    print('Compartilhar corrida: ${widget.race.title}');
    // TODO: Implementar lógica de compartilhamento (ex: usar package 'share_plus')
    // Pode compartilhar um link para a corrida, ou detalhes básicos.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de compartilhar ainda não implementada.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Observa providers necessários para ações e estado de loading
    final currentUserAsync = ref.watch(currentUserProvider);
    final actionState = ref.watch(raceNotifierProvider);
    final currentLocationAsync = ref.watch(
      currentLocationProvider,
    ); // Para cálculo de distância

    // --- Cálculo da distância (opcional, igual ao RaceCard) ---
    double? distanceToRaceStartKm;
    if (currentLocationAsync is AsyncData<Position?> &&
        currentLocationAsync.value != null) {
      final userPos = currentLocationAsync.value!;
      distanceToRaceStartKm =
          Geolocator.distanceBetween(
            userPos.latitude,
            userPos.longitude,
            widget.race.startLatitude,
            widget.race.startLongitude,
          ) /
          1000.0;
    }

    // Determina se os botões de ação devem estar habilitados
    final bool canPerformActions =
        currentUserAsync is AsyncData<AppUser?> &&
        currentUserAsync.value != null;
    final String? currentUserId = currentUserAsync.value?.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.white.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navegação para detalhes continua igual
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RaceDetailsView(raceId: widget.race.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Imagem da Corrida (igual ao RaceCard) ---
            if (widget.race.imageUrl != null &&
                widget.race.imageUrl!.isNotEmpty)
              Hero(
                tag: 'race_image_${widget.race.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.race.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(/* ... placeholder ... */),
                  errorWidget:
                      (context, url, error) =>
                          Container(/* ... error widget ... */),
                ),
              ),

            // --- Conteúdo de Texto (igual ao RaceCard) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                8,
              ), // Diminui padding inferior
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Título e Distância (igual ao RaceCard) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.race.title,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.race.formattedDistance,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- Linhas de Informação (igual ao RaceCard) ---
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    widget.race.formattedDate,
                  ),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    (widget.race.startAddress.isNotEmpty &&
                            widget.race.endAddress.isNotEmpty)
                        ? '${widget.race.startAddress} → ${widget.race.endAddress}'
                        : 'De [${widget.race.startLatitude.toStringAsFixed(2)}, ${widget.race.startLongitude.toStringAsFixed(2)}] para [${widget.race.endLatitude.toStringAsFixed(2)}, ${widget.race.endLongitude.toStringAsFixed(2)}]',
                  ),
                  if (distanceToRaceStartKm != null)
                    _buildInfoRow(
                      Icons.social_distance_outlined,
                      '${distanceToRaceStartKm.toStringAsFixed(1)} km de distância',
                    ),
                  _buildInfoRow(
                    Icons.people_outline,
                    '${widget.race.participants.length} participante(s)',
                  ),
                  _buildInfoRow(
                    widget.race.isPrivate
                        ? Icons.lock_outline
                        : Icons.lock_open_outlined,
                    widget.race.isPrivate
                        ? 'Corrida Privada'
                        : 'Corrida Pública',
                  ),
                  // const SizedBox(height: 16), // Espaço antes do botão antigo removido
                ],
              ),
            ),

            // --- NOVA SEÇÃO DE BOTÕES DE AÇÃO ---
            Padding(
              padding: const EdgeInsets.fromLTRB(
                8,
                0,
                8,
                8,
              ), // Padding para a linha de botões
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround, // Ou spaceBetween
                children: [
                  // 1. Botão Notificação (Toggle)
                  Tooltip(
                    message:
                        _isNotificationEnabled
                            ? 'Desativar notificações'
                            : 'Ativar notificações (5 min antes)',
                    child: IconButton(
                      icon: Icon(
                        _isNotificationEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off_outlined,
                        color:
                            _isNotificationEnabled
                                ? AppColors.btnGreenStrong
                                : AppColors.btnGreen,
                      ),
                      onPressed:
                          canPerformActions
                              ? _toggleNotification
                              : null, // Desabilita se não logado
                    ),
                  ),

                  // 2. Botão Sair da Corrida
                  Tooltip(
                    message: 'Sair da corrida',
                    child: IconButton(
                      icon: const Icon(
                        Icons.exit_to_app_rounded,
                        color: AppColors.primaryRed,
                      ),
                      // Desabilita se não logado OU se uma ação de corrida já estiver em andamento
                      onPressed:
                          canPerformActions &&
                                  currentUserId != null &&
                                  !actionState.isLoading
                              ? () =>
                                  _showLeaveConfirmationDialog(currentUserId)
                              : null,
                    ),
                  ),

                  // 3. Botão Compartilhar
                  Tooltip(
                    message: 'Compartilhar corrida',
                    child: IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: AppColors.btnGreenStrong,
                      ),
                      onPressed:
                          _handleShare, // Pode ser habilitado mesmo deslogado, dependendo da lógica
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------
          ],
        ),
      ),
    );
  }
}
