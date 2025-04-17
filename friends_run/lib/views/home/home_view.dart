import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:friends_run/core/services/auth_service.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/models/user/app_user.dart';
import 'package:friends_run/views/auth/auth_main_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final Future<AppUser?> _userFuture;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<AppUser?> _loadUser() async {
    try {
      return await _authService.getCurrentUser();
    } catch (e) {
      debugPrint("Erro ao carregar usuário: $e");
      return null;
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthMainView()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer logout: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Meu Perfil",
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            tooltip: 'Sair',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<AppUser?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 16),
                  const Text(
                    "Erro ao carregar perfil",
                    style: TextStyle(color: AppColors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed:
                        () => setState(() {
                          _userFuture = _loadUser();
                        }),
                    child: const Text("Tentar novamente"),
                  ),
                ],
              ),
            );
          }

          final user = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Cabeçalho com foto e nome
                _buildProfileHeader(user),
                const SizedBox(height: 30),

                // Seção de informações
                _buildUserInfoSection(user),
                const SizedBox(height: 30),

                // Estatísticas (pode adicionar mais)
                _buildStatsSection(),
                const SizedBox(height: 30),

                // Configurações
                _buildSettingsSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppColors.primaryRed.withOpacity(0.2),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl:
                  user.profileImageUrl ?? 'assets/images/default_profile.png',
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget:
                  (context, url, error) => const Icon(Icons.person, size: 60),
              width: 110,
              height: 110,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (user.email.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              user.email,
              style: TextStyle(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfoSection(AppUser user) {
    return Card(
      color: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoTile(Icons.person, "Nome completo", user.name),
            if (user.email.isNotEmpty)
              _buildInfoTile(Icons.email, "E-mail", user.email),
            // Adicione mais campos do usuário conforme necessário
            // Exemplo:
            // if (user.phone != null) _buildInfoTile(Icons.phone, "Telefone", user.phone!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryRed, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      color: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Minhas Estatísticas",
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("12", "Corridas"),
                _buildStatItem("42 km", "Distância"),
                _buildStatItem("05:20", "Melhor tempo"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryRed,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.edit, color: AppColors.primaryRed),
          title: const Text(
            "Editar perfil",
            style: TextStyle(color: AppColors.white),
          ),
          onTap: () {
            // Navegar para tela de edição de perfil
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings, color: AppColors.primaryRed),
          title: const Text(
            "Configurações",
            style: TextStyle(color: AppColors.white),
          ),
          onTap: () {
            // Navegar para tela de configurações
          },
        ),
        ListTile(
          leading: const Icon(Icons.help, color: AppColors.primaryRed),
          title: const Text("Ajuda", style: TextStyle(color: AppColors.white)),
          onTap: () {
            // Navegar para tela de ajuda
          },
        ),
      ],
    );
  }
}