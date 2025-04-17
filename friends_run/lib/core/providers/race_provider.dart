import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/services/race_service.dart';
import 'package:friends_run/models/race/race_model.dart';
import 'package:friends_run/models/user/app_user.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:meta/meta.dart';
import 'package:geolocator/geolocator.dart';
import 'package:friends_run/core/providers/location_provider.dart';

enum RaceActionType {
  join,
  leave,
  request,
  approve,
  reject,
  create,
  update,
  delete,
  none,
}

enum RaceFilterOption { todas, publicas, privadas }

enum RaceSortCriteria { proximidade, distancia, data }

@immutable
class RaceActionState {
  final bool isLoading;
  final String? error;
  final RaceActionType actionType;

  const RaceActionState._({
    this.isLoading = false,
    this.error,
    this.actionType = RaceActionType.none,
  });

  factory RaceActionState.initial() => const RaceActionState._();

  RaceActionState copyWith({
    bool? isLoading,
    String? error,
    RaceActionType? actionType,
    bool clearError = false,
  }) {
    return RaceActionState._(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      actionType: actionType ?? this.actionType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RaceActionState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          error == other.error &&
          actionType == other.actionType;

  @override
  int get hashCode => isLoading.hashCode ^ error.hashCode ^ actionType.hashCode;
}

class RaceNotifier extends StateNotifier<RaceActionState> {
  final RaceService _raceService;

  RaceNotifier(this._raceService) : super(RaceActionState.initial());

  Stream<List<Race>> racesStream() => _raceService.racesStream;
  Stream<List<Race>> racesByGroup(String groupId) =>
      _raceService.getRacesByGroup(groupId);
  Stream<List<Race>> racesByOwner(String ownerId) =>
      _raceService.getRacesByOwner(ownerId);
  Stream<List<Race>> racesByParticipant(String userId) =>
      _raceService.getRacesByParticipant(userId);
  Stream<List<Race>> racesByParticipantWithoutOrder(String userId) =>
      _raceService.getRacesByParticipantWithoutOrder(userId);

  Future<Race?> createRace({
    required String title,
    required DateTime date,
    required String startAddress,
    required String endAddress,
    required AppUser owner,
    bool isPrivate = false,
    String? groupId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      actionType: RaceActionType.create,
      clearError: true,
    );
    try {
      final createdRace = await _raceService.createRace(
        title: title,
        date: date,
        startAddress: startAddress,
        endAddress: endAddress,
        owner: owner,
        isPrivate: isPrivate,
        groupId: groupId,
      );
      state = state.copyWith(isLoading: false, actionType: RaceActionType.none);
      return createdRace;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        actionType: RaceActionType.none,
        error: "Erro ao criar corrida: ${e.toString()}",
      );
      return null;
    }
  }

  Future<bool> updateRace(Race race) async {
    state = state.copyWith(
      isLoading: true,
      actionType: RaceActionType.update,
      clearError: true,
    );
    try {
      await _raceService.updateRace(race);
      state = state.copyWith(isLoading: false, actionType: RaceActionType.none);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        actionType: RaceActionType.none,
        error: "Erro ao atualizar corrida: ${e.toString()}",
      );
      return false;
    }
  }

  Future<bool> leaveRace(String raceId, String userId) async {
    state = state.copyWith(
      isLoading: true,
      actionType: RaceActionType.leave,
      clearError: true,
    );
    try {
      await _raceService.leaveRace(raceId, userId);
      state = state.copyWith(isLoading: false, actionType: RaceActionType.none);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        actionType: RaceActionType.none,
        error:
            "Erro ao sair da corrida: ${e.toString().replaceFirst("Exception: ", "")}",
      );
      return false;
    }
  }

  Future<bool> deleteRace(String id) async {
    state = state.copyWith(
      isLoading: true,
      actionType: RaceActionType.delete,
      clearError: true,
    );
    try {
      await _raceService.deleteRace(id);
      state = state.copyWith(isLoading: false, actionType: RaceActionType.none);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        actionType: RaceActionType.none,
        error: "Erro ao deletar corrida: ${e.toString()}",
      );
      return false;
    }
  }

  Future<bool> addParticipant(String raceId, String userId) async {
    state = state.copyWith(
      isLoading: true,
      actionType: RaceActionType.join,
      clearError: true,
    );
    try {
      await _raceService.addParticipant(raceId, userId);
      state = state.copyWith(isLoading: false, actionType: RaceActionType.none);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        actionType: RaceActionType.none,
        error: "Erro ao adicionar participante: ${e.toString()}",
      );
      return false;
    }
  }

  Future<bool> removeParticipant(String raceId, String userId) async {
    try {
      await _raceService.removeParticipant(raceId, userId);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: "Erro ao remover participante: ${e.toString()}",
      );
      return false;
    }
  }

  Future<bool> addParticipationRequest(String raceId, String userId) async {
    state = state.copyWith(
      isLoading: true,
      actionType: RaceActionType.request,
      clearError: true,
    );
    try {
      await _raceService.addParticipationRequest(raceId, userId);
      state = state.copyWith(isLoading: false, actionType: RaceActionType.none);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        actionType: RaceActionType.none,
        error: "Erro ao solicitar participação: ${e.toString()}",
      );
      return false;
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<bool> rejectParticipationRequest(String raceId, String userId) async {
    state = state.copyWith(
      isLoading: true,
      actionType: RaceActionType.reject,
      clearError: true,
    );
    try {
      await _raceService.removePendingParticipant(raceId, userId);
      state = state.copyWith(isLoading: false, actionType: RaceActionType.none);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        actionType: RaceActionType.none,
        error: e.toString().replaceFirst("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> approveParticipant(String raceId, String userId) async {
    state = state.copyWith(
      isLoading: true,
      actionType: RaceActionType.approve,
      clearError: true,
    );
    try {
      await _raceService.approveParticipant(raceId, userId);
      state = state.copyWith(isLoading: false, actionType: RaceActionType.none);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        actionType: RaceActionType.none,
        error: e.toString().replaceFirst("Exception: ", ""),
      );
      return false;
    }
  }
}

final raceServiceProvider = Provider<RaceService>((ref) {
  return RaceService();
});

final raceNotifierProvider =
    StateNotifierProvider<RaceNotifier, RaceActionState>((ref) {
      final raceService = ref.watch(raceServiceProvider);
      return RaceNotifier(raceService);
    });

final allRacesStreamProvider = StreamProvider.autoDispose<List<Race>>((ref) {
  ref.watch(raceNotifierProvider);
  return ref.read(raceNotifierProvider.notifier).racesStream();
});

final groupRacesStreamProvider = StreamProvider.family
    .autoDispose<List<Race>, String>((ref, groupId) {
      ref.watch(raceNotifierProvider);
      return ref.read(raceNotifierProvider.notifier).racesByGroup(groupId);
    });

final ownerRacesStreamProvider = StreamProvider.family
    .autoDispose<List<Race>, String>((ref, ownerId) {
      ref.watch(raceNotifierProvider);
      return ref.read(raceNotifierProvider.notifier).racesByOwner(ownerId);
    });

final participantRacesStreamProvider = StreamProvider.family
    .autoDispose<List<Race>, String>((ref, userId) {
      ref.watch(raceNotifierProvider);
      return ref.read(raceNotifierProvider.notifier).racesByParticipant(userId);
    });

final participantRacesNoOrderStreamProvider = StreamProvider.family
    .autoDispose<List<Race>, String>((ref, userId) {
      ref.watch(raceNotifierProvider);
      return ref
          .read(raceNotifierProvider.notifier)
          .racesByParticipantWithoutOrder(userId);
    });

final raceDetailsProvider = FutureProvider.family.autoDispose<Race?, String>((
  ref,
  raceId,
) async {
  final raceService = ref.watch(raceServiceProvider);
  try {
    return await raceService.getRace(raceId);
  } catch (e) {
    print("Erro ao buscar detalhes da corrida $raceId: $e");
    return null;
  }
});

final myRacesProvider = StreamProvider.autoDispose<List<Race>>((ref) {
  final userAsyncValue = ref.watch(currentUserProvider);

  return userAsyncValue.when(
    data: (user) {
      if (user == null) return Stream.value(<Race>[]);
      return ref.watch(participantRacesNoOrderStreamProvider(user.uid).stream);
    },
    loading: () => Stream.value(<Race>[]),
    error: (error, stackTrace) => Stream.error(error, stackTrace),
  );
});

const double defaultSearchRadiusKm = 25.0;
final distanceRadiusProvider = StateProvider<double>(
  (ref) => defaultSearchRadiusKm,
);

final nearbyRacesProvider = FutureProvider.autoDispose<List<Race>>((ref) async {
  final radius = ref.watch(distanceRadiusProvider);
  final raceService = ref.watch(raceServiceProvider);

  try {
    final Position? position = await ref.watch(currentLocationProvider.future);
    if (position == null) return <Race>[];
    return await raceService.getNearbyRaces(position, radiusInKm: radius);
  } catch (error) {
    throw Exception(
      "Falha ao buscar corridas próximas: ${error.toString().replaceFirst("Exception: ", "")}",
    );
  }
});

final raceFilterProvider = StateProvider<RaceFilterOption>(
  (ref) => RaceFilterOption.todas,
);
final raceSortCriteriaProvider = StateProvider<RaceSortCriteria>(
  (ref) => RaceSortCriteria.proximidade,
);
final sortAscendingProvider = StateProvider<bool>((ref) => true);

final displayedRacesProvider = Provider.autoDispose<AsyncValue<List<Race>>>((
  ref,
) {
  final nearbyRacesAsync = ref.watch(nearbyRacesProvider);
  final currentLocationAsync = ref.watch(currentLocationProvider);
  final filterOption = ref.watch(raceFilterProvider);
  final sortCriteria = ref.watch(raceSortCriteriaProvider);
  final isAscending = ref.watch(sortAscendingProvider);

  if (nearbyRacesAsync is AsyncLoading ||
      currentLocationAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (nearbyRacesAsync is AsyncError) {
    return AsyncError(nearbyRacesAsync.error!, nearbyRacesAsync.stackTrace!);
  }

  Position? userPosition;
  if (currentLocationAsync is AsyncData<Position?>) {
    userPosition = currentLocationAsync.value;
  } else if (currentLocationAsync is AsyncError &&
      sortCriteria == RaceSortCriteria.proximidade) {
    return AsyncError(
      "Não foi possível ordenar por proximidade: falha ao obter localização.",
      StackTrace.current,
    );
  }

  final races = nearbyRacesAsync.value ?? [];
  List<Race> filteredRaces = [];

  switch (filterOption) {
    case RaceFilterOption.publicas:
      filteredRaces = races.where((race) => !race.isPrivate).toList();
      break;
    case RaceFilterOption.privadas:
      filteredRaces = races.where((race) => race.isPrivate).toList();
      break;
    case RaceFilterOption.todas:
    default:
      filteredRaces = List.from(races);
      break;
  }

  switch (sortCriteria) {
    case RaceSortCriteria.proximidade:
      if (userPosition != null) {
        filteredRaces.sort((a, b) {
          try {
            final distA = Geolocator.distanceBetween(
              userPosition!.latitude,
              userPosition.longitude,
              a.startLatitude,
              a.startLongitude,
            );
            final distB = Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              b.startLatitude,
              b.startLongitude,
            );
            return isAscending
                ? distA.compareTo(distB)
                : distB.compareTo(distA);
          } catch (e) {
            return 0;
          }
        });
      }
      break;
    case RaceSortCriteria.distancia:
      filteredRaces.sort((a, b) {
        return isAscending
            ? a.distance.compareTo(b.distance)
            : b.distance.compareTo(a.distance);
      });
      break;
    case RaceSortCriteria.data:
      filteredRaces.sort((a, b) {
        return isAscending
            ? a.date.compareTo(b.date)
            : b.date.compareTo(a.date);
      });
      break;
  }

  return AsyncValue.data(filteredRaces);
});
