import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para listEquals em ==

// @immutable // Boa prática
class RaceGroup {
  final String id; // ID do documento Firestore
  final String name;
  final String? description;
  final String? imageUrl; // URL da imagem do grupo (opcional)
  final String adminId; // UID do criador/admin principal
  final List<String> memberIds; // Lista de UIDs dos membros (inclui admin)
  final List<String> pendingMemberIds; // Solicitações pendentes (se grupo for público)
  final bool isPublic; // Se true, qualquer um pode SOLICITAR entrada. Se false, apenas convite (a implementar).
  final Timestamp createdAt;

  const RaceGroup({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.adminId,
    required this.memberIds,
    required this.pendingMemberIds,
    required this.isPublic,
    required this.createdAt,
  });

  // Construtor fromJson (ou fromFirestore)
  factory RaceGroup.fromMap(Map<String, dynamic> map, String documentId) {
    return RaceGroup(
      id: documentId,
      name: map['name'] ?? 'Grupo Sem Nome',
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String?,
      adminId: map['adminId'] ?? '',
      // Garante que as listas sejam de Strings
      memberIds: List<String>.from(map['memberIds'] ?? []),
      pendingMemberIds: List<String>.from(map['pendingMemberIds'] ?? []),
      isPublic: map['isPublic'] ?? true, // Padrão é público para solicitar
      createdAt: map['createdAt'] ?? Timestamp.now(), // Fallback
    );
  }

  // Método toJson (ou toMap)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'adminId': adminId,
      'memberIds': memberIds,
      'pendingMemberIds': pendingMemberIds,
      'isPublic': isPublic,
      'createdAt': createdAt,
      // O ID não é salvo dentro do documento
    };
  }

   // copyWith para facilitar atualizações imutáveis
   RaceGroup copyWith({
     String? id, String? name, String? description, String? imageUrl,
     String? adminId, List<String>? memberIds, List<String>? pendingMemberIds,
     bool? isPublic, Timestamp? createdAt,
   }) {
     return RaceGroup(
       id: id ?? this.id, name: name ?? this.name,
       description: description ?? this.description, imageUrl: imageUrl ?? this.imageUrl,
       adminId: adminId ?? this.adminId, memberIds: memberIds ?? this.memberIds,
       pendingMemberIds: pendingMemberIds ?? this.pendingMemberIds,
       isPublic: isPublic ?? this.isPublic, createdAt: createdAt ?? this.createdAt,
     );
   }

    // Sobrescreve == e hashCode para comparações corretas
   @override
   bool operator ==(Object other) {
     if (identical(this, other)) return true;
     return other is RaceGroup && other.id == id && other.name == name &&
            other.description == description && other.imageUrl == imageUrl &&
            other.adminId == adminId && listEquals(other.memberIds, memberIds) &&
            listEquals(other.pendingMemberIds, pendingMemberIds) &&
            other.isPublic == isPublic && other.createdAt == createdAt;
   }

   @override
   int get hashCode => Object.hash(id, name, description, imageUrl, adminId,
        Object.hashAll(memberIds), Object.hashAll(pendingMemberIds), isPublic, createdAt);
}