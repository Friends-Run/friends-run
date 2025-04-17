class MyMetrics {
  final String userId;
  final int totalDistance; // em metros
  final int time; // em segundos
  final int pace; // em segundos por km
  final double speed; // em m/s
  final double calories; // em kcal

  MyMetrics({
    required this.userId,
    required this.totalDistance,
    required this.time,
    required this.pace,
    required this.speed,
    required this.calories,
  });
}
