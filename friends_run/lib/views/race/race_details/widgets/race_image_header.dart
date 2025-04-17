import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:friends_run/core/utils/colors.dart'; // Importe suas cores

class RaceImageHeader extends StatelessWidget {
  final String? imageUrl;
  final String raceId;

  const RaceImageHeader({
    super.key,
    required this.imageUrl,
    required this.raceId,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const SizedBox.shrink(); // Não mostra nada se não houver imagem
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Hero(
          tag: 'race_image_$raceId', // Usa o raceId para a tag Hero
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              color: AppColors.underBackground, // Use sua cor de placeholder
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryRed, // Use sua cor primária
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: AppColors.underBackground, // Use sua cor de erro
              child: const Center(
                child: Icon(
                  Icons.running_with_errors_rounded,
                  color: AppColors.greyLight, // Use sua cor de ícone de erro
                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}