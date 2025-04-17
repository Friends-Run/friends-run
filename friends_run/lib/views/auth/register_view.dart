import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Remova a importação direta do AuthService se não for mais usada aqui
// import 'package:friends_run/core/services/auth_service.dart';
import 'package:friends_run/views/home/home_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/core/utils/validationsUtils.dart';
// Importe o provider refatorado
import 'package:friends_run/core/providers/auth_provider.dart';
import 'auth_widgets.dart'; // Mantenha seus widgets de UI

// Já é ConsumerStatefulWidget, ótimo
class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  // Controllers para todos os campos do formulário
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Para confirmação

  // Estado local para o caminho da imagem selecionada
  String? _selectedImagePath;
  File? _selectedImageFile; // Armazena o File para upload

  @override
  void dispose() {
    // Limpe todos os controllers
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Se uma ação já estiver em progresso, não permite escolher imagem
    if (ref.read(authNotifierProvider).isLoading) return;

    final ImagePicker picker = ImagePicker();
    XFile? pickedFile;

    // Mostra opções (câmera/galeria)
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea( // Garante que não fique sob elementos do sistema
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Tirar uma foto"),
              onTap: () async {
                Navigator.pop(context); // Fecha o BottomSheet ANTES de abrir a câmera
                pickedFile = await picker.pickImage(source: ImageSource.camera);
                 // Atualiza o estado local após escolher
                 if (pickedFile != null) {
                  setState(() {
                    _selectedImagePath = pickedFile!.path;
                    _selectedImageFile = File(pickedFile!.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Escolher da galeria"),
              onTap: () async {
                 Navigator.pop(context); // Fecha o BottomSheet ANTES de abrir a galeria
                 pickedFile = await picker.pickImage(source: ImageSource.gallery);
                 // Atualiza o estado local após escolher
                 if (pickedFile != null) {
                   setState(() {
                    _selectedImagePath = pickedFile!.path;
                    _selectedImageFile = File(pickedFile!.path);
                  });
                 }
              },
            ),
          ],
        ),
      ),
    );
    // Não precisamos mais chamar o notifier aqui, apenas atualizamos o estado local
  }

  // Método de registro agora usa o notifier e dados locais
  void _register() async {
    FocusScope.of(context).unfocus(); // Fecha o teclado
    if (_formKey.currentState!.validate()) {
      // Pega os dados dos controllers e do estado local da imagem
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text; // Não trim senha

      // Chama o método de registro no notifier
      final registeredUser = await ref
          .read(authNotifierProvider.notifier)
          .registerUser(
            name: name,
            email: email,
            password: password,
            profileImage: _selectedImageFile, // Passa o File
          );

      // Navega se o registro for bem-sucedido
      if (registeredUser != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeView()),
        );
      }
       // O tratamento de erro agora é feito pelo ref.listen abaixo
    }
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
        title: const Text("Cadastro", style: TextStyle(color: AppColors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          // Só permite voltar se não estiver carregando
          onPressed: actionState.isLoading ? null : () => Navigator.pop(context),
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
                // Usa o estado local para a imagem
                ProfileImagePicker(
                  imagePath: _selectedImagePath,
                  onTap: _pickImage, // Chama o método local
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _nameController, // Usa o controller
                  label: "Nome Completo",
                  validator: ValidationUtils.validateName,
                ),
                const SizedBox(height: 15),
                AuthTextField(
                  controller: _emailController, // Usa o controller
                  label: "Email",
                  validator: ValidationUtils.validateEmail,
                ),
                const SizedBox(height: 15),
                AuthTextField(
                  controller: _passwordController, // Usa o controller
                  label: "Senha",
                  isPassword: true,
                  validator: ValidationUtils.validatePassword,
                ),
                const SizedBox(height: 15),
                AuthTextField(
                  controller: _confirmPasswordController, // Usa o controller
                  label: "Confirmar Senha",
                  isPassword: true,
                  validator: (value) => ValidationUtils.validateConfirmPassword(
                    value,
                    _passwordController.text, // Compara com o valor do controller
                  ),
                ),
                const SizedBox(height: 30),

                // Loading ou botão
                actionState.isLoading
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : PrimaryButton(
                        text: "Criar Conta",
                        onPressed: _register, // Chama o método refatorado
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}