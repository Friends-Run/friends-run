import 'dart:io'; // Necessário para File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // Importado para seleção de imagem
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/providers/group_provider.dart';
import 'package:friends_run/core/utils/colors.dart';

class CreateGroupView extends ConsumerStatefulWidget {
  const CreateGroupView({super.key});

  @override
  ConsumerState<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends ConsumerState<CreateGroupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = true;
  bool _isLoading = false;
  File? _selectedImageFile; // Estado para armazenar a imagem selecionada

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- NOVO: Método para escolher a imagem (do código novo) ---
  Future<void> _pickImage() async {
    if (_isLoading) return; // Não permite escolher se já está carregando
    final ImagePicker picker = ImagePicker();
    ImageSource? source;

    // Mostra diálogo para escolher Câmera ou Galeria
    await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.underBackground,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primaryRed),
              title: const Text('Escolher da Galeria', style: TextStyle(color: AppColors.white)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.primaryRed),
              title: const Text('Tirar Foto', style: TextStyle(color: AppColors.white)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    ).then((value) => source = value); // Captura a fonte escolhida

    if (source == null) return; // Usuário cancelou

    try {
      final XFile? image = await picker.pickImage(
        source: source!,
        imageQuality: 80, // Comprime um pouco
        maxWidth: 800,    // Redimensiona
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImageFile = File(image.path); // Armazena o arquivo
        });
      }
    } catch (e) {
       debugPrint("Erro ao selecionar imagem: $e");
       if(mounted){
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao selecionar imagem: ${e.toString()}"), backgroundColor: Colors.redAccent));
       }
    }
  }
  // --- FIM do Método _pickImage ---


  Future<void> _createGroup() async {
    FocusScope.of(context).unfocus(); // Esconde o teclado
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Você precisa estar logado para criar um grupo.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final groupService = ref.read(groupServiceProvider);
      final newGroup = await groupService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        adminId: user.uid,
        isPublic: _isPublic,
        groupImage: _selectedImageFile, // *** MODIFICADO: Passa o arquivo da imagem selecionada ***
      );

      if (newGroup != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grupo criado com sucesso!'), backgroundColor: Colors.green),
        );
        ref.invalidate(userGroupsProvider); // Atualiza tela do usuário
        ref.invalidate(allGroupsProvider); // Atualiza exploração geral
        Navigator.pop(context); // Volta pra lista
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível criar o grupo.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar grupo: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NOVO: Widget para o seletor de imagem (do código novo) ---
  Widget _buildGroupImagePicker() {
    ImageProvider? imageProvider;
    if (_selectedImageFile != null) {
      imageProvider = FileImage(_selectedImageFile!); // Mostra imagem local selecionada
    }
    // Não temos imagem de rede aqui (diferente do ProfileView)

    return GestureDetector(
      onTap: _isLoading ? null : _pickImage, // Permite tocar para escolher
      child: CircleAvatar(
        radius: 55, // Um pouco maior
        backgroundColor: AppColors.underBackground, // Cor de fundo
        backgroundImage: imageProvider, // Mostra a imagem selecionada
        child: imageProvider == null
          ? Column( // Ícone e texto placeholder
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 30, color: AppColors.greyLight.withOpacity(0.8)),
                const SizedBox(height: 4),
                Text("Add Foto", style: TextStyle(color: AppColors.greyLight.withOpacity(0.8), fontSize: 10))
              ],
            )
          : Container( // Overlay sutil para indicar clicabilidade mesmo com imagem
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
            ),
      ),
    );
  }
  // --- FIM do Widget _buildGroupImagePicker ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Criar Novo Grupo', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: IgnorePointer(
        ignoring: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _buildGroupImagePicker()),
                const SizedBox(height: 24),

                // Nome
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Nome do Grupo *',
                    labelStyle: const TextStyle(color: AppColors.greyLight),
                    prefixIcon: const Icon(Icons.group_work, color: AppColors.primaryRed),
                    filled: true,
                    fillColor: AppColors.underBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Nome do grupo é obrigatório'
                      : null,
                ),
                const SizedBox(height: 16),

                // Descrição
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isLoading,
                  style: const TextStyle(color: AppColors.white),
                  maxLines: 3,
                  maxLength: 150,
                  decoration: InputDecoration(
                    labelText: 'Descrição (Opcional)',
                    labelStyle: const TextStyle(color: AppColors.greyLight),
                    prefixIcon: const Icon(Icons.description_outlined, color: AppColors.primaryRed),
                    filled: true,
                    fillColor: AppColors.underBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    counterStyle: const TextStyle(color: AppColors.greyLight),
                  ),
                ),
                const SizedBox(height: 20),

                // Switch público/privado
                SwitchListTile(
                  title: const Text("Grupo Público?", style: TextStyle(color: AppColors.white)),
                  subtitle: Text(
                    _isPublic
                        ? "Qualquer um pode solicitar entrada."
                        : "Apenas por convite (futuro).", // Manter lógica original ou adaptar se necessário
                    style: const TextStyle(color: AppColors.greyLight),
                  ),
                  value: _isPublic,
                  onChanged: _isLoading ? null : (value) => setState(() => _isPublic = value),
                  activeColor: AppColors.primaryRed,
                  tileColor: AppColors.underBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                ),
                const SizedBox(height: 30),

                // Botão Criar
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Criar Grupo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _createGroup,
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}