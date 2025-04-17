import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Remova a importação direta do AuthService se não for mais usada aqui
// import 'package:friends_run/core/services/auth_service.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/core/utils/validationsUtils.dart';
import 'package:friends_run/views/home/home_view.dart';
// Importe o provider refatorado
import 'package:friends_run/core/providers/auth_provider.dart';
import 'auth_widgets.dart'; // Mantenha seus widgets de UI

// Já é ConsumerStatefulWidget, ótimo.
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // Limpe os controllers
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Método de login agora usa o notifier
  void _login() async {
    // Fecha o teclado
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Chama o método de login no notifier
      // ref.read para ações fora do build
      final loggedInUser = await ref
          .read(authNotifierProvider.notifier)
          .loginUser(email: email, password: password);

      // Navega se o login for bem-sucedido (o notifier cuidou do isLoading)
      // A verificação do usuário logado agora é feita pelo currentUserProvider na HomeView ou onde for necessário
      if (loggedInUser != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeView()),
        );
      }
      // O tratamento de erro agora é feito pelo ref.listen abaixo
    }
  }

  // Método para login com Google agora usa o notifier
  void _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    final loggedInUser =
        await ref.read(authNotifierProvider.notifier).signInWithGoogle();

    if (loggedInUser != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    }
    // O tratamento de erro é feito pelo ref.listen
  }

  @override
  Widget build(BuildContext context) {
    // Ouve o ESTADO DE AÇÃO (loading/error) do notifier
    final actionState = ref.watch(authNotifierProvider);

    // Ouve as MUDANÇAS de estado para mostrar erros em Snackbars
    ref.listen<AuthActionState>(authNotifierProvider, (_, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.redAccent,
          ),
        );
        // Limpa o erro para não mostrar de novo em rebuilds
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text("Login", style: TextStyle(color: AppColors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            // Apenas volta se não estiver carregando uma ação
            if (!actionState.isLoading) {
               Navigator.pop(context);
            }
          },
        ),
      ),
      // Ignora toques enquanto estiver carregando
      body: IgnorePointer(
        ignoring: actionState.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                AuthTextField(
                  controller: _emailController,
                  label: "Email",
                  validator: ValidationUtils.validateEmail,// Desabilita durante loading
                ),
                const SizedBox(height: 15),

                AuthTextField(
                  controller: _passwordController,
                  label: "Senha",
                  isPassword: true,
                  validator: ValidationUtils.validatePassword, // Desabilita durante loading
                ),
                const SizedBox(height: 30),

                // Mostra loading ou botão
                actionState.isLoading
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : PrimaryButton(
                        text: "Entrar",
                        onPressed: _login, // Chama o método refatorado
                      ),
                const SizedBox(height: 20),

                // Divisor
                const DividerWithText(text: "OU"),
                const SizedBox(height: 20),

                // Botão Login com Google
                SocialLoginButton(
                  text: "Entrar com Google",
                  iconPath: "assets/icons/google.png",
                  // Desabilita se estiver carregando, chama método refatorado
                  onPressed: actionState.isLoading ? () {} : _signInWithGoogle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}