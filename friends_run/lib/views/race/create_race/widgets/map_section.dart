import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Para gesture recognizers
import 'package:flutter/foundation.dart'; // Para Factory
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSection extends StatelessWidget {
  final AsyncValue<CameraPosition> initialCameraPositionAsync;
  final Set<Marker> markers;
  final ArgumentCallback<LatLng> onMapTap;
  final MapCreatedCallback onMapCreated;

  const MapSection({
    required this.initialCameraPositionAsync,
    required this.markers,
    required this.onMapTap,
    required this.onMapCreated,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Mapa Interativo:", style: TextStyle(color: AppColors.white, fontSize: 16)),
         Padding(
           padding: const EdgeInsets.symmetric(vertical: 4.0),
           child: Text(
             markers.isEmpty ? "Busque pelos endereços ou toque no mapa."
               : markers.length == 1 ? "Defina o segundo endereço ou toque/arraste."
               : "Arraste os marcadores para ajustar.",
             style: const TextStyle(color: AppColors.greyLight, fontStyle: FontStyle.italic)
           ),
         ),
         const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: ClipRRect(
             borderRadius: BorderRadius.circular(12),
            child: initialCameraPositionAsync.when(
               data: (initialPosition) => GoogleMap(
                  onMapCreated: onMapCreated,
                  initialCameraPosition: initialPosition,
                  markers: markers,
                  onTap: onMapTap,
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  compassEnabled: true,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                    Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                    Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                  },
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                ),
               loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
               error: (err, stack) => Center(child: Text("Erro ao carregar mapa: $err", style: const TextStyle(color: Colors.redAccent)))
             ),
          ),
        ),
      ],
    );
  }
}