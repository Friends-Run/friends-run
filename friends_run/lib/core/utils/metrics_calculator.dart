import 'dart:math';

class MetricsCalculator {
  static Duration calculatePace(Duration duration, double distanceMeters) {
    if (distanceMeters <= 0 || duration <= Duration.zero) {
      return Duration.zero;
    }
    final double distanceKm = distanceMeters / 1000.0;
    final double avgMillisPerKm = duration.inMilliseconds / distanceKm;
    // Evita paces irrealisticamente baixos devido a possíveis imprecisões
    if (avgMillisPerKm < 1000) return Duration.zero; // Menos de 1 seg/km? Impossível.
    return Duration(milliseconds: avgMillisPerKm.round());
  }

  static double calculateSpeedKmh(Duration duration, double distanceMeters) {
    if (distanceMeters <= 0 || duration <= Duration.zero) {
      return 0.0;
    }
    final double distanceKm = distanceMeters / 1000.0;
    final double durationHours = duration.inSeconds / 3600.0;
    if (durationHours <= 0) return 0.0; // Evita divisão por zero
    return distanceKm / durationHours;
  }

  // Adicione outras funções de cálculo se necessário
}