import 'dart:async';
import 'package:flutter/material.dart';
import 'package:friends_run/models/race/race_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RaceMapView extends StatelessWidget {
  final Race race;

  const RaceMapView({required this.race, super.key});

  @override
  Widget build(BuildContext context) {
    final startPoint = LatLng(race.startLatitude, race.startLongitude);
    final endPoint = LatLng(race.endLatitude, race.endLongitude);
    final markers = {
      Marker(
        markerId: const MarkerId('start'),
        position: startPoint,
        infoWindow: const InfoWindow(title: 'Início'),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: endPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Fim'),
      ),
    };

    // Lógica para calcular bounds
    LatLngBounds bounds;
     if (startPoint == endPoint) {
       const delta = 0.002; // Aumenta um pouco a área visível se início e fim são iguais
       bounds = LatLngBounds(
         southwest: LatLng(startPoint.latitude - delta, startPoint.longitude - delta),
         northeast: LatLng(startPoint.latitude + delta, startPoint.longitude + delta),
       );
     } else {
       bounds = LatLngBounds(
         southwest: LatLng(
           startPoint.latitude < endPoint.latitude ? startPoint.latitude : endPoint.latitude,
           startPoint.longitude < endPoint.longitude ? startPoint.longitude : endPoint.longitude,
         ),
         northeast: LatLng(
           startPoint.latitude > endPoint.latitude ? startPoint.latitude : endPoint.latitude,
           startPoint.longitude > endPoint.longitude ? startPoint.longitude : endPoint.longitude,
         ),
       );
     }


    final mapControllerCompleter = Completer<GoogleMapController>();

    return SizedBox(
      height: 250,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          markers: markers,
          initialCameraPosition: CameraPosition(
            target: LatLng(
              (startPoint.latitude + endPoint.latitude) / 2,
              (startPoint.longitude + endPoint.longitude) / 2,
            ),
            zoom: 14, // Zoom inicial pode ser ajustado
          ),
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: true,
          mapToolbarEnabled: false,
          mapType: MapType.normal,
          onMapCreated: (controller) {
            if (!mapControllerCompleter.isCompleted) {
              mapControllerCompleter.complete(controller);
            }
            // Anima a câmera para os bounds após um pequeno delay
            Future.delayed(const Duration(milliseconds: 100), () {
               controller.animateCamera(
                 CameraUpdate.newLatLngBounds(bounds, 60.0), // 60.0 é o padding
               );
            });
          },
        ),
      ),
    );
  }
}