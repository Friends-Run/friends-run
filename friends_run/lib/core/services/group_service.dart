import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friends_run/models/group/race_group.dart';
import 'package:friends_run/core/services/firebase_storage_service.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'groups';

  // --- Operações CRUD Básicas ---

  Future<RaceGroup?> createGroup({
    required String name,
    String? description,
    required String adminId,
    bool isPublic = true,
    File? groupImage,
  }) async {
    print("[GroupService] Tentando criar grupo '$name' por $adminId");
    try {
      final now = Timestamp.now();
      String? imageUrl;

      // Prepara dados iniciais
      Map<String, dynamic> groupData = {
        'name': name.trim(),
        'description': description?.trim(),
        'imageUrl': null,
        'adminId': adminId,
        'memberIds': [adminId],
        'pendingMemberIds': [],
        'isPublic': isPublic,
        'createdAt': now,
        'updatedAt': now,
      };

      // Cria documento no Firestore para obter ID
      final docRef = await _firestore.collection(_collectionName).add(groupData);
      print("[GroupService] Documento criado com ID: ${docRef.id}");

      // Faz upload da imagem se fornecida
      if (groupImage != null) {
        print("[GroupService] Fazendo upload da imagem para o grupo ${docRef.id}");
        try {
          imageUrl = await FirebaseStorageService.uploadGroupImage(docRef.id, groupImage);
          print("[GroupService] Upload concluído, URL: $imageUrl");
          await docRef.update({'imageUrl': imageUrl, 'updatedAt': Timestamp.now()});
          groupData['imageUrl'] = imageUrl;
        } catch (uploadError) {
          print("[GroupService] ERRO no upload da imagem: $uploadError");
          // Continua sem imagem
        }
      }

      return RaceGroup.fromMap(groupData, docRef.id);
    } catch (e) {
      print("[GroupService] Erro ao criar grupo: $e");
      throw Exception("Falha ao criar o grupo. Tente novamente.");
    }
  }

  Future<RaceGroup?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(groupId).get();
      if (doc.exists && doc.data() != null) {
        return RaceGroup.fromMap(doc.data()!, doc.id);
      }
      print("[GroupService] Grupo $groupId não encontrado.");
      return null;
    } catch (e) {
      print("[GroupService] Erro ao buscar grupo $groupId: $e");
      return null;
    }
  }

  // --- Busca de Grupos ---

  Stream<List<RaceGroup>> getUserGroupsStream(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    print("[GroupService] Obtendo stream de grupos para $userId");
    return _firestore
        .collection(_collectionName)
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print("[GroupService] Recebidos ${snapshot.docs.length} grupos para $userId");
          return snapshot.docs.map((doc) => RaceGroup.fromMap(doc.data(), doc.id)).toList();
        })
        .handleError((error) {
          print("[GroupService] Erro no stream getUserGroupsStream: $error");
          return <RaceGroup>[];
        });
  }

  Stream<List<RaceGroup>> getAllGroupsStream() {
    print("[GroupService] Obtendo stream de TODOS os grupos");
    return _firestore
        .collection(_collectionName)
        .orderBy('name', descending: false)
        .snapshots()
        .map((snapshot) {
          print("[GroupService] Recebidos ${snapshot.docs.length} grupos");
          return snapshot.docs.map((doc) => RaceGroup.fromMap(doc.data(), doc.id)).toList();
        })
        .handleError((error) {
          print("[GroupService] Erro no stream getAllGroupsStream: $error");
          return <RaceGroup>[];
        });
  }

  // --- Gerenciamento de Membros ---

  Future<void> joinPublicGroup(String groupId, String userId) async {
    print("[GroupService] Usuário $userId entrando DIRETAMENTE no grupo público $groupId");
    try {
      // Verificações importantes antes de atualizar:
      final groupDocRef = _firestore.collection(_collectionName).doc(groupId);
      final groupDoc = await groupDocRef.get();

      if (!groupDoc.exists || groupDoc.data() == null) {
        throw Exception("Grupo não encontrado.");
      }
      if (groupDoc.data()?['isPublic'] != true) {
         throw Exception("Este grupo não é público para entrada direta.");
      }
       final groupData = groupDoc.data()!;
      if (List<String>.from(groupData['memberIds'] ?? []).contains(userId) ||
          List<String>.from(groupData['pendingMemberIds'] ?? []).contains(userId)) {
        print("[GroupService] Usuário $userId já é membro ou pendente no grupo $groupId. Nenhuma ação necessária.");
        // Pode lançar exceção se quiser dar feedback específico na UI
        // throw Exception("Você já participa ou solicitou entrada neste grupo.");
        return; // Retorna sem erro se já está relacionado
      }

      // Adiciona diretamente à lista de membros
      await groupDocRef.update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.now(),
      });
       print("[GroupService] Usuário $userId adicionado aos membros do grupo $groupId.");

    } catch (e) {
      print("[GroupService] Erro ao entrar no grupo público $groupId: $e");
      // Relança a exceção formatada
      throw Exception("Falha ao entrar no grupo: ${e.toString().replaceFirst("Exception: ", "")}");
    }
  }

  Future<void> requestToJoinGroup(String groupId, String userId) async {
    try {
      print("[GroupService] Usuário $userId solicitando entrada no grupo $groupId");
      
      final groupDoc = await _firestore.collection(_collectionName).doc(groupId).get();
      if (!(groupDoc.exists && groupDoc.data()?['isPublic'] == true)) {
        throw Exception("Este grupo não é público ou não existe.");
      }

      final groupData = groupDoc.data()!;
      if (List<String>.from(groupData['memberIds'] ?? []).contains(userId) || 
          List<String>.from(groupData['pendingMemberIds'] ?? []).contains(userId)) {
        print("[GroupService] Usuário já é membro ou pendente");
        return;
      }

      await _firestore.collection(_collectionName).doc(groupId).update({
        'pendingMemberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.now(),
      });
      print("[GroupService] Solicitação enviada com sucesso");
    } catch (e) {
      print("[GroupService] Erro ao solicitar entrada: $e");
      throw Exception("Falha ao enviar solicitação: ${e.toString()}");
    }
  }

  Future<void> approveMember(String groupId, String userIdToApprove) async {
    try {
      print("[GroupService] Aprovando membro $userIdToApprove no grupo $groupId");
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection(_collectionName).doc(groupId);
        transaction.update(docRef, {
          'pendingMemberIds': FieldValue.arrayRemove([userIdToApprove]),
          'memberIds': FieldValue.arrayUnion([userIdToApprove]),
          'updatedAt': Timestamp.now(),
        });
      });
      print("[GroupService] Membro aprovado com sucesso");
    } catch (e) {
      print("[GroupService] Erro ao aprovar membro: $e");
      throw Exception("Falha ao aprovar membro: ${e.toString()}");
    }
  }

  Future<void> removeOrRejectMember(
    String groupId, 
    String userIdToRemove, 
    {required bool isPending}
  ) async {
    try {
      final action = isPending ? "rejeitar" : "remover";
      final fieldToRemove = isPending ? 'pendingMemberIds' : 'memberIds';
      print("[GroupService] Tentando $action membro $userIdToRemove");

      await _firestore.collection(_collectionName).doc(groupId).update({
        fieldToRemove: FieldValue.arrayRemove([userIdToRemove]),
        'updatedAt': Timestamp.now(),
      });
      print("[GroupService] Ação $action realizada com sucesso");
    } catch (e) {
      print("[GroupService] Erro membro: $e");
      throw Exception("Falha membro: ${e.toString()}");
    }
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      print("[GroupService] Usuário $userId saindo do grupo $groupId");
      await _firestore.collection(_collectionName).doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });
      print("[GroupService] Saída realizada com sucesso");
    } catch (e) {
      print("[GroupService] Erro ao sair do grupo: $e");
      throw Exception("Falha ao sair do grupo: ${e.toString()}");
    }
  }

  // --- Métodos de Atualização ---

  Future<bool> updateGroupDetails({
    required String groupId,
    String? newName,
    String? newDescription,
    bool? newIsPublic,
    File? newImage,
    bool removeImage = false,
  }) async {
    print("[GroupService] Atualizando grupo $groupId");
    try {
      Map<String, dynamic> dataToUpdate = {'updatedAt': Timestamp.now()};

      if (newName != null && newName.trim().isNotEmpty) {
        dataToUpdate['name'] = newName.trim();
      }
      if (newDescription != null) {
        dataToUpdate['description'] = newDescription.trim().isEmpty ? null : newDescription.trim();
      }
      if (newIsPublic != null) {
        dataToUpdate['isPublic'] = newIsPublic;
      }

      if (removeImage) {
        dataToUpdate['imageUrl'] = null;
        await FirebaseStorageService.deleteGroupImage(groupId);
      } else if (newImage != null) {
        final imageUrl = await FirebaseStorageService.uploadGroupImage(groupId, newImage);
        dataToUpdate['imageUrl'] = imageUrl;
      }

      if (dataToUpdate.length > 1) {
        await _firestore.collection(_collectionName).doc(groupId).update(dataToUpdate);
      }
      
      return true;
    } catch (e) {
      print("[GroupService] Erro ao atualizar grupo: $e");
      throw Exception("Falha ao atualizar grupo: ${e.toString()}");
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    print("[GroupService] Deletando grupo $groupId");
    try {
      // Remove imagem do storage se existir
      final group = await getGroupById(groupId);
      if (group?.imageUrl != null && group!.imageUrl!.isNotEmpty) {
        await FirebaseStorageService.deleteGroupImage(groupId);
      }

      // Deleta o documento do grupo
      await _firestore.collection(_collectionName).doc(groupId).delete();
      
      return true;
    } catch (e) {
      print("[GroupService] Erro ao deletar grupo: $e");
      throw Exception("Falha ao deletar grupo: ${e.toString()}");
    }
  }
}