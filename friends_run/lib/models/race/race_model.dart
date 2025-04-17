import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para listEquals e @immutable
import 'package:intl/intl.dart';
import 'package:friends_run/models/user/app_user.dart';

@immutable
class Race {
  final String id;
  final String title;
  final double distance;
  final DateTime date;
  final bool isFinished; // Novo campo adicionado
  final List<AppUser> participants; // Contém AppUsers "parciais" (só ID) após fromJson
  final List<AppUser> pendingParticipants; // Contém AppUsers "parciais" (só ID) após fromJson
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final String startAddress;
  final String endAddress;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AppUser owner; // Contém AppUser "parcial" (só ID) após fromJson
  final String ownerId; // Mantido para fácil acesso/query
  final String? groupId;
  final bool isPrivate;

  const Race({
    required this.id,
    required this.title,
    required this.distance,
    required this.date,
    this.isFinished = false, // Valor padrão aqui
    this.participants = const [],
    this.pendingParticipants = const [],
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    required this.startAddress,
    required this.endAddress,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.owner,
    required this.ownerId,
    this.groupId,
    this.isPrivate = false,
  });

  // --- Getters ---
  bool get isPublic => !isPrivate;
  bool get belongsToGroup => groupId != null;

  String get formattedDistance {
    if (distance < 0.1) {
      return '${(distance * 1000).round()} m';
    } else if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  String get formattedDate {
     try {
       // Adapte o formato 'pt_BR' ou outro conforme necessário
       final formatter = DateFormat('dd/MM/yyyy - HH:mm');
       return formatter.format(date);
     } catch (e) {
       print("Erro ao formatar data: $e");
       return "Data inválida";
     }
  }

  // --- Métodos de Manipulação ---
  Race copyWith({
    String? id,
    String? title,
    double? distance,
    DateTime? date,
    bool? isFinished, // Adicionado
    List<AppUser>? participants,
    List<AppUser>? pendingParticipants,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
    String? startAddress,
    String? endAddress,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    AppUser? owner,
    String? ownerId,
    String? groupId,
    bool? isPrivate,
  }) {
    return Race(
      id: id ?? this.id,
      title: title ?? this.title,
      distance: distance ?? this.distance,
      date: date ?? this.date,
      isFinished: isFinished ?? this.isFinished, // Adicionado
      participants: participants ?? this.participants,
      pendingParticipants: pendingParticipants ?? this.pendingParticipants,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      endLatitude: endLatitude ?? this.endLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
      startAddress: startAddress ?? this.startAddress,
      endAddress: endAddress ?? this.endAddress,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      owner: owner ?? this.owner,
      ownerId: ownerId ?? (owner != null ? owner.uid : this.ownerId),
      groupId: groupId ?? this.groupId,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  factory Race.fromJson(Map<String, dynamic> json) {
    // Função auxiliar segura para converter Timestamp ou String (legado) para DateTime
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        try { return DateTime.parse(value); } catch (_) {}
      }
      print("Alerta: Tipo/formato de data inesperado ($value). Usando data atual.");
      return DateTime.now();
    }

    // Função auxiliar para converter lista de IDs para lista de AppUser parciais
    List<AppUser> parseIdListToPartialAppUsers(dynamic idListData) {
      if (idListData is List) {
        return idListData
            .whereType<String>() // Garante que são Strings
            .where((id) => id.isNotEmpty)
            .map((id) => AppUser(uid: id, name: '', email: ''))
            .toList();
      }
      return [];
    }

    final ownerIdFromJson = json['ownerId'] as String? ?? '';

    return Race(
      id: json['id'] as String? ?? '', // ID é geralmente adicionado após leitura do doc
      title: json['title'] as String? ?? 'Sem Título',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      date: parseDateTime(json['date']),
      isFinished: json['isFinished'] as bool? ?? false, // Adicionado (lê do JSON, default false)
      participants: parseIdListToPartialAppUsers(json['participants']),
      pendingParticipants: parseIdListToPartialAppUsers(json['pendingParticipants']),
      startLatitude: (json['startLatitude'] as num?)?.toDouble() ?? 0.0,
      startLongitude: (json['startLongitude'] as num?)?.toDouble() ?? 0.0,
      endLatitude: (json['endLatitude'] as num?)?.toDouble() ?? 0.0,
      endLongitude: (json['endLongitude'] as num?)?.toDouble() ?? 0.0,
      startAddress: json['startAddress'] as String? ?? '',
      endAddress: json['endAddress'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      ownerId: ownerIdFromJson,
      owner: AppUser(uid: ownerIdFromJson, name: '', email: ''), // Owner "parcial"
      groupId: json['groupId'] as String?,
      isPrivate: json['isPrivate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'id' não é incluído, pois é o ID do documento Firestore
      'title': title,
      'distance': distance,
      'date': Timestamp.fromDate(date),
      'isFinished': isFinished, // Adicionado
      'participants': participants.map((user) => user.uid).toList(), // Salva lista de IDs
      'pendingParticipants': pendingParticipants.map((user) => user.uid).toList(), // Salva lista de IDs
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'startAddress': startAddress,
      'endAddress': endAddress,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'ownerId': ownerId, // Salva apenas o ID do owner
      'groupId': groupId,
      'isPrivate': isPrivate,
    };
  }

  // --- Operadores de Igualdade ---
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    // Compara IDs dos participantes/pendentes e ownerId, além dos outros campos
    return other is Race &&
        other.id == id &&
        other.title == title &&
        other.distance == distance &&
        other.date == date &&
        other.isFinished == isFinished && // Adicionado
        listEquals(other.participants.map((u) => u.uid).toList(), participants.map((u) => u.uid).toList()) &&
        listEquals(other.pendingParticipants.map((u) => u.uid).toList(), pendingParticipants.map((u) => u.uid).toList()) &&
        other.startLatitude == startLatitude &&
        other.startLongitude == startLongitude &&
        other.endLatitude == endLatitude &&
        other.endLongitude == endLongitude &&
        other.startAddress == startAddress &&
        other.endAddress == endAddress &&
        other.imageUrl == imageUrl &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.ownerId == ownerId &&
        other.groupId == groupId &&
        other.isPrivate == isPrivate;
  }

  @override
  int get hashCode {
    // Usa Object.hash para combinar os hashes dos campos relevantes
    return Object.hash(
      id,
      title,
      distance,
      date,
      isFinished, // Adicionado
      Object.hashAll(participants.map((u) => u.uid)), // Hash dos IDs
      Object.hashAll(pendingParticipants.map((u) => u.uid)), // Hash dos IDs
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
      startAddress,
      endAddress,
      imageUrl,
      createdAt,
      updatedAt,
      ownerId, // Hash do ownerId
      groupId,
      isPrivate,
    );
  }
}