import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/models/user/app_user.dart';
import 'package:friends_run/core/utils/colors.dart'; // Supondo que AppColors existe aqui
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final ImagePicker picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Estado local
  bool _isLoadingSaveChanges = false;
  bool _isEditing = false;

  // Controladores
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  // Arquivo da imagem
  File? _newProfileImageFile;

  @override
  void initState() {
    super.initState();
    debugPrint("--- ProfileView: initState ---");
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    debugPrint("--- ProfileView: dispose ---");
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    debugPrint("--- ProfileView: _toggleEditMode (isEditing atual: $_isEditing) ---");
    if (!_isEditing) {
      final currentUser = ref.read(currentUserProvider).asData?.value;
      debugPrint("--- ProfileView: Entrando em edição. Usuário atual: ${currentUser?.uid} ---");
      if (currentUser != null) {
        _nameController.text = currentUser.name;
        _emailController.text = currentUser.email;
        debugPrint("--- ProfileView: Controllers preenchidos (Nome: ${currentUser.name}) ---");
      } else {
        _nameController.text = '';
        _emailController.text = '';
        debugPrint("--- ProfileView: Usuário nulo ao entrar em edição! ---");
      }
      _newProfileImageFile = null; // Reseta imagem ao entrar em edição
    } else {
      debugPrint("--- ProfileView: Saindo do modo de edição. ---");
      _formKey.currentState?.reset();
    }
    setState(() { _isEditing = !_isEditing; });
    debugPrint("--- ProfileView: _toggleEditMode FIM (isEditing novo: $_isEditing) ---");
  }

  void _cancelEdit() {
    debugPrint("--- ProfileView: _cancelEdit ---");
    _newProfileImageFile = null;
    setState(() {
      _isEditing = false;
      _formKey.currentState?.reset();
    });
     debugPrint("--- ProfileView: _cancelEdit FIM (isEditing: $_isEditing) ---");
  }

  Future<void> _saveChanges() async {
    debugPrint("--- ProfileView._saveChanges: INÍCIO ---");

    final formState = _formKey.currentState;
    final isValid = formState?.validate() ?? false;
    debugPrint("--- ProfileView._saveChanges: Formulário válido? $isValid ---");
    if (!isValid) {
      debugPrint("--- ProfileView._saveChanges: SAINDO (formulário inválido) ---");
      return;
    }

    final uid = ref.read(currentUserProvider).asData?.value?.uid;
    debugPrint("--- ProfileView._saveChanges: UID obtido? $uid ---");
    if (uid == null) {
       debugPrint("--- ProfileView._saveChanges: SAINDO (UID nulo) ---");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro: Usuário não identificado."), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    setState(() => _isLoadingSaveChanges = true);

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final newImageFile = _newProfileImageFile;
    final authService = ref.read(authServiceProvider);

     debugPrint("--- ProfileView._saveChanges: CHAMANDO authService.updateUserProfile (UID: $uid, Nome: $newName, Email: $newEmail, Imagem?: ${newImageFile != null}) ---");

    try {
      bool success = await authService.updateUserProfile(
        uid: uid, name: newName, email: newEmail, newProfileImage: newImageFile,
      );
      debugPrint("--- ProfileView._saveChanges: Retorno de updateUserProfile: $success ---");

      if (mounted) {
         debugPrint("--- ProfileView._saveChanges: Sucesso! Saindo do modo de edição. ---");
        setState(() {
          _isEditing = false;
          _newProfileImageFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
       debugPrint("--- ProfileView._saveChanges: ERRO CAPTURADO: $e ---");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
       debugPrint("--- ProfileView._saveChanges: Bloco FINALLY ---");
      if (mounted) {
        setState(() => _isLoadingSaveChanges = false);
      }
    }
     debugPrint("--- ProfileView._saveChanges: FIM ---");
  }

  // --- INÍCIO: Funções para escolha e obtenção da imagem ---
  /// Mostra opções Câmera/Galeria
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      // Use cores do seu tema se desejar
      // backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      backgroundColor: AppColors.background.withOpacity(0.95), // Exemplo
      shape: const RoundedRectangleBorder( // Bordas arredondadas
         borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.primaryRed),
                title: const Text('Tirar Foto', style: TextStyle(color: AppColors.white)),
                onTap: () {
                  Navigator.of(context).pop(); // Fecha o sheet
                  _getImage(ImageSource.camera); // Pega da câmera
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryRed),
                title: const Text('Escolher da Galeria', style: TextStyle(color: AppColors.white)),
                onTap: () {
                  Navigator.of(context).pop(); // Fecha o sheet
                  _getImage(ImageSource.gallery); // Pega da galeria
                },
              ),
            ],
          ),
        );
      },
    );
     debugPrint("--- ProfileView: _showImageSourceOptions FIM ---");
  }

  /// Pega a imagem da fonte especificada (Câmera ou Galeria)
  Future<void> _getImage(ImageSource source) async {
    debugPrint("--- ProfileView: _getImage (source: $source) INÍCIO ---");
    try {
      // Não precisa criar um novo picker toda vez, pode usar o da classe
      // final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80, // Qualidade da imagem (0 a 100)
        maxWidth: 1024,  // Largura máxima para redimensionar
        // maxHeight: 1024, // Altura máxima (opcional)
      );
      debugPrint("--- ProfileView: Imagem selecionada da $source? ${image?.path ?? 'NÃO'} ---");

      if (image != null && mounted) {
        setState(() {
          _newProfileImageFile = File(image.path);
          debugPrint("--- ProfileView: _newProfileImageFile atualizado (${_newProfileImageFile?.lengthSync()} bytes) ---");
        });
      }
    } catch (e) {
       debugPrint("--- ProfileView: ERRO ao obter imagem da $source: $e ---");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao usar ${source == ImageSource.camera ? 'a câmera' : 'a galeria'}: ${e.toString()}")),
        );
      }
    }
     debugPrint("--- ProfileView: _getImage FIM ---");
  }
  // --- FIM: Funções para escolha e obtenção da imagem ---


  @override
  Widget build(BuildContext context) {
     debugPrint("--- ProfileView: build INÍCIO (isEditing: $_isEditing, isLoadingSave: $_isLoadingSaveChanges) ---");
    final asyncUser = ref.watch(currentUserProvider);
     debugPrint("--- ProfileView: Estado do currentUserProvider: ${asyncUser.toString()} ---");

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          // Botão Editar
          if (asyncUser.hasValue && asyncUser.value != null && !_isEditing && !_isLoadingSaveChanges)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.white),
              tooltip: 'Editar Perfil',
              onPressed: _toggleEditMode,
            ),
          // Loading na AppBar
          if (_isLoadingSaveChanges)
             const Padding(
               padding: EdgeInsets.only(right: 12.0),
               child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))),
             ),
        ],
      ),
      body: asyncUser.when(
        loading: () {
           debugPrint("--- ProfileView: build (when: loading) ---");
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
        },
        error: (err, stack) {
           debugPrint("--- ProfileView: build (when: error) - Erro: $err ---");
          return _buildErrorStateWidget("Erro ao carregar perfil: $err");
        },
        data: (user) {
           debugPrint("--- ProfileView: build (when: data) - User UID: ${user?.uid} ---");
          if (user == null) {
             debugPrint("--- ProfileView: build (when: data) - Usuário é NULL! ---");
            return _buildErrorStateWidget("Usuário não encontrado ou deslogado.");
          }
          return _buildProfileContent(user);
        },
      ),
    );
  }

  Widget _buildErrorStateWidget(String message) {
    // ... (código do _buildErrorStateWidget igual ao anterior) ...
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text( message, style: const TextStyle(color: AppColors.white, fontSize: 18), textAlign: TextAlign.center,),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, foregroundColor: AppColors.white,),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              onPressed: () {
                 debugPrint("--- ProfileView: Botão Tentar Novamente pressionado ---");
                 final refreshedUser = ref.refresh(currentUserProvider);
                 debugPrint("--- ProfileView: currentUserProvider refreshed: $refreshedUser ---");
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(AppUser user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfilePictureSection(user),
            const SizedBox(height: 32),
            if (_isEditing) _buildEditFormFields() else _buildDisplayInfo(user),
            const SizedBox(height: 40),
            if (_isEditing) _buildActionButtonsEditMode(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(AppUser user) {
    final imageUrl = user.profileImageUrl;
    ImageProvider? displayImageProvider;

     debugPrint("--- ProfileView._buildProfilePictureSection: Construindo. ImageUrl do Firestore: $imageUrl ---");
     debugPrint("--- ProfileView._buildProfilePictureSection: _newProfileImageFile é: ${_newProfileImageFile?.path ?? 'null'} ---");

    if (_newProfileImageFile != null) {
       debugPrint("--- ProfileView._buildProfilePictureSection: Usando _newProfileImageFile ---");
      displayImageProvider = FileImage(_newProfileImageFile!);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      Uri? uri = Uri.tryParse(imageUrl);
      if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
         debugPrint("--- ProfileView._buildProfilePictureSection: Usando CachedNetworkImageProvider para $imageUrl ---");
        displayImageProvider = CachedNetworkImageProvider(imageUrl);
      } else {
         debugPrint("--- ProfileView._buildProfilePictureSection: URL '$imageUrl' inválida, mostrando placeholder. ---");
      }
    } else {
       debugPrint("--- ProfileView._buildProfilePictureSection: ImageUrl nula ou vazia, mostrando placeholder. ---");
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppColors.white.withOpacity(0.2),
          backgroundImage: displayImageProvider,
          child: (displayImageProvider == null)
              ? const Icon( Icons.person, size: 60, color: AppColors.primaryRed)
              : null,
        ),
        // Botão de editar foto
        if (_isEditing)
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.primaryRed,
              shape: const CircleBorder(),
              elevation: 2.0,
              child: InkWell(
                // ATUALIZADO: Chama a função que mostra as opções
                onTap: _showImageSourceOptions,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon( Icons.camera_alt, color: AppColors.white, size: 20),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Mostra informações (não editando)
  Widget _buildDisplayInfo(AppUser user) {
    // ... (código do _buildDisplayInfo igual ao anterior) ...
      return Column(
      children: [
        _buildInfoTile(Icons.person_outline, "Nome", user.name),
        const SizedBox(height: 16),
        _buildInfoTile(Icons.email_outlined, "Email", user.email),
      ],
    );
  }

  // Widget para tile de informação
  Widget _buildInfoTile(IconData icon, String label, String value) {
    // ... (código do _buildInfoTile igual ao anterior) ...
      return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryRed, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text( label, style: TextStyle( color: AppColors.white.withOpacity(0.6), fontSize: 13),),
                const SizedBox(height: 2),
                Text( value, style: const TextStyle(color: AppColors.white, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Campos de edição
  Widget _buildEditFormFields() {
    // ... (código do _buildEditFormFields igual ao anterior) ...
     return Column(
      children: [
        TextFormField(
          controller: _nameController,
          style: const TextStyle( color: AppColors.white),
          decoration: _buildInputDecoration( labelText: 'Nome', prefixIcon: Icons.person_outline,),
          validator: (value) {
            if (value == null || value.trim().isEmpty) { return 'Por favor, insira seu nome'; }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          style: const TextStyle(color: AppColors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: _buildInputDecoration( labelText: 'Email', prefixIcon: Icons.email_outlined,),
          validator: (value) {
            if (value == null || value.trim().isEmpty) { return 'Por favor, insira seu email';}
            if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) { return 'Por favor, insira um email válido';}
            return null;
          },
        ),
      ],
    );
  }

  // Decoração do Input
  InputDecoration _buildInputDecoration({ required String labelText, required IconData prefixIcon}) {
    // ... (código do _buildInputDecoration igual ao anterior) ...
       return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: AppColors.white.withOpacity(0.7)),
      prefixIcon: Icon( prefixIcon, color: AppColors.primaryRed),
      filled: true,
      fillColor: AppColors.white.withOpacity(0.1),
      border: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: const BorderSide( color: AppColors.primaryRed, width: 1.5)),
      errorBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: const BorderSide( color: Colors.redAccent, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }

  // Botões Salvar/Cancelar
  Widget _buildActionButtonsEditMode() {
    // ... (código do _buildActionButtonsEditMode igual ao anterior) ...
     return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom( foregroundColor: AppColors.primaryRed, side: const BorderSide( color: AppColors.primaryRed), padding: const EdgeInsets.symmetric( vertical: 14), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8)), ),
            onPressed: _isLoadingSaveChanges ? null : _cancelEdit,
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom( backgroundColor: AppColors.primaryRed, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8)),),
            onPressed: _isLoadingSaveChanges ? null : _saveChanges,
            child: _isLoadingSaveChanges
                ? const SizedBox( width: 20, height: 20, child: CircularProgressIndicator( strokeWidth: 2, color: AppColors.white))
                : const Text('Salvar'),
          ),
        ),
      ],
    );
  }
} // Fim de _ProfileViewState