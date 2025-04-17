import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:friends_run/core/services/location_service.dart';
import 'package:friends_run/models/race/race_model.dart';
import 'package:friends_run/core/providers/race_provider.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final currentLocationProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  try {
    final position = await locationService.getCurrentLocation();
    return position;
  } catch (e) {
    throw Exception("Falha ao obter localização: $e");
  }
});

final nearbyRacesProvider = FutureProvider<List<Race>>((ref) async {
  final locationAsyncValue = ref.watch(currentLocationProvider);
  final raceService = ref.watch(raceServiceProvider);

  return locationAsyncValue.when(
    data: (position) {
      if (position == null) return <Race>[];
      return raceService.getNearbyRaces(position);
    },
    error: (err, _) {
      throw Exception("Não foi possível buscar corridas: $err");
    },
    loading: () {
      return Future.delayed(const Duration(days: 1), () => <Race>[]);
    },
  );
});
