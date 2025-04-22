import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/services/metrics_service.dart';
// Certifique-se que o caminho para o seu modelo está correto
import 'package:friends_run/models/user/my_race_metrics.dart'; 
import 'package:meta/meta.dart'; // para @immutable

// --- Provider para a instância do MetricsService ---

final metricsServiceProvider = Provider<MetricsService>((ref) {
  // Simplesmente retorna uma nova instância do serviço.
  // Se o serviço tivesse dependências, elas seriam injetadas aqui.
  return MetricsService();
});

// --- Provider para buscar DADOS (Lista de Métricas) ---

/// Provider que busca a lista de [MyRaceMetrics] para um usuário específico.
/// Usa `.family` para aceitar `userId` como parâmetro.
/// Usa `.autoDispose` para limpar o cache quando a UI não estiver mais ouvindo.
final userMetricsProvider = FutureProvider.autoDispose
    .family<List<MyRaceMetrics>, String>((ref, userId) async {
  // Observa (watch) o provider do serviço para obter a instância.
  // Se o serviço for atualizado (improvável neste caso), este provider será reexecutado.
  final metricsService = ref.watch(metricsServiceProvider);
  // Chama o método do serviço. O FutureProvider gerencia loading/error.
  return metricsService.getUserMetrics(userId);
});


// --- Providers para gerenciar ESTADO DE AÇÕES (Salvar, Deletar) ---
// Similar ao seu RaceNotifier/RaceActionState

enum MetricsActionType { save, delete, none }

@immutable
class MetricsActionState {
  final bool isLoading;
  final String? error;
  final MetricsActionType actionType;
  // Pode adicionar um campo successMessage se quiser feedback positivo
  // final String? successMessage; 

  const MetricsActionState._({
    this.isLoading = false,
    this.error,
    this.actionType = MetricsActionType.none,
  });

  factory MetricsActionState.initial() => const MetricsActionState._();

  MetricsActionState copyWith({
    bool? isLoading,
    String? error,
    MetricsActionType? actionType,
    bool clearError = false,
    // String? successMessage,
    // bool clearSuccess = false,
  }) {
    return MetricsActionState._(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      actionType: actionType ?? this.actionType,
      // successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

   @override
   bool operator ==(Object other) => /* Implementação padrão */
       identical(this, other) ||
       other is MetricsActionState &&
           runtimeType == other.runtimeType &&
           isLoading == other.isLoading &&
           error == other.error &&
           actionType == other.actionType;

   @override
   int get hashCode => /* Implementação padrão */
      isLoading.hashCode ^ error.hashCode ^ actionType.hashCode;
}

class MetricsActionNotifier extends StateNotifier<MetricsActionState> {
  final MetricsService _metricsService;

  MetricsActionNotifier(this._metricsService) : super(MetricsActionState.initial());

  /// Salva as métricas de uma corrida para um usuário.
  /// Retorna o ID do documento salvo/atualizado em caso de sucesso, ou null em caso de falha.
  Future<String?> saveMetrics(MyRaceMetrics metrics) async {
    state = state.copyWith(isLoading: true, actionType: MetricsActionType.save, clearError: true);
    try {
      final docId = await _metricsService.saveUserRaceMetrics(metrics);
      state = state.copyWith(isLoading: false, actionType: MetricsActionType.none);
      // TODO: Considerar invalidar o userMetricsProvider aqui se a UI precisar refletir a mudança imediatamente
      // ref.invalidate(userMetricsProvider(metrics.userId));
      return docId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        actionType: MetricsActionType.none,
        error: e.toString().replaceFirst("Exception: ", ""),
      );
      return null;
    }
  }

  /// Deleta um registro de métrica específico.
  /// Retorna `true` em sucesso, `false` em falha.
  Future<bool> deleteMetrics(String metricsDocId, String userId) async {
     state = state.copyWith(isLoading: true, actionType: MetricsActionType.delete, clearError: true);
     try {
        await _metricsService.deleteUserRaceMetrics(metricsDocId);
        state = state.copyWith(isLoading: false, actionType: MetricsActionType.none);
        // TODO: Invalidar o provider para remover o item da lista na UI
        // ref.invalidate(userMetricsProvider(userId));
        return true;
     } catch (e) {
       state = state.copyWith(
         isLoading: false,
         actionType: MetricsActionType.none,
         error: e.toString().replaceFirst("Exception: ", ""),
       );
       return false;
     }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

// Provider para buscar uma métrica específica (útil para saber se já foi finalizada)
// Usa record como parâmetro da família: ({String userId, String raceId})
final specificMetricProvider = FutureProvider.autoDispose
    .family<MyRaceMetrics?, ({String userId, String raceId})>((ref, params) async {
  // Não busca se algum ID for inválido
  if (params.userId.isEmpty || params.raceId.isEmpty) {
    return null;
  }
  final service = ref.watch(metricsServiceProvider);
  // Chama o novo método do serviço
  return service.getSpecificUserRaceMetric(params.userId, params.raceId);
});

/// Provider para o Notifier que gerencia o estado das ações de métricas (salvar/deletar).
final metricsActionNotifierProvider =
    StateNotifierProvider<MetricsActionNotifier, MetricsActionState>((ref) {
  final metricsService = ref.watch(metricsServiceProvider);
  return MetricsActionNotifier(metricsService);
});