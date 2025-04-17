import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/views/auth/auth_main_view.dart';
import 'package:friends_run/views/group/groups_list_view.dart';
import 'package:friends_run/views/profile/my_races_view.dart';
import 'package:friends_run/views/profile/profile_view.dart';

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authServiceProvider).logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthMainView()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer logout: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          userAsync.when(
            data:
                (user) => UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.8),
                  ),
                  accountName: Text(
                    user?.name ?? 'Carregando...',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  accountEmail: Text(user?.email ?? ''),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: AppColors.white,
                    child:
                        user?.profileImageUrl != null &&
                                user!.profileImageUrl!.isNotEmpty
                            ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user.profileImageUrl!,
                                placeholder:
                                    (context, url) =>
                                        const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                errorWidget:
                                    (context, url, error) => const Icon(
                                      Icons.person,
                                      color: AppColors.primaryRed,
                                      size: 40,
                                    ),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                            : const Icon(
                              Icons.person,
                              color: AppColors.primaryRed,
                              size: 40,
                            ),
                  ),
                ),
            loading:
                () => DrawerHeader(
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.8),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.white),
                  ),
                ),
            error:
                (err, stack) => DrawerHeader(
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.8),
                  ),
                  child: const Center(
                    child: Text(
                      "Erro ao carregar usuário",
                      style: TextStyle(color: AppColors.white),
                    ),
                  ),
                ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'Meu Perfil',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileView()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.flag,
                  title: 'Minhas Corridas',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyRacesView()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.group,
                  title: 'Meus Grupos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GroupsListView(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.leaderboard,
                  title: 'Estatísticas',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/stats');
                  },
                ),
                const Divider(color: AppColors.white),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Sair',
                  onTap: () => _logout(context, ref),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Friends Run v1.0',
              style: TextStyle(color: AppColors.white.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.white),
      title: Text(title, style: const TextStyle(color: AppColors.white)),
      onTap: onTap,
    );
  }
}
