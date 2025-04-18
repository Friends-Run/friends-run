import 'dart:io'; // Para File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Models, Providers, Utils, Services
import 'package:friends_run/models/group/race_group.dart';
import 'package:friends_run/core/providers/group_provider.dart';
import 'package:friends_run/core/utils/colors.dart';
// Importe suas validações se for usar para nome/descrição

class EditGroupView extends ConsumerStatefulWidget {
  final RaceGroup group; // Recebe o grupo a ser editado

  const EditGroupView({required this.group, super.key});

  @override
  ConsumerState<EditGroupView> createState() => _EditGroupViewState();
}

class _EditGroupViewState extends ConsumerState<EditGroupView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late bool _isPublic;
  bool _isLoading = false;
  File? _newImageFile;
  bool _removeCurrentImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(text: widget.group.description ?? '');
    _isPublic = widget.group.isPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Lógica para Seleção/Remoção de Imagem ---
  Future<void> _pickImage() async {
    if (_isLoading) return;
    final ImagePicker picker = ImagePicker();
    ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.underBackground,
      builder: (context) => SafeArea(
        // --- PREENCHENDO OPÇÕES CÂMERA/GALERIA ---
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
        // --- FIM DAS OPÇÕES ---
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
      if (image != null && mounted) {
        setState(() {
          _newImageFile = File(image.path);
          _removeCurrentImage = false;
        });
      }
    } catch (e) {
       debugPrint("Erro ao selecionar imagem: $e");
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao selecionar imagem: ${e.toString()}"), backgroundColor: Colors.redAccent));
    }
  }

  void _triggerRemoveImage() {
     if (_isLoading) return;
     setState(() {
        _newImageFile = null;
        _removeCurrentImage = true;
     });
  }

  // --- Lógica para Salvar Alterações (sem alterações) ---
  Future<void> _saveChanges() async {
     // ... (lógica igual à anterior, chama updateGroupDetails) ...
      FocusScope.of(context).unfocus();
     if (!(_formKey.currentState?.validate() ?? false)) return;

     setState(() => _isLoading = true);

     try {
        final groupService = ref.read(groupServiceProvider);
        final success = await groupService.updateGroupDetails(
          groupId: widget.group.id,
          newName: _nameController.text.trim(),
          newDescription: _descriptionController.text.trim(),
          newIsPublic: _isPublic,
          newImage: _newImageFile,
          removeImage: _removeCurrentImage,
          clearPending: true,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grupo atualizado com sucesso!'), backgroundColor: Colors.green));
          ref.invalidate(groupDetailsProvider(widget.group.id));
          ref.invalidate(allGroupsProvider);
          ref.invalidate(userGroupsProvider);
          Navigator.pop(context);
        } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível atualizar o grupo.'), backgroundColor: Colors.orange));
        }
     } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar grupo: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent));
        }
     } finally {
        if (mounted) setState(() => _isLoading = false);
     }
  }

  // --- Widget para Seletor de Imagem Editável (sem alterações) ---
  Widget _buildEditableGroupImagePicker() {
     // ... (lógica igual à anterior, mostra imagem correta e botão remover) ...
      ImageProvider? displayImageProvider;
    bool currentImageExists = widget.group.imageUrl != null && widget.group.imageUrl!.isNotEmpty;

    if (_newImageFile != null) {
      displayImageProvider = FileImage(_newImageFile!);
    }
    else if (!_removeCurrentImage && currentImageExists) {
      displayImageProvider = CachedNetworkImageProvider(widget.group.imageUrl!);
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _pickImage,
          child: CircleAvatar(
            radius: 55,
            backgroundColor: AppColors.underBackground,
            backgroundImage: displayImageProvider,
            child: displayImageProvider == null
                ? const _PlaceholderIconText(label: "Alterar Foto") // Usa helper
                : const _CameraOverlayIcon(), // Usa helper
          ),
        ),
        // Botão para remover imagem
        // Visibility melhora a performance vs if para esconder/mostrar
        Visibility(
          visible: !_removeCurrentImage && (_newImageFile != null || currentImageExists),
          maintainState: true, maintainAnimation: true, maintainSize: true, // Para evitar pulos no layout
          child: TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              label: const Text("Remover Foto", style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              onPressed: _isLoading ? null : _triggerRemoveImage,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
           ),
        )
      ],
    );
  }

  // --- Helper para InputDecoration (Reutilizado) ---
   InputDecoration _buildInputDecoration({required String labelText, IconData? prefixIcon}) {
      return InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: AppColors.white.withOpacity(0.7)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primaryRed, size: 20) : null,
        filled: true,
        fillColor: AppColors.underBackground, // Cor de fundo definida
        border: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: const BorderSide( color: AppColors.primaryRed, width: 1.5)),
        errorBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: const BorderSide( color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Ajusta padding
        counterStyle: const TextStyle(color: AppColors.greyLight), // Para o contador do maxLength
      );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // Usa o nome atual do grupo no título para clareza
        title: Text('Editar "${widget.group.name}"', style: const TextStyle(color: AppColors.white, fontSize: 18)),
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
                Center(child: _buildEditableGroupImagePicker()), // Seletor de imagem
                const SizedBox(height: 24),

                // --- Nome ---
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  style: const TextStyle(color: AppColors.white),
                  // --- PREENCHENDO DECORATION ---
                  decoration: _buildInputDecoration(
                      labelText: 'Nome do Grupo *',
                      prefixIcon: Icons.group_work,
                  ),
                  // -----------------------------
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome é obrigatório' : null,
                ),
                const SizedBox(height: 16),

                // --- Descrição ---
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isLoading,
                  style: const TextStyle(color: AppColors.white),
                  maxLines: 3, maxLength: 150,
                  // --- PREENCHENDO DECORATION ---
                  decoration: _buildInputDecoration(
                     labelText: 'Descrição (Opcional)',
                     prefixIcon: Icons.description_outlined,
                  ),
                  // -----------------------------
                ),
                const SizedBox(height: 20),

                // Switch público/privado
                SwitchListTile(
                   title: const Text("Grupo Público?", style: TextStyle(color: AppColors.white)),
                   subtitle: Text(_isPublic ? "Qualquer um pode solicitar entrada." : "Apenas por convite (futuro).", style: const TextStyle(color: AppColors.greyLight)),
                   value: _isPublic,
                   onChanged: _isLoading ? null : (value) => setState(() => _isPublic = value),
                   activeColor: AppColors.primaryRed,
                   tileColor: AppColors.underBackground,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                 ),
                const SizedBox(height: 30),

                // Botão Salvar
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar Alterações'), // Texto atualizado
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed, foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  onPressed: _isLoading ? null : _saveChanges,
                ),
                if (_isLoading)
                   const Padding(
                     padding: EdgeInsets.only(top: 16.0),
                     child: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
                   ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Widgets Auxiliares Pequenos ---

// Placeholder para quando não há imagem
class _PlaceholderIconText extends StatelessWidget {
  final String label;
  const _PlaceholderIconText({this.label = "Add Foto"}); // Permite customizar texto
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 30, color: AppColors.greyLight.withOpacity(0.8)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppColors.greyLight.withOpacity(0.8), fontSize: 10))
      ],
    );
  }
}

// Overlay de câmera para indicar clicabilidade
class _CameraOverlayIcon extends StatelessWidget {
  const _CameraOverlayIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
       decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
       ),
       alignment: Alignment.center,
       child: Icon(Icons.camera_alt, color: Colors.white.withOpacity(0.9), size: 30),
    );
  }
}