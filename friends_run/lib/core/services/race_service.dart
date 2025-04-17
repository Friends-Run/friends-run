import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friends_run/core/services/google_maps_service.dart';
import 'package:friends_run/models/race/race_model.dart';
import 'package:friends_run/models/user/app_user.dart';
import 'package:geolocator/geolocator.dart';

class RaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'races';
  final GoogleMapsService _mapsService = GoogleMapsService();

  // CREATE - Adicionar nova corrida
  Future<Race> createRace({
    required String title,
    required DateTime date,
    required String startAddress,
    required String endAddress,
    required AppUser owner,
    bool isPrivate = false,
    String? groupId,
  }) async {
    try {
      // 1. Geocodificar os endereços
      final startCoords = await _mapsService.getCoordinatesFromAddress(
        startAddress,
      );
      final endCoords = await _mapsService.getCoordinatesFromAddress(
        endAddress,
      );

      if (startCoords == null || endCoords == null) {
        throw Exception(
          'Não foi possível obter coordenadas para os endereços fornecidos.',
        );
      }

      // 2. Calcular distância entre pontos (em km)
      final distance = _calculateDistance(
        startCoords['lat']!,
        startCoords['lng']!,
        endCoords['lat']!,
        endCoords['lng']!,
      );

      // 3. Obter imagem do mapa da rota
      final imageUrl = await _mapsService.getRouteMapImage(
        startLat: startCoords['lat']!,
        startLng: startCoords['lng']!,
        endLat: endCoords['lat']!,
        endLng: endCoords['lng']!,
      );

      final now = DateTime.now();

      final newRace = Race(
        id: '',
        title: title,
        date: date,
        distance: distance,
        participants: [owner],
        pendingParticipants: [],
        startLatitude: startCoords['lat']!,
        startLongitude: startCoords['lng']!,
        endLatitude: endCoords['lat']!,
        endLongitude: endCoords['lng']!,
        startAddress: startAddress,
        endAddress: endAddress,
        imageUrl: imageUrl,
        createdAt: now,
        updatedAt: now,
        owner: owner,
        ownerId: owner.uid,
        groupId: groupId,
        isPrivate: isPrivate,
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(newRace.toJson());

      return newRace.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Erro ao criar corrida: $e');
    }
  }

  // READ - Obter corrida por ID
  Future<Race> getRace(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return Race.fromJson(doc.data()!..['id'] = doc.id);
      }
      throw Exception('Race not found');
    } catch (e) {
      throw Exception('Failed to get race: $e');
    }
  }

  // UPDATE - Atualizar corrida
  Future<void> updateRace(Race race) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(race.id)
          .update(race.toJson());
    } catch (e) {
      throw Exception('Failed to update race: $e');
    }
  }

  // DELETE - Remover corrida
  Future<void> deleteRace(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete race: $e');
    }
  }

  // LISTEN - Stream de todas corridas
  Stream<List<Race>> get racesStream {
    return _firestore
        .collection(_collectionName)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Race.fromJson(doc.data()..['id'] = doc.id))
                  .toList(),
        );
  }

  // Consulta por grupo
  Stream<List<Race>> getRacesByGroup(String groupId) {
    return _firestore
        .collection(_collectionName)
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Race.fromJson(doc.data()..['id'] = doc.id))
                  .toList(),
        );
  }

  // Consulta por usuário (criador)
  Stream<List<Race>> getRacesByOwner(String ownerId) {
    return _firestore
        .collection(_collectionName)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Race.fromJson(doc.data()..['id'] = doc.id))
                  .toList(),
        );
  }

  // Consulta por participante
  Stream<List<Race>> getRacesByParticipant(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('participants', arrayContains: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Race.fromJson(doc.data()..['id'] = doc.id))
                  .toList(),
        );
  }

  // Consulta por participante sem ordenar
  Stream<List<Race>> getRacesByParticipantWithoutOrder(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Race.fromJson(doc.data()..['id'] = doc.id))
                  .toList(),
        );
  }

  // Adicionar participante
  Future<void> addParticipant(String raceId, String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(raceId).update({
        'participants': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to add participant: $e');
    }
  }

  // Remover participante
  Future<void> removeParticipant(String raceId, String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(raceId).update({
        'participants': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to remove participant: $e');
    }
  }

  // Adicionar solicitação de participação
  Future<void> addParticipationRequest(String raceId, String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(raceId).update({
        'pendingParticipants': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to add participation request: $e');
    }
  }

  /// Remove um usuário da lista de solicitações pendentes de uma corrida.
  Future<void> removePendingParticipant(String raceId, String userId) async {
    try {
      await _firestore.collection('races').doc(raceId).update({
        'pendingParticipants': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(), // Atualiza data de modificação
      });
      print("Solicitação pendente de $userId removida da corrida $raceId");
    } catch (e) {
      print("Erro ao remover solicitação pendente: $e");
      // Relança a exceção para ser tratada pelo Notifier
      throw Exception("Falha ao remover solicitação pendente.");
    }
  }

  // --- Método approveParticipant (precisa existir ou ser verificado) ---
  Future<void> approveParticipant(String raceId, String userId) async {
    try {
      // Remove da lista de pendentes e adiciona à lista de participantes
      // ATENÇÃO: Isso deve ser feito atomicamente se possível,
      // mas uma atualização simples geralmente funciona bem.
      await _firestore.collection('races').doc(raceId).update({
        'pendingParticipants': FieldValue.arrayRemove([userId]),
        'participants': FieldValue.arrayUnion([
          userId,
        ]), // Adiciona à lista principal
        'updatedAt': Timestamp.now(),
      });
      print("Participante $userId aprovado para a corrida $raceId");
    } catch (e) {
      print("Erro ao aprovar participante: $e");
      throw Exception("Falha ao aprovar participante.");
    }
  }

  Future<List<Race>> getNearbyRaces(
    Position userPosition, {
    double radiusInKm = 100000000.0,
  }) async {
    // Calcula os limites geográficos
    final lat = userPosition.latitude;
    final lng = userPosition.longitude;

    // Aproximação de 1 grau = ~111km
    final degree = radiusInKm / 111.0;
    final lowerLat = lat - degree;
    final upperLat = lat + degree;
    final lowerLng = lng - degree;
    final upperLng = lng + degree;

    try {
      // Consulta no Firestore por corridas dentro do retângulo aproximado
      final query = _firestore
          .collection(_collectionName)
          .where('startLatitude', isGreaterThanOrEqualTo: lowerLat)
          .where('startLatitude', isLessThanOrEqualTo: upperLat)
          .where('startLongitude', isGreaterThanOrEqualTo: lowerLng)
          .where('startLongitude', isLessThanOrEqualTo: upperLng);

      final snapshot = await query.get();

      // Filtra os resultados para obter apenas os dentro do raio exato
      final races =
          snapshot.docs.map((doc) {
            return Race.fromJson(doc.data()..['id'] = doc.id);
          }).toList();

      return races.where((race) {
        final distance =
            Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              race.startLatitude,
              race.startLongitude,
            ) /
            1000; // Converte para km

        return distance <= radiusInKm;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby races: $e');
    }
  }

  Future<void> leaveRace(String raceId, String userId) async {
    try {
      print("Tentando remover $userId da corrida $raceId");
      await _firestore.collection(_collectionName).doc(raceId).update({
        'participants': FieldValue.arrayRemove([
          userId,
        ]), // Remove o ID do array
        // Considerar: remover também de pendingParticipants se ele pudesse estar lá?
        // 'pendingParticipants': FieldValue.arrayRemove([userId]),
      });
      print("Usuário $userId removido com sucesso da corrida $raceId");
    } catch (e) {
      print("Erro ao remover participante $userId da corrida $raceId: $e");
      // Relança a exceção para ser tratada no Notifier/UI
      throw Exception('Failed to leave race: $e');
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // π / 180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R * asin...
  }
}
