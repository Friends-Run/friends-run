import 'package:flutter/material.dart';
import 'package:friends_run/core/service/auth_service.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/views/auth/login_view.dart';
import 'package:friends_run/views/auth/register_view.dart';
import 'package:friends_run/views/home/home_view.dart';
import 'auth_widgets.dart';

class AuthMainView extends StatelessWidget {
  const AuthMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              // Nome do app
              const Text(
                "Friends Run",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Logo
              const CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/icons/auth_image.png'),
              ),
              const SizedBox(height: 20),

              // Texto secundário
              const Text(
                "Corra com seus amigos e desafie-se!",
                style: TextStyle(fontSize: 16, color: AppColors.greyLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Botão de Cadastro
              PrimaryButton(
                text: "Criar conta",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterView()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Divisor
              const DividerWithText(text: "OU"),
              const SizedBox(height: 20),

              // Botão de Login Social (Google)
              SocialLoginButton(
                text: "Entrar com Google",
                iconPath: "assets/icons/google.png",
                onPressed: () async {
                  final user = await AuthService().signInWithGoogle();

                  if (user != null) {
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeView()),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao fazer login com Google'),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 10),

              // Botão de Login com Email
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginView()),
                  );
                },
                child: const Text(
                  "Já tem uma conta? Entrar",
                  style: TextStyle(fontSize: 16, color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
