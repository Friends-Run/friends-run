import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // para @immutable
import 'package:intl/intl.dart';       // para formatação

@immutable
class MyRaceMetrics {
  final String id; // Document ID from Firestore
  final String userId;
  final String raceId;
  final DateTime? userStartTime; // Quando o usuário realmente começou
  final DateTime userEndTime;   // Quando o usuário realmente terminou
  final Duration duration;      // Duração calculada (endTime - startTime)
  final double distanceMeters;
  final Duration avgPacePerKm;  // Pace médio
  final double avgSpeedKmh;
  final double? maxSpeedKmh;
  final int? caloriesBurned;
  final double? elevationGainMeters;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime raceDate;      // Cópia da data da corrida original

  const MyRaceMetrics({
    required this.id,
    required this.userId,
    required this.raceId,
    this.userStartTime,
    required this.userEndTime,
    required this.duration,
    required this.distanceMeters,
    required this.avgPacePerKm,
    required this.avgSpeedKmh,
    this.maxSpeedKmh,
    this.caloriesBurned,
    this.elevationGainMeters,
    this.avgHeartRate,
    this.maxHeartRate,
    required this.createdAt,
    required this.updatedAt,
    required this.raceDate,
  });

  // --- Getters para Formatação ---

  // Formata a duração para HH:MM:SS ou MM:SS
  String get formattedDuration {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
    } else {
      return "${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
  }

  // Formata o pace para MM'SS"/km
  String get formattedPace {
    if (avgPacePerKm == Duration.zero) return "--'--\"/km";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = avgPacePerKm.inMinutes;
    final seconds = avgPacePerKm.inSeconds.remainder(60);
    return "$minutes'${twoDigits(seconds)}\"/km";
  }

  // Formata a distância para km com 2 casas decimais ou metros
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return "${distanceMeters.toStringAsFixed(0)} m";
    } else {
      return "${(distanceMeters / 1000).toStringAsFixed(2)} km";
    }
  }

  // --- Conversões Firestore ---

  factory MyRaceMetrics.fromJson(Map<String, dynamic> json, String docId) {
     // Função auxiliar segura para converter Timestamp para DateTime nullable
     DateTime? parseNullableDateTime(dynamic value) {
       if (value is Timestamp) return value.toDate();
       return null;
     }
     // Função auxiliar segura para converter Timestamp para DateTime non-nullable
     DateTime parseRequiredDateTime(dynamic value) {
        if (value is Timestamp) return value.toDate();
        print("Alerta: Timestamp obrigatório ausente ou inválido ($value). Usando data atual.");
        return DateTime.now();
     }

    return MyRaceMetrics(
      id: docId, // Usa o ID do documento passado
      userId: json['userId'] as String? ?? '',
      raceId: json['raceId'] as String? ?? '',
      userStartTime: parseNullableDateTime(json['userStartTime']),
      userEndTime: parseRequiredDateTime(json['userEndTime']),
      // Converte milissegundos de volta para Duration
      duration: Duration(milliseconds: json['durationMillis'] as int? ?? 0),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      // Converte milissegundos/km de volta para Duration
      avgPacePerKm: Duration(milliseconds: json['avgPaceMillisPerKm'] as int? ?? 0),
      avgSpeedKmh: (json['avgSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      maxSpeedKmh: (json['maxSpeedKmh'] as num?)?.toDouble(),
      caloriesBurned: json['caloriesBurned'] as int?,
      elevationGainMeters: (json['elevationGainMeters'] as num?)?.toDouble(),
      avgHeartRate: json['avgHeartRate'] as int?,
      maxHeartRate: json['maxHeartRate'] as int?,
      createdAt: parseRequiredDateTime(json['createdAt']),
      updatedAt: parseRequiredDateTime(json['updatedAt']),
      raceDate: parseRequiredDateTime(json['raceDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // id não é incluído aqui, pois é o ID do documento
      'userId': userId,
      'raceId': raceId,
      // Converte DateTime? para Timestamp?
      'userStartTime': userStartTime != null ? Timestamp.fromDate(userStartTime!) : null,
      'userEndTime': Timestamp.fromDate(userEndTime),
      // Converte Duration para milissegundos (int)
      'durationMillis': duration.inMilliseconds,
      'distanceMeters': distanceMeters,
      // Converte Duration Pace para milissegundos/km (int)
      'avgPaceMillisPerKm': avgPacePerKm.inMilliseconds,
      'avgSpeedKmh': avgSpeedKmh,
      'maxSpeedKmh': maxSpeedKmh,
      'caloriesBurned': caloriesBurned,
      'elevationGainMeters': elevationGainMeters,
      'avgHeartRate': avgHeartRate,
      'maxHeartRate': maxHeartRate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'raceDate': Timestamp.fromDate(raceDate),
    };
  }

  // --- copyWith, ==, hashCode --- (Implementações padrão)

  MyRaceMetrics copyWith({
    String? id,
    String? userId,
    String? raceId,
    DateTime? userStartTime,
    DateTime? userEndTime,
    Duration? duration,
    double? distanceMeters,
    Duration? avgPacePerKm,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    int? caloriesBurned,
    double? elevationGainMeters,
    int? avgHeartRate,
    int? maxHeartRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? raceDate,
  }) {
    return MyRaceMetrics(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      raceId: raceId ?? this.raceId,
      userStartTime: userStartTime ?? this.userStartTime,
      userEndTime: userEndTime ?? this.userEndTime,
      duration: duration ?? this.duration,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      avgPacePerKm: avgPacePerKm ?? this.avgPacePerKm,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      raceDate: raceDate ?? this.raceDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MyRaceMetrics &&
        other.id == id &&
        other.userId == userId &&
        other.raceId == raceId &&
        other.userStartTime == userStartTime &&
        other.userEndTime == userEndTime &&
        other.duration == duration &&
        other.distanceMeters == distanceMeters &&
        other.avgPacePerKm == avgPacePerKm &&
        other.avgSpeedKmh == avgSpeedKmh &&
        other.maxSpeedKmh == maxSpeedKmh &&
        other.caloriesBurned == caloriesBurned &&
        other.elevationGainMeters == elevationGainMeters &&
        other.avgHeartRate == avgHeartRate &&
        other.maxHeartRate == maxHeartRate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.raceDate == raceDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      raceId,
      userStartTime,
      userEndTime,
      duration,
      distanceMeters,
      avgPacePerKm,
      avgSpeedKmh,
      maxSpeedKmh,
      caloriesBurned,
      elevationGainMeters,
      avgHeartRate,
      maxHeartRate,
      createdAt,
      updatedAt,
      raceDate,
    );
  }
}