import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/service/auth_service.dart';
import 'package:friends_run/models/user/app_user.dart';     // Necessário para os tipos de retorno
import 'package:meta/meta.dart';

// Estado da autenticação para AÇÕES (Login, Registro, Logout)
@immutable // Boa prática para estados Riverpod
class AuthActionState {
  final bool isLoading;
  final String? error;

  const AuthActionState._({this.isLoading = false, this.error});

  factory AuthActionState.initial() => const AuthActionState._();

  AuthActionState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false, // Flag para limpar o erro explicitamente
  }) {
    return AuthActionState._(
      isLoading: isLoading ?? this.isLoading,
      // Se clearError for true, define erro como null, senão usa o novo erro ou mantém o antigo
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthActionState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => isLoading.hashCode ^ error.hashCode;
}

// Notifier para gerenciar o estado das AÇÕES de autenticação
class AuthNotifier extends StateNotifier<AuthActionState> {
  final AuthService _authService;

  // Recebe o AuthService via injeção de dependência
  AuthNotifier(this._authService) : super(AuthActionState.initial());

  // --- Métodos de Ação ---
  // (Estes métodos executam a ação e atualizam o AuthActionState com isLoading/error)

  Future<AppUser?> registerUser({
    required String name,
    required String email,
    required String password,
    File? profileImage,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true); // Inicia loading, limpa erro anterior
    try {
      // Chama o serviço. O serviço agora lança exceções em caso de erro.
      final user = await _authService.registerUser(
        name: name,
        email: email,
        password: password,
        profileImage: profileImage,
      );
      state = state.copyWith(isLoading: false); // Finaliza loading
      // Retorna o usuário se o registro for bem-sucedido (pode ser útil para navegação pós-registro)
      return user;
    } catch (e) {
      // Captura a exceção lançada pelo serviço
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst("Exception: ", "")); // Finaliza loading, define erro
      return null; // Indica falha
    }
  }

  Future<AppUser?> loginUser({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.loginUser(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return user;
    } catch (e) {
       // Captura a exceção lançada pelo serviço (que pode ser específica como 'Email ou senha inválidos.')
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst("Exception: ", ""));
      return null; // Indica falha
    }
  }

  Future<AppUser?> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.signInWithGoogle();
      state = state.copyWith(isLoading: false);
      return user; // Pode ser null se o usuário cancelou
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst("Exception: ", ""));
      return null;
    }
  }

  Future<bool> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.logout();
      state = state.copyWith(isLoading: false);
      return true; // Sucesso
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst("Exception: ", ""));
      return false; // Falha
    }
  }

  // Método para limpar o erro manualmente, se necessário (ex: ao mostrar um diálogo)
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

// --- Service Provider ---
// Provider singleton para a instância do AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  // Poderia inicializar dependências aqui se AuthService precisasse
  return AuthService();
});

// --- Action Notifier Provider ---
// Provider para o AuthNotifier (gerencia AuthActionState para ações)
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthActionState>((ref) {
  // Assiste (watch) o authServiceProvider para obter a instância do serviço
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// --- Data Providers (Estado da Autenticação e Dados do Usuário) ---

// Provider que expõe o Stream de mudanças de estado de autenticação do Firebase Auth
// Emite o objeto `User?` bruto do Firebase.
final authStateChangesProvider = StreamProvider.autoDispose<User?>((ref) {
  // Ouve diretamente o stream do FirebaseAuth
  // autoDispose garante que o listener seja removido quando não for mais usado
  return ref.watch(authServiceProvider).authStateChanges;
  // Alternativa: FirebaseAuth.instance.authStateChanges();
});

// Provider que expõe o AppUser logado atualmente (ou null), com atualizações em tempo real do Firestore
// Depende do authStateChangesProvider para saber QUEM está logado.
final currentUserProvider = StreamProvider.autoDispose<AppUser?>((ref) {
  // Ouve o stream de mudanças do Firebase Auth (User?)
  final authStateStream = ref.watch(authStateChangesProvider);

  // Transforma o Stream<User?> em Stream<AppUser?>
  return authStateStream.when(
    data: (firebaseUser) {
      // Se há um usuário Firebase logado...
      if (firebaseUser != null) {
        try {
          // Escuta por mudanças NO DOCUMENTO do usuário no Firestore
          return FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .snapshots() // Usa snapshots() para ouvir mudanças no perfil em tempo real
              .map((docSnapshot) {
                // Quando o documento muda (ou na primeira leitura)...
                if (docSnapshot.exists && docSnapshot.data() != null) {
                  // Converte os dados do Firestore para AppUser
                  return AppUser.fromMap(docSnapshot.data()!);
                } else {
                  // Documento não existe no Firestore (caso raro, pode indicar erro no registro)
                  print("AVISO: Usuário ${firebaseUser.uid} logado no Firebase Auth, mas documento não encontrado/vazio no Firestore.");
                  // Pode ser que o registro ainda não completou a escrita no Firestore.
                  // Ou o documento foi deletado manualmente.
                  // Retornar null indica que não temos os dados do AppUser.
                  return null;
                }
              })
              .handleError((error, stackTrace) { // Trata erros do stream do Firestore
                 print("Erro no stream do Firestore para AppUser (${firebaseUser.uid}): $error");
                 // print(stackTrace); // Descomente para ver o stacktrace
                 return null; // Emite null em caso de erro neste stream específico
              });
        } catch (e) {
           print("Erro ao configurar stream do Firestore para AppUser (${firebaseUser.uid}): $e");
           // print(stackTrace);
           return Stream.value(null); // Retorna stream com null em caso de erro inicial na configuração
        }
      } else {
        // Se não há usuário Firebase logado, emite null.
        return Stream.value(null);
      }
    },
    // Se o stream do Firebase Auth estiver carregando (pouco provável de acontecer por muito tempo)
    loading: () => Stream.value(null), // Emite null temporariamente
    // Se houver erro no stream do Firebase Auth (ex: problema de inicialização do Firebase)
    error: (err, stack) {
       print("Erro crítico no authStateChangesProvider: $err");
       // print(stack);
       return Stream.value(null); // Emite null em caso de erro no stream base
    },
  );
});


// --- Provider para buscar um AppUser específico por ID ---
// (Combinação dos dois snippets)
/// Busca um [AppUser] específico pelo seu [userId].
/// Retorna `null` se o ID for vazio, o usuário não for encontrado ou ocorrer um erro.
/// Usa `.autoDispose` para limpar o cache do provider quando não estiver mais em uso.
/// Usa `.family` para poder passar o `userId` como parâmetro.
final userProvider = FutureProvider.autoDispose.family<AppUser?, String>((ref, userId) async {
  // Verifica se o ID é válido antes de prosseguir
  if (userId.isEmpty) {
    print("userProvider: Tentativa de busca com userId vazio.");
    return null;
  }

  // Obtém a instância do AuthService
  final authService = ref.watch(authServiceProvider);

  // Chama o método do serviço que busca o usuário (e pode usar cache interno)
  // O FutureProvider lida com o estado de loading/error automaticamente
  try {
    return await authService.getUserById(userId);
  } catch (e) {
     print("Erro capturado pelo userProvider ao chamar authService.getUserById para $userId: $e");
     // Embora getUserById já trate erros e retorne null, podemos logar aqui também.
     // O FutureProvider colocará o estado em 'error'.
     return null; // Ou rethrow e; para propagar o erro ao .when do widget
  }
});