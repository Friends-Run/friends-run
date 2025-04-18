// core/providers/group_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/services/group_service.dart';
import 'package:friends_run/models/group/race_group.dart';
import 'package:friends_run/core/providers/auth_provider.dart';

// Provider para o GroupService
final groupServiceProvider = Provider<GroupService>((ref) => GroupService());

// Provider para obter a lista de grupos do usuário atual
final userGroupsProvider = StreamProvider.autoDispose<List<RaceGroup>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final groupService = ref.watch(groupServiceProvider);

  final user = userAsync.asData?.value;
  if (user != null) {
    return groupService.getUserGroupsStream(user.uid);
  } else {
    return Stream.value(<RaceGroup>[]);
  }
});

// Provider para buscar os detalhes de um grupo específico por ID
final groupDetailsProvider = FutureProvider.autoDispose.family<RaceGroup?, String>((ref, groupId) async {
  if (groupId.isEmpty) {
    print("[Provider] groupDetailsProvider: groupId está vazio.");
    return null;
  }

  print("[Provider] groupDetailsProvider: Buscando detalhes para groupId: $groupId");
  final groupService = ref.watch(groupServiceProvider);
  try {
    final group = await groupService.getGroupById(groupId);
    if (group == null) {
      print("[Provider] groupDetailsProvider: Grupo não encontrado no serviço para ID: $groupId");
    } else {
      print("[Provider] groupDetailsProvider: Grupo '${group.name}' encontrado.");
    }
    return group;
  } catch (e) {
    print("[Provider] groupDetailsProvider: Erro ao buscar grupo $groupId: $e");
    throw Exception("Erro ao carregar detalhes do grupo: ${e.toString()}");
  }
});

// Provider para todos os grupos
final allGroupsProvider = StreamProvider.autoDispose<List<RaceGroup>>((ref) {
  final groupService = ref.watch(groupServiceProvider);
  return groupService.getAllGroupsStream();
});

// --- NOVOS PROVIDERS ADICIONADOS ---

// Provider para o termo de busca
final groupSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// Provider para a lista de grupos "Explorar" (Todos os grupos - Grupos do usuário)
final exploreGroupsProvider = Provider.autoDispose<AsyncValue<List<RaceGroup>>>((ref) {
  final allGroupsAsync = ref.watch(allGroupsProvider);
  final userGroupsAsync = ref.watch(userGroupsProvider);
  final currentUser = ref.watch(currentUserProvider).asData?.value;

  // Combina os estados dos dois providers
  return allGroupsAsync.when(
    data: (allGroups) {
      return userGroupsAsync.when(
        data: (userGroups) {
          if (currentUser == null) {
            return AsyncValue.data(allGroups);
          }
          // Filtra para remover os grupos dos quais o usuário já participa
          final userGroupIds = userGroups.map((g) => g.id).toSet();
          final exploreList = allGroups.where((group) => !userGroupIds.contains(group.id)).toList();
          return AsyncValue.data(exploreList);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// Provider para lista "Explorar" FILTRADA pela busca
final filteredExploreGroupsProvider = Provider.autoDispose<AsyncValue<List<RaceGroup>>>((ref) {
  final searchQuery = ref.watch(groupSearchQueryProvider).toLowerCase().trim();
  final exploreGroupsAsync = ref.watch(exploreGroupsProvider);

  return exploreGroupsAsync.whenData((groups) {
    if (searchQuery.isEmpty) {
      return groups;
    }
    return groups.where((group) => group.name.toLowerCase().contains(searchQuery)).toList();
  });
});

// Provider para lista "Meus Grupos" FILTRADA pela busca
final filteredUserGroupsProvider = Provider.autoDispose<AsyncValue<List<RaceGroup>>>((ref) {
  final searchQuery = ref.watch(groupSearchQueryProvider).toLowerCase().trim();
  final userGroupsAsync = ref.watch(userGroupsProvider);

  return userGroupsAsync.whenData((groups) {
    if (searchQuery.isEmpty) {
      return groups;
    }
    return groups.where((group) => group.name.toLowerCase().contains(searchQuery)).toList();
  });
});