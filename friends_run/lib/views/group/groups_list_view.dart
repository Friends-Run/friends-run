import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/providers/group_provider.dart';
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/utils/colors.dart';
// Widgets
import 'package:friends_run/views/group/widgets/group_list.dart';
import 'package:friends_run/views/group/widgets/empty_groups_message.dart';
import 'package:friends_run/views/group/widgets/groups_error.dart';
import 'package:friends_run/views/group/create_group_view.dart';
import 'package:friends_run/views/home/widgets/home_drawer.dart'; // Certifique-se de ter esse import

class GroupsListView extends ConsumerStatefulWidget {
  const GroupsListView({super.key});

  @override
  ConsumerState<GroupsListView> createState() => _GroupsListViewState();
}

class _GroupsListViewState extends ConsumerState<GroupsListView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _searchController.addListener(() {
      ref.read(groupSearchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildTabContent(WidgetRef ref, bool isExploreTab) {
    final groupsAsync = isExploreTab
        ? ref.watch(filteredExploreGroupsProvider)
        : ref.watch(filteredUserGroupsProvider);

    final String emptyMessage = isExploreTab
        ? "Nenhum grupo encontrado com a busca."
        : "Você não participa de nenhum grupo com este nome.";
    final String genericEmptyMessage = isExploreTab
        ? "Nenhum grupo para explorar no momento."
        : "";

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          if (ref.read(groupSearchQueryProvider).isNotEmpty) {
            return Center(
              child: Text(
                emptyMessage,
                style: const TextStyle(color: AppColors.greyLight, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }
          return isExploreTab
              ? Center(
                  child: Text(
                    genericEmptyMessage,
                    style: const TextStyle(color: AppColors.greyLight, fontSize: 16),
                  ),
                )
              : const EmptyGroupsMessage();
        } else {
          return GroupList(groups: groups, showAllGroups: isExploreTab);
        }
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
      error: (error, stack) {
        return GroupsErrorWidget(
          error: error,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RaceActionState>(raceNotifierProvider, (_, next) {});

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: const HomeDrawer(),
        appBar: AppBar(
          title: const Text("Grupos", style: TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.background,
          iconTheme: const IconThemeData(color: AppColors.white),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.white),
              tooltip: "Atualizar Lista",
              onPressed: () {
                ref.invalidate(allGroupsProvider);
                ref.invalidate(userGroupsProvider);
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight + 50),
            child: Container(
              color: AppColors.background,
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: "Buscar por nome...",
                        hintStyle:
                            TextStyle(color: AppColors.greyLight.withOpacity(0.7)),
                        prefixIcon: const Icon(Icons.search, color: AppColors.greyLight),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppColors.greyLight),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.underBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10.0),
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primaryRed,
                    labelColor: AppColors.primaryRed,
                    unselectedLabelColor: AppColors.greyLight,
                    indicatorWeight: 3.0,
                    tabs: const [
                      Tab(text: "EXPLORAR"),
                      Tab(text: "MEUS GRUPOS"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent(ref, true),
            _buildTabContent(ref, false),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text("Criar Grupo"),
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupView()),
            );
          },
        ),
      ),
    );
  }
}
