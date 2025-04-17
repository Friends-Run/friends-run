import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseStorageService {
  // URL Completa da imagem placeholder no Firebase Storage
  static const String placeholderUrl = 'https://firebasestorage.googleapis.com/v0/b/friends-run-f4061.firebasestorage.app/o/profile_placeholder.png?alt=media&token=5943558c-0747-4250-a601-999080a820cb';

  // Retorna diretamente a URL da imagem placeholder.
  static String getPlaceholderImageUrl() {
    return placeholderUrl;
  }

  /// Faz upload da imagem de perfil e retorna a URL.
  /// Retorna a URL do placeholder se imageFile for null ou ocorrer erro no upload.
  static Future<String> uploadProfileImage(String uid, {File? imageFile}) async {
    debugPrint("--- FSS.uploadProfileImage: INÍCIO (UID: $uid, imageFile: ${imageFile?.path ?? 'null'}) ---");
    try {
      if (imageFile == null) {
        debugPrint("--- FSS.uploadProfileImage: imageFile é NULL, retornando placeholder. ---");
        return getPlaceholderImageUrl();
      }

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('profile.jpg');

      final metadata = SettableMetadata(contentType: 'image/jpeg');

      debugPrint("--- FSS.uploadProfileImage: TENTANDO ref.putFile para ${ref.fullPath} ---");
      await ref.putFile(imageFile, metadata);

      debugPrint("--- FSS.uploadProfileImage: putFile BEM SUCEDIDO. Obtendo URL... ---");
      final downloadUrl = await ref.getDownloadURL();

      debugPrint("--- FSS.uploadProfileImage: URL obtida: $downloadUrl ---");
      return downloadUrl;

    } catch (e) {
      debugPrint("--- FSS.uploadProfileImage: ERRO CAPTURADO: $e ---");
      final placeholder = getPlaceholderImageUrl();
      debugPrint("--- FSS.uploadProfileImage: Retornando placeholder ($placeholder) devido ao erro. ---");
      return placeholder;
    }
  }

  /// Obtém a URL da imagem de perfil do usuário ou o placeholder se não existir/erro.
  static Future<String> getProfileImageUrl(String uid) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('profile.jpg');
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return getPlaceholderImageUrl();
    }
  }

  /// Remove a imagem de perfil do usuário no Storage.
  /// Retorna a URL do placeholder após a tentativa de exclusão.
  static Future<String> deleteProfileImage(String uid) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('profile.jpg');
      debugPrint("Tentando deletar ${ref.fullPath}");
      await ref.delete();
      debugPrint("Imagem deletada com sucesso para $uid.");
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        debugPrint("Erro ao deletar a imagem ($uid): ${e.code} - ${e.message}");
      } else {
        debugPrint("Imagem para $uid não encontrada para deletar (já não existia?).");
      }
    } catch (e) {
      debugPrint("Erro inesperado ao deletar a imagem ($uid): $e");
    }
    return getPlaceholderImageUrl();
  }

  // ===============================
  // NOVOS MÉTODOS: Imagens de GRUPO
  // ===============================

  /// Faz upload da imagem do grupo e retorna a URL.
  static Future<String> uploadGroupImage(String groupId, File imageFile) async {
    debugPrint("--- FSS.uploadGroupImage: INÍCIO (GroupID: $groupId) ---");
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('groups')
          .child(groupId)
          .child('group_image.jpg');

      final metadata = SettableMetadata(contentType: 'image/jpeg');

      debugPrint("--- FSS.uploadGroupImage: TENTANDO putFile para ${ref.fullPath} ---");
      await ref.putFile(imageFile, metadata);

      debugPrint("--- FSS.uploadGroupImage: putFile BEM SUCEDIDO. Obtendo URL... ---");
      final downloadUrl = await ref.getDownloadURL();

      debugPrint("--- FSS.uploadGroupImage: URL obtida: $downloadUrl ---");
      return downloadUrl;

    } catch (e) {
      debugPrint("--- FSS.uploadGroupImage: ERRO CAPTURADO: $e ---");
      throw Exception("Falha no upload da imagem do grupo: $e");
    }
  }

  /// Deleta a imagem do grupo do Storage.
  static Future<void> deleteGroupImage(String groupId) async {
    debugPrint("--- FSS.deleteGroupImage: INÍCIO (GroupID: $groupId) ---");
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('groups')
          .child(groupId)
          .child('group_image.jpg');

      debugPrint("--- FSS.deleteGroupImage: Tentando deletar ${ref.fullPath} ---");
      await ref.delete();
      debugPrint("--- FSS.deleteGroupImage: Imagem do grupo $groupId deletada. ---");

    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        debugPrint("--- FSS.deleteGroupImage: ERRO Firebase ao deletar imagem ($groupId): ${e.code} ---");
        throw Exception("Erro ao deletar imagem do grupo: ${e.code}");
      } else {
        debugPrint("--- FSS.deleteGroupImage: Imagem para $groupId não encontrada (ok). ---");
      }
    } catch (e) {
      debugPrint("--- FSS.deleteGroupImage: ERRO inesperado ao deletar imagem ($groupId): $e ---");
      throw Exception("Erro inesperado ao deletar imagem do grupo.");
    }
  }
}
