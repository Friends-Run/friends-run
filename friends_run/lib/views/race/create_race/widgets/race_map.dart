import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RaceMap extends ConsumerWidget {
  final Set<Marker> markers;
  final Function(LatLng) onMapTap;
  final Function(GoogleMapController) onMapCreated;
  final AsyncValue<CameraPosition> initialCameraPosition;

  const RaceMap({
    super.key,
    required this.markers,
    required this.onMapTap,
    required this.onMapCreated,
    required this.initialCameraPosition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMapTitle(),
        _buildMapInstructions(),
        const SizedBox(height: 8),
        _buildMapContainer(),
      ],
    );
  }

  Widget _buildMapTitle() {
    return const Text(
      "Mapa Interativo:",
      style: TextStyle(color: AppColors.white, fontSize: 16),
    );
  }

  Widget _buildMapInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        markers.isEmpty
            ? "Busque pelos endereços ou toque no mapa."
            : markers.length == 1
                ? "Defina o segundo endereço ou toque/arraste."
                : "Arraste os marcadores para ajustar.",
        style: const TextStyle(
          color: AppColors.greyLight,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildMapContainer() {
    return SizedBox(
      height: 250,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: initialCameraPosition.when(
          data: (initialPosition) => _buildGoogleMap(initialPosition),
          loading: () => _buildLoadingIndicator(),
          error: (err, stack) => _buildErrorIndicator(err),
        ),
      ),
    );
  }

  Widget _buildGoogleMap(CameraPosition initialPosition) {
    return GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: initialPosition,
      markers: markers,
      onTap: onMapTap,
      mapType: MapType.normal,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      compassEnabled: true,
      gestureRecognizers: _createGestureRecognizers(),
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
    );
  }

  Set<Factory<OneSequenceGestureRecognizer>> _createGestureRecognizers() {
    return {
      Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
      Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
      Factory<PanGestureRecognizer>(
        () => PanGestureRecognizer()
          ..onStart = (details) {
            // Permite arrastar apenas com 2 dedos ou quando não há scroll vertical
            if (details.kind == PointerDeviceKind.touch) {
              return; // Bloqueia arraste com 1 dedo
            }
          },
      ),
    };
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryRed),
    );
  }

  Widget _buildErrorIndicator(dynamic error) {
    return Center(
      child: Text(
        "Erro ao carregar mapa: $error",
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}