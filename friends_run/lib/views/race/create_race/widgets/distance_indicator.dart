import 'package:flutter/material.dart';
import 'package:friends_run/core/utils/colors.dart';

class DistanceIndicator extends StatelessWidget {
  final double distanceKm;
  const DistanceIndicator({required this.distanceKm, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Icon(Icons.straighten, color: AppColors.primaryRed, size: 20),
             const SizedBox(width: 8),
             Text(
               "Distância: ${distanceKm.toStringAsFixed(1)} km",
               style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w500),
             ),
          ],
        ),
     );
  }
}