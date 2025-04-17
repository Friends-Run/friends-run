import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/services/google_maps_service.dart';

// Provider que expõe uma instância de GoogleMapsService
final googleMapsServiceProvider = Provider<GoogleMapsService>((ref) {
  return GoogleMapsService();
});
