import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint
// Certifique-se que o caminho para o seu modelo está correto
import 'package:friends_run/models/user/my_race_metrics.dart';

class MetricsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'userRaceMetrics';

  /// Busca todas as métricas de um usuário específico, ordenadas pela data da corrida.
  Future<List<MyRaceMetrics>> getUserMetrics(String userId) async {
    if (userId.isEmpty) {
      debugPrint("MetricsService: Tentativa de busca com userId vazio.");
      return []; // Retorna vazio se o userId for inválido
    }
    debugPrint("MetricsService: Buscando métricas para userId: $userId");
    try {
      final snapshot =
          await _firestore
              .collection(_collectionName)
              .where('userId', isEqualTo: userId)
              // Ordena pela cópia da data da corrida para eficiência
              //.orderBy('raceDate', descending: true)
              .get();

      // Mapeia os documentos para a lista de MyRaceMetrics
      final metricsList =
          snapshot.docs.map((doc) {
            final data = doc.data();
            // Passa o ID do documento para o fromJson
            return MyRaceMetrics.fromJson(data, doc.id);
          }).toList();

      debugPrint(
        "MetricsService: Encontradas ${metricsList.length} métricas para userId: $userId",
      );
      return metricsList;
    } catch (e, stackTrace) {
      debugPrint("Erro ao buscar métricas do usuário $userId: $e\n$stackTrace");
      // Relança a exceção para ser tratada pelo Provider
      throw Exception('Falha ao carregar o histórico de corridas.');
    }
  }

  Future<MyRaceMetrics?> getSpecificUserRaceMetric(
    String userId,
    String raceId,
  ) async {
    if (userId.isEmpty || raceId.isEmpty) return null;
    try {
      final snapshot =
          await _firestore
              .collection(_collectionName)
              .where('userId', isEqualTo: userId)
              .where('raceId', isEqualTo: raceId)
              .limit(1) // Só precisamos saber se existe um
              .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return MyRaceMetrics.fromJson(doc.data(), doc.id);
      }
      return null; // Não encontrou
    } catch (e) {
      print(
        "Erro ao buscar métrica específica para User $userId, Race $raceId: $e",
      );
      return null; // Retorna null em caso de erro também
    }
  }

  /// Salva ou atualiza um registro de métrica na coleção userRaceMetrics.
  /// Se metrics.id for vazio, cria um novo documento.
  /// Se metrics.id tiver valor, atualiza o documento existente (ou cria se não existir).
  Future<String> saveUserRaceMetrics(MyRaceMetrics metrics) async {
    debugPrint(
      "MetricsService: Salvando/Atualizando métrica para userId ${metrics.userId}, raceId ${metrics.raceId}",
    );
    try {
      // Prepara os dados para o Firestore
      final data =
          metrics
              .copyWith(
                // Garante que updatedAt seja atualizado
                updatedAt: DateTime.now(),
                // Garante que createdAt seja definido na primeira vez (copyWith preserva se já existir)
                createdAt:
                    metrics.createdAt == DateTime(0)
                        ? DateTime.now()
                        : metrics.createdAt,
              )
              .toJson();

      DocumentReference docRef;
      if (metrics.id.isEmpty) {
        debugPrint("MetricsService: Criando novo documento de métrica.");
        docRef = await _firestore.collection(_collectionName).add(data);
        debugPrint(
          "MetricsService: Novo documento criado com ID: ${docRef.id}",
        );
        return docRef.id; // Retorna o ID do novo documento
      } else {
        debugPrint(
          "MetricsService: Atualizando documento de métrica com ID: ${metrics.id}",
        );
        docRef = _firestore.collection(_collectionName).doc(metrics.id);
        // Usar 'set' com 'merge: true' é seguro para atualizar ou criar se não existir
        await docRef.set(data, SetOptions(merge: true));
        debugPrint("MetricsService: Documento ${metrics.id} atualizado.");
        return metrics.id; // Retorna o ID existente
      }
    } catch (e, stackTrace) {
      debugPrint(
        "Erro ao salvar métricas para userId ${metrics.userId}, raceId ${metrics.raceId}: $e\n$stackTrace",
      );
      throw Exception('Falha ao salvar as estatísticas da sua corrida.');
    }
  }

  /// Deleta um registro de métrica específico pelo seu ID de documento.
  Future<void> deleteUserRaceMetrics(String metricsDocId) async {
    if (metricsDocId.isEmpty) {
      debugPrint("MetricsService: Tentativa de deletar métrica com ID vazio.");
      throw ArgumentError("ID do documento de métrica não pode ser vazio.");
    }
    debugPrint("MetricsService: Deletando métrica com ID: $metricsDocId");
    try {
      await _firestore.collection(_collectionName).doc(metricsDocId).delete();
      debugPrint("MetricsService: Métrica $metricsDocId deletada com sucesso.");
    } catch (e, stackTrace) {
      debugPrint("Erro ao deletar métrica $metricsDocId: $e\n$stackTrace");
      throw Exception('Falha ao deletar o registro desta corrida.');
    }
  }

  // --- Outros métodos podem ser adicionados conforme necessário ---
  // Ex: Future<MyRaceMetrics?> getSpecificUserRaceMetric(String userId, String raceId)
  // Ex: Future<List<MyRaceMetrics>> getRaceLeaderboard(String raceId) // Ordenado por duração, etc.
}
