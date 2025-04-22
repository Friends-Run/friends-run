import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/providers/location_provider.dart'
    hide nearbyRacesProvider; // Esconder se não usar nearbyRacesProvider
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/providers/metrics_provider.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/models/race/race_model.dart';
import 'package:friends_run/models/user/app_user.dart';
import 'package:friends_run/models/user/my_race_metrics.dart';
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

  Future<void> _finishRace(String userId) async {
    // ... (Lógica _finishRace com dados SIMULADOS como na resposta anterior) ...
    final race = widget.race;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final refReader = ref.read;

    // --- SIMULAÇÃO DAS MÉTRICAS ---
    final DateTime startTime = race.date;
    final DateTime endTime = DateTime.now();
    final Duration duration = endTime.difference(startTime);
    final double distanceMeters = race.distance * 1000;

    if (duration.isNegative ||
        duration < const Duration(seconds: 10) ||
        distanceMeters <= 0) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Dados inválidos para registrar."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Duration avgPacePerKm = Duration.zero;
    double avgSpeedKmh = 0.0;
    final double distanceKm = distanceMeters / 1000.0;
    if (distanceKm > 0)
      avgPacePerKm = Duration(
        milliseconds: (duration.inMilliseconds / distanceKm).round(),
      );
    if (duration.inSeconds > 0)
      avgSpeedKmh = (distanceKm / (duration.inSeconds / 3600.0));
    // --- FIM DA SIMULAÇÃO ---

    final newMetrics = MyRaceMetrics(
      /* ... preenche com dados ... */
      id: '',
      userId: userId,
      raceId: race.id,
      raceTitle: race.title,
      userStartTime: startTime,
      userEndTime: endTime,
      duration: duration,
      distanceMeters: distanceMeters,
      avgPacePerKm: avgPacePerKm,
      avgSpeedKmh: avgSpeedKmh,
      maxSpeedKmh: avgSpeedKmh * 1.2,
      caloriesBurned: (distanceKm * 70).round(),
      elevationGainMeters: null,
      avgHeartRate: null,
      maxHeartRate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      raceDate: race.date,
    );

    final notifier = refReader(metricsActionNotifierProvider.notifier);
    final savedId = await notifier.saveMetrics(newMetrics);

    if (context.mounted) {
      if (savedId != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Corrida "${race.title}" finalizada!'),
            backgroundColor: Colors.green,
          ),
        );
        // Invalida o provider para que a UI reflita que foi finalizado
        ref.invalidate(
          specificMetricProvider((userId: userId, raceId: widget.race.id)),
        ); // Passa um Record
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa providers necessários para ações e estado de loading
    // --- Observa os Providers ---
    final currentUserAsync = ref.watch(currentUserProvider);
    final raceActionState = ref.watch(
      raceNotifierProvider,
    ); // Estado de Ações da Corrida (Sair)
    final metricsActionState = ref.watch(
      metricsActionNotifierProvider,
    ); // Estado de Ações de Métricas (Finalizar)
    final currentLocationAsync = ref.watch(
      currentLocationProvider,
    ); // Para distância

    // Obtém o ID do usuário atual de forma segura
    final String currentUserId = currentUserAsync.valueOrNull?.uid ?? '';
    // Habilita ações apenas se logado
    final bool canPerformActions = currentUserId.isNotEmpty;
    // Verifica se alguma ação está em progresso
    final bool isActionLoading =
        raceActionState.isLoading || metricsActionState.isLoading;

    // --- Observa o Provider de Métrica Específica ---
    // Usa o ID atual e o ID da corrida. Passa um record para a família.
    final specificMetricAsync = ref.watch(
      specificMetricProvider((
        userId: currentUserId,
        raceId: widget.race.id,
      )), // Passa um Record
    );

    // --- Verifica o Status da Corrida ---
    final bool raceHasStarted = DateTime.now().isAfter(widget.race.date);

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.white.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RaceDetailsView(raceId: widget.race.id),
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Imagem da Corrida ---
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
                      (context, url) => Container(
                        height: 180,
                        color: AppColors.underBackground,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        height: 180,
                        color: AppColors.underBackground,
                        child: const Center(
                          child: Icon(
                            Icons.running_with_errors_rounded,
                            color: AppColors.greyLight,
                            size: 50,
                          ),
                        ),
                      ),
                ),
              ),
            // --- Conteúdo de Texto (Infos da Corrida) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(/* Título e Distancia */),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    widget.race.formattedDate,
                  ), // Já estava OK
                  _buildInfoRow(
                    // Linha ~277 corrigida
                    Icons.location_on_outlined,
                    (widget.race.startAddress.isNotEmpty &&
                            widget.race.endAddress.isNotEmpty)
                        ? '${widget.race.startAddress} → ${widget.race.endAddress}'
                        : 'De [${widget.race.startLatitude.toStringAsFixed(2)}, ${widget.race.startLongitude.toStringAsFixed(2)}] para [${widget.race.endLatitude.toStringAsFixed(2)}, ${widget.race.endLongitude.toStringAsFixed(2)}]',
                  ),
                  if (distanceToRaceStartKm !=
                      null) // Linha ~278 corrigida (dentro do if)
                    _buildInfoRow(
                      Icons.social_distance_outlined,
                      '${distanceToRaceStartKm.toStringAsFixed(1)} km de distância',
                    ),
                  _buildInfoRow(
                    // Linha ~279 corrigida
                    Icons.people_outline,
                    '${widget.race.participants.length} participante(s)',
                  ),
                  _buildInfoRow(
                    // Corrigindo também a linha de Pública/Privada
                    widget.race.isPrivate
                        ? Icons.lock_outline
                        : Icons.lock_open_outlined,
                    widget.race.isPrivate
                        ? 'Corrida Privada'
                        : 'Corrida Pública',
                  ),
                ],
              ),
            ),

            // --- BOTÕES DE AÇÃO ---
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ), // Ajuste o padding se necessário
              child: Center(
                // Centraliza o botão que sobrar
                child: _buildMiddleButton(
                  // Chama o helper que decide o botão
                  context: context,
                  specificMetricAsync: specificMetricAsync,
                  raceHasStarted: raceHasStarted,
                  canPerformActions: canPerformActions,
                  isActionLoading: isActionLoading,
                  currentUserId: currentUserId,
                ),
              ),
            ),
            /*
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 1. Botão Notificação
                  Tooltip(
                    message:
                        _isNotificationEnabled
                            ? 'Desativar notificações'
                            : 'Ativar notificações',
                    child: IconButton(
                      icon: Icon(
                        _isNotificationEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off_outlined,
                        color:
                            _isNotificationEnabled
                                ? AppColors.primaryRed
                                : AppColors.greyLight,
                      ),
                      onPressed:
                          canPerformActions && !isActionLoading
                              ? _toggleNotification
                              : null,
                    ),
                  ),

                  // 2. Botão Central Dinâmico (Loading / Sair / Finalizar / Finalizado)
                  _buildMiddleButton(
                    context:
                        context, // Passa o contexto se precisar para navegação ou dialogs
                    specificMetricAsync: specificMetricAsync,
                    raceHasStarted: raceHasStarted,
                    canPerformActions: canPerformActions,
                    isActionLoading: isActionLoading,
                    currentUserId: currentUserId, // Passa userId para as ações
                  ),

                  // 3. Botão Compartilhar
                  Tooltip(
                    message: 'Compartilhar corrida',
                    child: IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: AppColors.greyLight,
                      ),
                      onPressed: _handleShare, // Pode ser habilitado sempre
                    ),
                  ),
                ],
              ),
            ),
            */
          ],
        ),
      ),
    );
  }

  // --- Helper para construir o Botão Central ---
  Widget _buildMiddleButton({
    required BuildContext context,
    required AsyncValue<MyRaceMetrics?> specificMetricAsync,
    required bool raceHasStarted,
    required bool canPerformActions,
    required bool isActionLoading,
    required String currentUserId,
  }) {
    // Se não pode realizar ações (deslogado), mostra placeholder desabilitado
    if (!canPerformActions) {
      return const IconButton(
        icon: Icon(Icons.more_horiz, color: AppColors.greyDark),
        onPressed: null,
      );
    }

    // Usa o 'when' do AsyncValue para tratar os estados do provider de métrica
    return specificMetricAsync.when(
      // Estado: Carregando a informação se já finalizou ou não
      loading:
          () => const Padding(
            padding: EdgeInsets.all(
              12.0,
            ), // Padding para igualar tamanho do IconButton
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.greyLight,
              ),
            ),
          ),
      // Estado: Erro ao verificar se já finalizou
      error:
          (error, stack) => Tooltip(
            message: 'Erro ao verificar status',
            child: IconButton(
              icon: Icon(
                Icons.error_outline,
                color: Colors.orangeAccent.shade100,
              ),
              onPressed: null,
            ), // Botão de erro desabilitado
          ),
      // Estado: Dados recebidos (sabemos se finalizou ou não)
      data: (metric) {
        final bool alreadyFinished =
            metric != null; // Se métrica não é nula, já finalizou

        if (alreadyFinished) {
          // --- Já Finalizou ---
          return Tooltip(
            message: 'Corrida Finalizada',
            child: IconButton(
              icon: Icon(Icons.check_circle, color: Colors.green.shade300),
              onPressed: null, // Desabilitado pois já finalizou
            ),
          );
        } else if (raceHasStarted) {
          // --- Corrida Começou, NÃO Finalizou ---
          return Tooltip(
            message: 'Finalizar Corrida',
            child: IconButton(
              icon: const Icon(
                Icons.flag_circle_outlined,
                color: AppColors.white,
              ),
              // Desabilita se ação (Finalizar ou Sair) estiver carregando
              onPressed:
                  !isActionLoading ? () => _finishRace(currentUserId) : null,
            ),
          );
        } else {
          // --- Corrida NÃO Começou, NÃO Finalizou ---
          return Tooltip(
            message: 'Sair da corrida',
            child: IconButton(
              icon: const Icon(
                Icons.exit_to_app_rounded,
                color: AppColors.greyLight,
              ),
              // Desabilita se ação (Finalizar ou Sair) estiver carregando
              onPressed:
                  !isActionLoading
                      ? () => _showLeaveConfirmationDialog(currentUserId)
                      : null,
            ),
          );
        }
      },
    );
  }
}
