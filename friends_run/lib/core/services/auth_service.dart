import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friends_run/core/services/firebase_storage_service.dart';
import 'package:friends_run/models/user/app_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Cache simples para evitar buscas repetidas no Firestore pelo mesmo ID rapidamente.
  final Map<String, AppUser> _userCache = {};

  /// Registra um novo usuário com email, senha, nome e imagem de perfil opcional.
  Future<AppUser?> registerUser({
    required String name,
    required String email,
    required String password,
    File? profileImage,
  }) async {
    debugPrint("--- AuthService.registerUser START ---");
    try {
      // 1. Cria o usuário no Firebase Auth
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Garantia que user não é nulo após criação bem-sucedida
      final User user = userCred.user!;
      final String uid = user.uid;
      debugPrint("--- AuthService.registerUser: Usuário criado no Auth (UID: $uid) ---");

      // 2. Lida com a imagem de perfil
      String imageUrl;
      if (profileImage == null) {
        debugPrint("--- AuthService.registerUser: Nenhuma imagem fornecida, usando placeholder. ---");
        imageUrl = FirebaseStorageService.getPlaceholderImageUrl();

      } else {
        debugPrint("--- AuthService.registerUser: Imagem fornecida, chamando uploadProfileImage... ---");
        // Faz upload da imagem fornecida
        imageUrl = await FirebaseStorageService.uploadProfileImage(
          uid,
          imageFile: profileImage,
        );
        debugPrint("--- AuthService.registerUser: Upload retornou URL: $imageUrl ---");
         if (imageUrl == FirebaseStorageService.getPlaceholderImageUrl()) {
            debugPrint("--- AuthService.registerUser: ALERTA - Upload retornou URL do placeholder, usando-a mesmo assim. ---");
         }
      }

      // 3. Cria o objeto AppUser
      final appUser = AppUser(
        uid: uid,
        name: name,
        email: email, // Email validado pelo Firebase Auth
        profileImageUrl: imageUrl,
      );
      debugPrint("--- AuthService.registerUser: Objeto AppUser criado. ---");


      // 4. Salva no Firestore
      debugPrint("--- AuthService.registerUser: Salvando usuário no Firestore... ---");
      await _firestore.collection('users').doc(uid).set(appUser.toMap());

      // 5. Adiciona ao cache
      _userCache[uid] = appUser;
      debugPrint("--- AuthService.registerUser: Usuário salvo e cacheado. END (Sucesso) ---");

      return appUser;

    } on FirebaseAuthException catch (e) {
      debugPrint("--- AuthService.registerUser: ERRO FirebaseAuth: ${e.code} - ${e.message} ---");
      return null;
    } catch (e) {
      debugPrint("--- AuthService.registerUser: ERRO GERAL: $e ---");
      return null;
    }
  }

  /// Realiza login com email e senha.
  Future<AppUser?> loginUser({
    required String email,
    required String password,
  }) async {
    debugPrint("--- AuthService.loginUser START ---");
    try {
      // 1. Autentica no Firebase Auth
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User user = userCred.user!;
      final String uid = user.uid;
      debugPrint("--- AuthService.loginUser: Logado no Auth (UID: $uid). Buscando dados... ---");

      // 2. Busca os dados do AppUser (usa cache)
      final appUser = await getUserById(uid);

      if (appUser == null) {
        debugPrint("--- AuthService.loginUser: ERRO - Usuário autenticado ($uid) mas não encontrado no Firestore. Deslogando. ---");
        await logout(); // Desloga para evitar estado inconsistente
        return null;
      }

      debugPrint("--- AuthService.loginUser: AppUser encontrado. END (Sucesso) ---");
      return appUser;

    } on FirebaseAuthException catch (e) {
      debugPrint("--- AuthService.loginUser: ERRO FirebaseAuth: ${e.code} - ${e.message} ---");
      return null; 
    } catch (e) {
      debugPrint("--- AuthService.loginUser: ERRO GERAL: $e ---");
      return null;
    }
  }

  /// Realiza login ou registro usando conta Google.
  Future<AppUser?> signInWithGoogle() async {
    debugPrint("--- AuthService.signInWithGoogle START ---");
    try {
      // 1. Faz login com o Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        debugPrint("--- AuthService.signInWithGoogle: Login com Google cancelado pelo usuário. ---");
        return null;
      }
      debugPrint("--- AuthService.signInWithGoogle: Usuário Google obtido: ${googleUser.displayName} ---");


      // 2. Obtém credenciais do Google para o Firebase
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
       debugPrint("--- AuthService.signInWithGoogle: Credencial Google obtida. ---");

      // 3. Faz login no Firebase com a credencial Google
      final UserCredential userCred = await _auth.signInWithCredential(credential);
      final User user = userCred.user!;
      final String uid = user.uid;
      debugPrint("--- AuthService.signInWithGoogle: Logado no Firebase Auth (UID: $uid). Verificando Firestore... ---");

      // 4. Verifica se já existe no Firestore (ou usa getUserById com cache)
      AppUser? appUser = await getUserById(uid);

      if (appUser == null) {
        debugPrint("--- AuthService.signInWithGoogle: Novo usuário via Google. Criando doc Firestore... ---");
        final profilePic = user.photoURL ?? FirebaseStorageService.getPlaceholderImageUrl();

        appUser = AppUser(
          uid: uid,
          name: user.displayName ?? 'Usuário Google',
          email: user.email ?? '',
          profileImageUrl: profilePic,
        );

        await _firestore.collection('users').doc(uid).set(appUser.toMap());
        _userCache[uid] = appUser;
         debugPrint("--- AuthService.signInWithGoogle: Novo usuário salvo e cacheado. ---");
      } else {
         debugPrint("--- AuthService.signInWithGoogle: Usuário existente via Google: ${appUser.name} ---");
         bool needsUpdate = false;
         Map<String, dynamic> updates = {};
         if (appUser.name != user.displayName && user.displayName != null) {
            updates['name'] = user.displayName;
            needsUpdate = true;
         }
         final googlePhotoUrl = user.photoURL ?? FirebaseStorageService.getPlaceholderImageUrl();
         if (appUser.profileImageUrl != googlePhotoUrl) {
             updates['profileImageUrl'] = googlePhotoUrl;
             needsUpdate = true;
         }
         if (needsUpdate) {
             debugPrint("--- AuthService.signInWithGoogle: Atualizando dados do usuário existente com dados do Google: $updates ---");
             await _firestore.collection('users').doc(uid).update(updates);
             _userCache[uid] = appUser.copyWith(
                 name: updates['name'] ?? appUser.name,
                 profileImageUrl: updates['profileImageUrl'] ?? appUser.profileImageUrl,
             );
             appUser = _userCache[uid];
         }
      }

      debugPrint("--- AuthService.signInWithGoogle: END (Sucesso) ---");
      return appUser;

    } on FirebaseAuthException catch (e) {
       debugPrint("--- AuthService.signInWithGoogle: ERRO FirebaseAuth: ${e.code} - ${e.message} ---");
       return null;
    } catch (e) {
      debugPrint('--- AuthService.signInWithGoogle: ERRO GERAL: $e ---');
      try { await GoogleSignIn().signOut(); } catch (_) {}
      return null;
    }
  }

  /// Realiza logout do Firebase Auth e Google Sign In.
  Future<void> logout() async {
    debugPrint("--- AuthService.logout START ---");
    try {
      _userCache.clear();
      debugPrint("--- AuthService.logout: Cache limpo. ---");

      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        debugPrint("--- AuthService.logout: Google Signed Out ---");
      } else {
         debugPrint("--- AuthService.logout: Não estava logado com Google. ---");
      }
      await _auth.signOut();
      debugPrint("--- AuthService.logout: Firebase Auth Signed Out ---");
      debugPrint("--- AuthService.logout END ---");
    } catch (e) {
      debugPrint('--- AuthService.logout: ERRO (não relançado): $e ---');
    }
  }

  /// Obtém o AppUser atualmente logado, buscando no cache ou Firestore.
  Future<AppUser?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      if (_userCache.containsKey(user.uid)) {
         debugPrint("Usuário atual encontrado no cache: ${user.uid}");
         return _userCache[user.uid];
      }

      debugPrint("Buscando usuário atual (via getUserById): ${user.uid}");
      final appUser = await getUserById(user.uid); // Reutiliza a busca e o cache
      return appUser;

    } catch (e) {
      debugPrint('Erro silencioso ao obter usuário atual: $e');
      return null;
    }
  }

  /// Busca um usuário específico no Firestore pelo seu UID, usando cache.
  Future<AppUser?> getUserById(String userId) async {
    if (_userCache.containsKey(userId)) {
       debugPrint("Usuário encontrado no cache: $userId");
       return _userCache[userId];
    }

    debugPrint("Buscando usuário no Firestore: $userId");
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final appUser = AppUser.fromMap(doc.data()!);
        _userCache[userId] = appUser;
         debugPrint("Usuário $userId encontrado no Firestore e adicionado ao cache.");
        return appUser;
      } else {
        debugPrint("Usuário com ID $userId não encontrado no Firestore.");
        return null;
      }
    } catch (e) {
      debugPrint('Erro ao buscar usuário por ID ($userId): $e');
      return null;
    }
  }

  /// Atualiza os dados do perfil do usuário no Firebase Auth e Firestore.
  /// Retorna `true` em sucesso, `false` ou lança exceção em erro.
  Future<bool> updateUserProfile({
    required String uid,
    required String name,
    required String email,
    File? newProfileImage,
  }) async {
     debugPrint("--- AuthService.updateUserProfile START (UID: $uid) ---");
    final user = _auth.currentUser;
    // Validação crucial
    if (user == null || user.uid != uid) {
       debugPrint("--- AuthService.updateUserProfile: ERRO - Usuário inválido ou UID não corresponde. ---");
      throw Exception("Usuário não autenticado ou UID não corresponde para atualização.");
    }

    try {
      final Map<String, dynamic> updates = {};
      bool needsFirestoreUpdate = false;
      AppUser? currentUserFromCache = _userCache[uid];

      // 1. Atualizar Nome (se diferente do cache ou se cache vazio)
      if (currentUserFromCache == null || name != currentUserFromCache.name) {
         debugPrint("--- AuthService.updateUserProfile: Preparando atualização de nome para '$name' ---");
         updates['name'] = name;
         needsFirestoreUpdate = true;
      }

      // 2. Atualizar Email (se diferente do Auth atual)
      final String currentAuthEmail = user.email ?? "";
      final String trimmedEmail = email.trim();
      if (trimmedEmail.isNotEmpty && trimmedEmail.toLowerCase() != currentAuthEmail.toLowerCase()) {
         debugPrint("--- AuthService.updateUserProfile: Tentando atualizar email Auth de '$currentAuthEmail' para '$trimmedEmail' ---");
        try {
          await user.verifyBeforeUpdateEmail(trimmedEmail);
           debugPrint("--- AuthService.updateUserProfile: Verificação de email enviada/atualização Auth iniciada. ---");
          updates['email'] = trimmedEmail;
          needsFirestoreUpdate = true;
        } on FirebaseAuthException catch (e) {
           debugPrint("--- AuthService.updateUserProfile: ERRO FirebaseAuth ao atualizar email: ${e.code} ---");
           if (e.code == 'requires-recent-login') {
            throw Exception('Para alterar seu email, por favor, faça logout e login novamente.');
          } else if (e.code == 'email-already-in-use') {
            throw Exception('Este email já está sendo utilizado por outra conta.');
          } else {
            throw Exception('Ocorreu um erro ao atualizar seu email (${e.code}).');
          }
        }
      } else {
         debugPrint("--- AuthService.updateUserProfile: Email não modificado ('$trimmedEmail'). ---");
      }

      // 3. Atualizar Foto de Perfil (se nova imagem fornecida)
      String? finalImageUrlForUpdate;
      if (newProfileImage != null) {
         debugPrint("--- AuthService.updateUserProfile: Nova imagem fornecida. Fazendo upload... ---");
        try {
            finalImageUrlForUpdate = await FirebaseStorageService.uploadProfileImage(
              uid,
              imageFile: newProfileImage,
            );
            if (finalImageUrlForUpdate == FirebaseStorageService.getPlaceholderImageUrl()) {
               debugPrint("--- AuthService.updateUserProfile: ERRO - Upload da imagem falhou (serviço retornou placeholder). ---");
               throw Exception('Falha ao salvar a nova foto de perfil.');
            }
             debugPrint("--- AuthService.updateUserProfile: Upload OK. URL: $finalImageUrlForUpdate ---");
            updates['profileImageUrl'] = finalImageUrlForUpdate;
            needsFirestoreUpdate = true;
        } catch(e) {
            debugPrint("--- AuthService.updateUserProfile: ERRO durante upload: $e ---");
             throw Exception('Erro ao fazer upload da imagem: ${e.toString()}');
        }
      } else {
         debugPrint("--- AuthService.updateUserProfile: Nenhuma nova imagem fornecida. ---");
      }

      // 4. Atualizar dados no Firestore (se houver alterações)
      if (needsFirestoreUpdate && updates.isNotEmpty) {
         debugPrint("--- AuthService.updateUserProfile: Atualizando Firestore com: $updates ---");
        await _firestore.collection('users').doc(uid).update(updates);
        debugPrint("--- AuthService.updateUserProfile: Firestore atualizado. ---");

         if (_userCache.containsKey(uid)) {
             _userCache[uid] = _userCache[uid]!.copyWith(
                 name: updates['name'] ?? _userCache[uid]!.name,
                 email: updates['email'] ?? _userCache[uid]!.email,
                 profileImageUrl: updates['profileImageUrl'] ?? _userCache[uid]!.profileImageUrl,
             );
              debugPrint("--- AuthService.updateUserProfile: Cache atualizado. ---");
         }

      } else {
         debugPrint("--- AuthService.updateUserProfile: Nenhuma atualização necessária no Firestore. ---");
      }

      debugPrint("--- AuthService.updateUserProfile: END (Sucesso) ---");
      return true;

    } on FirebaseException catch (e) {
       debugPrint("--- AuthService.updateUserProfile: ERRO FirebaseException: ${e.code} - ${e.message} ---");
       if (e.message == null || !(e.message!.contains('logout e login') || e.message!.contains('email já está sendo utilizado'))) {
           throw Exception('Erro ao salvar (${e.code}). Verifique sua conexão.');
       } else {
          rethrow;
       }
    } catch (e) {
       debugPrint("--- AuthService.updateUserProfile: ERRO GERAL: $e ---");
       if (e is Exception) {
         rethrow;
       }
       throw Exception('Ocorreu um erro inesperado ao salvar seu perfil.');
    }
  }

  // --- FUNÇÕES AUXILIARES ---
  /// Retorna o stream do usuário autenticado no Firebase.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Verifica se o usuário atual fez login usando Google.
  Future<bool> isGoogleSignedIn() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final providerData = user.providerData;
    return providerData.any((info) => info.providerId == GoogleAuthProvider.PROVIDER_ID);
  }

}