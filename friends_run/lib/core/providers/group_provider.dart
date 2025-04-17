// core/providers/group_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/services/group_service.dart';
import 'package:friends_run/models/group/race_group.dart';
import 'package:friends_run/core/providers/auth_provider.dart'; // Para currentUserProvider

// Provider para o GroupService
final groupServiceProvider = Provider<GroupService>((ref) => GroupService());

// Provider para obter a lista de grupos do usuário atual
final userGroupsProvider = StreamProvider.autoDispose<List<RaceGroup>>((ref) {
  final userAsync = ref.watch(currentUserProvider); // Observa o usuário logado
  final groupService = ref.watch(groupServiceProvider);

  final user = userAsync.asData?.value;
  if (user != null) {
    // Se tem usuário, retorna o stream de grupos dele
    return groupService.getUserGroupsStream(user.uid);
  } else {
    // Se não tem usuário logado, retorna um stream vazio
    return Stream.value(<RaceGroup>[]);
  }
});

// Provider para buscar os detalhes de um grupo específico por ID
// Provider para buscar os detalhes de um grupo específico por ID (usando FutureProvider)
final groupDetailsProvider = FutureProvider.autoDispose.family<
  RaceGroup?,
  String
>((ref, groupId) async {
  // Se groupId for vazio, retorna null imediatamente
  if (groupId.isEmpty) {
    print("[Provider] groupDetailsProvider: groupId está vazio.");
    return null;
  }

  print(
    "[Provider] groupDetailsProvider: Buscando detalhes para groupId: $groupId",
  );
  // Obtém a instância do serviço
  final groupService = ref.watch(groupServiceProvider);
  try {
    // Chama o método getGroupById do serviço
    final group = await groupService.getGroupById(groupId);
    if (group == null) {
      print(
        "[Provider] groupDetailsProvider: Grupo não encontrado no serviço para ID: $groupId",
      );
    } else {
      print(
        "[Provider] groupDetailsProvider: Grupo '${group.name}' encontrado.",
      );
    }
    return group; // Retorna o grupo encontrado ou null
  } catch (e) {
    print("[Provider] groupDetailsProvider: Erro ao buscar grupo $groupId: $e");
    // Lança o erro para ser tratado pelo .when() na UI
    throw Exception("Erro ao carregar detalhes do grupo: ${e.toString()}");
    // Ou retorne null se preferir tratar erro como dados nulos:
    // return null;
  }
});

final allGroupsProvider = StreamProvider.autoDispose<List<RaceGroup>>((ref) {
  final groupService = ref.watch(groupServiceProvider);
  return groupService.getAllGroupsStream();
});

// Opcional: Provider de Estado de Ação para Grupos (similar ao RaceActionState)
// final groupActionNotifierProvider = StateNotifierProvider...
