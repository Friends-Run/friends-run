import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/providers/metrics_provider.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/models/user/my_race_metrics.dart'; // Corrigido caminho se necessário
import 'package:friends_run/views/estatistic/metrics_details_view.dart';
import 'package:friends_run/views/home/widgets/empty_list_message.dart'; // Corrigido caminho se necessário
import 'package:friends_run/views/home/widgets/races_error.dart';
import 'package:friends_run/views/race/race_details/race_details_view.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // Para usar 'max' e 'min' com reduce

class UserStatsView extends ConsumerWidget {
  const UserStatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
    final metricsAsync = ref.watch(userMetricsProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          tooltip: 'Voltar',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Minhas Estatísticas',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: metricsAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
        error: (error, stackTrace) {
          print("Erro ao carregar métricas: $error\nStackTrace: $stackTrace");
          return Center(/* ... Widget de erro como antes ... */);
        },
        data: (metricsListOriginal) {
          // Renomeado para clareza
          if (userId.isEmpty) {
            return Center(/* ... Mensagem de login ... */);
          }
          if (metricsListOriginal.isEmpty) {
            return const EmptyListMessage(
              message:
                  'Você ainda não registrou nenhuma corrida para exibir estatísticas.',
              icon: Icons.query_stats_rounded,
            );
          }

          // --- ORDENAÇÃO MANUAL DA LISTA POR DATA (MAIS RECENTE PRIMEIRO) ---
          // Cria uma cópia modificável e ordena
          final List<MyRaceMetrics> metricsList = List.from(
            metricsListOriginal,
          );
          metricsList.sort(
            (a, b) => b.raceDate.compareTo(a.raceDate),
          ); // Descendente

          // --- Processamento e Cálculo das Estatísticas Agregadas ---
          // (A lógica de cálculo continua a mesma, mas usamos a lista original ou iteramos)
          final int totalRuns = metricsListOriginal.length;
          final double totalDistanceMeters = metricsListOriginal.fold(
            0.0,
            (sum, m) => sum + m.distanceMeters,
          );
          final Duration totalDuration = metricsListOriginal.fold(
            Duration.zero,
            (sum, m) => sum + m.duration,
          );
          final int totalCalories = metricsListOriginal.fold(
            0,
            (sum, m) => sum + (m.caloriesBurned ?? 0),
          );

          Duration overallAvgPace = Duration.zero;
          if (totalDistanceMeters > 0) {
            final double totalDistanceKm = totalDistanceMeters / 1000.0;
            overallAvgPace = Duration(
              milliseconds:
                  (totalDuration.inMilliseconds / totalDistanceKm).round(),
            );
          }

          // Cálculo de recordes iterando (mais seguro que sort múltiplo)
          MyRaceMetrics? bestPaceRun;
          Duration currentBestPace = const Duration(
            days: 999,
          ); // Valor inicial alto
          for (final metric in metricsListOriginal) {
            // Considera apenas paces válidos (> 0)
            if (metric.avgPacePerKm > Duration.zero &&
                metric.avgPacePerKm < currentBestPace) {
              currentBestPace = metric.avgPacePerKm;
              bestPaceRun = metric;
            }
          }

          MyRaceMetrics? longestRun;
          double currentLongestDist = -1.0;
          for (final metric in metricsListOriginal) {
            if (metric.distanceMeters > currentLongestDist) {
              currentLongestDist = metric.distanceMeters;
              longestRun = metric;
            }
          }

          // Formatação para exibição (igual antes)
          final distanceFormatter = NumberFormat("#,##0.0", "pt_BR");
          final numberFormatter = NumberFormat("#,##0", "pt_BR");
          final String formattedTotalDistance =
              "${distanceFormatter.format(totalDistanceMeters / 1000)} km";
          final String formattedTotalDuration = _formatDuration(totalDuration);
          final String formattedOverallPace = _formatPace(overallAvgPace);
          final String formattedTotalCalories =
              "${numberFormatter.format(totalCalories)} kcal";
          final String formattedBestPace =
              bestPaceRun != null
                  ? _formatPace(bestPaceRun.avgPacePerKm)
                  : "--'--\"";
          final String formattedLongestDistance =
              longestRun != null
                  ? "${distanceFormatter.format(longestRun.distanceMeters / 1000)} km"
                  : "- km";

          // --- Construção da UI (Dashboard) ---
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Card de Resumo Principal (igual antes) ---
                _buildSummaryCard(
                  totalRuns: totalRuns.toString(),
                  totalDistance: formattedTotalDistance,
                  avgPace: formattedOverallPace,
                ),
                const SizedBox(height: 24),

                // --- Grid de Métricas Chave (igual antes) ---
                Text(
                  'Recordes e Totais',
                  style: TextStyle(
                    color: AppColors.white.withAlpha(220),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.8,
                  children: [
                    _buildStatCard(
                      label: 'Maior Distância',
                      value: formattedLongestDistance,
                      icon: Icons.directions_run_rounded,
                      iconColor: Colors.blueAccent,
                      onTap:
                          longestRun != null
                              ? () => _navigateToMetricsDetails(
                                context,
                                longestRun!,
                              )
                              : null,
                    ),
                    _buildStatCard(
                      label: 'Melhor Pace',
                      value: formattedBestPace,
                      icon: Icons.speed_rounded,
                      iconColor: Colors.orangeAccent,
                      onTap:
                          bestPaceRun != null
                              ? () => _navigateToMetricsDetails(
                                context,
                                bestPaceRun!,
                              )
                              : null,
                    ),
                    _buildStatCard(
                      label: 'Tempo Total',
                      value: formattedTotalDuration,
                      icon: Icons.timer_outlined,
                      iconColor: Colors.purpleAccent,
                    ),
                    _buildStatCard(
                      label: 'Calorias Totais',
                      value: formattedTotalCalories,
                      icon: Icons.local_fire_department_outlined,
                      iconColor: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Seção de Últimas Corridas (MODIFICADO) ---
                Text(
                  'Últimas Corridas', // <-- Título alterado
                  style: TextStyle(
                    color: AppColors.white.withAlpha(220),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Usa Column e map para criar a lista de widgets
                // Usa a lista JÁ ORDENADA (metricsList)
                Column(
                  children:
                      metricsList.map((metric) {
                        // <-- Itera sobre a lista ordenada
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 8.0,
                          ), // Espaçamento entre os cards
                          // Reutiliza o mesmo widget de resumo da última corrida
                          child: _buildLastRunSummary(context, metric, onTap: () => _navigateToMetricsDetails(context, metric)),

                        );
                      }).toList(), // Converte o resultado do map em uma lista de Widgets
                ),
                // --- Fim da Modificação ---
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Widgets Auxiliares para Construir a UI ---

  Widget _buildSummaryCard({
    required String totalRuns,
    required String totalDistance,
    required String avgPace,
  }) {
    return Card(
      color: AppColors.white.withAlpha(30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(Icons.run_circle_outlined, totalRuns, 'Corridas'),
            _buildSummaryItem(Icons.route_outlined, totalDistance, 'Distância'),
            _buildSummaryItem(Icons.speed_outlined, avgPace, 'Pace Médio'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primaryRed, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppColors.white.withAlpha(180), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    Color iconColor = AppColors.primaryRed,
    VoidCallback?
    onTap, // Para tornar o card clicável (ex: ir para a corrida do recorde)
  }) {
    return Card(
      color: AppColors.white.withAlpha(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        // Adiciona InkWell se onTap for fornecido
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.white.withAlpha(180),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, color: iconColor, size: 22),
                ],
              ),

              const Spacer(), // Empurra o valor para baixo
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20, // Tamanho maior para o valor
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Exemplo de como mostrar um resumo da última corrida
  Widget _buildLastRunSummary(BuildContext context, MyRaceMetrics runMetric, {VoidCallback? onTap}) {
    return Card(
      color: AppColors.white.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ),
        leading: Icon(
          // Ícone pode variar se a corrida foi 'boa' ou 'ruim'? Exemplo:
          runMetric.avgPacePerKm < const Duration(minutes: 5)
              ? Icons
                  .local_fire_department // Foguinho para rápido
              : Icons.directions_run, // Normal
          color: AppColors.primaryRed,
          size: 30,
        ),
        // --- MODIFICADO ---
        title: Text(
          runMetric.raceTitle, // <<< Título da Corrida aqui
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          // Mover Distância, Duração, Pace e Data para o subtítulo
          '${runMetric.formattedDistance} em ${runMetric.formattedDuration} • Pace: ${runMetric.formattedPace}\n${DateFormat('dd/MM/yyyy').format(runMetric.raceDate)}', // Adiciona data em nova linha
          style: TextStyle(
            color: AppColors.white.withAlpha(180),
            height: 1.3,
          ), // Ajusta altura da linha
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // --- FIM DA MODIFICAÇÃO ---
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.white.withAlpha(150),
        ),
        onTap: onTap,
      ),
    );
  }

  // Função auxiliar para navegar para detalhes da corrida
  void _navigateToRaceDetails(BuildContext context, String raceId) {
    // Importe RaceDetailsView se necessário
    // import 'package:friends_run/views/race/race_details/race_details_view.dart';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RaceDetailsView(raceId: raceId)),
    );
  }

  // ADICIONAR o novo método de navegação
  void _navigateToMetricsDetails(BuildContext context, MyRaceMetrics metric) {
     Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MetricsDetailsView(initialMetrics: metric)),
     );
  }

  // Funções auxiliares de formatação (podem ir para um arquivo utils)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return "${hours}h ${twoDigits(minutes)}m"; // Simplificado para horas e minutos
    } else if (minutes > 0) {
      return "${minutes}m ${twoDigits(seconds)}s";
    } else {
      return "${seconds}s";
    }
  }

  String _formatPace(Duration pace) {
    if (pace == Duration.zero) return "--'--\"";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = pace.inMinutes;
    final seconds = pace.inSeconds.remainder(60);
    return "$minutes'${twoDigits(seconds)}\""; // Remove /km para caber melhor
  }
}
