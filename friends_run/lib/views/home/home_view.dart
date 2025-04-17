import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/providers/location_provider.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/views/home/widgets/empty_races.dart';
import 'package:friends_run/views/home/widgets/home_drawer.dart';
import 'package:friends_run/views/home/widgets/race_card.dart';
import 'package:friends_run/views/home/widgets/races_error.dart';
import 'package:friends_run/views/race/create_race/create_race_view.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayedRacesAsync = ref.watch(displayedRacesProvider);

    ref.listen<RaceActionState>(raceNotifierProvider, (_, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        if (ScaffoldMessenger.maybeOf(context) != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: Colors.redAccent,
            ),
          );
          ref.read(raceNotifierProvider.notifier).clearError();
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const HomeDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Corridas Próximas',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.white),
            tooltip: "Ajustar Raio de Busca",
            onPressed: () => _showRadiusSliderBottomSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          const _BuildFilterSortControls(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryRed,
              backgroundColor: AppColors.underBackground,
              onRefresh: () async {
                ref.invalidate(currentLocationProvider);
                await Future.delayed(const Duration(milliseconds: 100));
              },
              child: displayedRacesAsync.when(
                data: (races) {
                  if (races.isEmpty) return const EmptyRacesMessage();
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(top: 0, bottom: 80),
                    itemCount: races.length,
                    itemBuilder: (context, index) => RaceCard(race: races[index]),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                ),
                error: (error, stackTrace) {
                  print("Erro em displayedRacesProvider: $error\n$stackTrace");
                  return RacesErrorWidget(
                    error: error,
                    onRetry: () => ref.invalidate(currentLocationProvider),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  void _showRadiusSliderBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.underBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, sheetRef, child) {
            final distanceRadiusNotifier = ref.read(distanceRadiusProvider.notifier);
            final currentRadius = sheetRef.watch(distanceRadiusProvider);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ajustar Raio de Busca',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.greyLight),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(
                        Icons.radar_outlined,
                        color: AppColors.primaryRed,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: currentRadius,
                          min: 1.0,
                          max: 100.0,
                          divisions: 99,
                          activeColor: AppColors.primaryRed,
                          inactiveColor: AppColors.greyDark,
                          label: '${currentRadius.round()} km',
                          onChanged: (value) {
                            distanceRadiusNotifier.state = value;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 55,
                        child: Text(
                          '${currentRadius.toStringAsFixed(0)} km',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.primaryRed,
      foregroundColor: AppColors.white,
      icon: const Icon(Icons.add_location_alt),
      label: const Text('Criar Corrida'),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateRaceView()),
        );
      },
    );
  }
}

class _BuildFilterSortControls extends ConsumerWidget {
  const _BuildFilterSortControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(raceFilterProvider);
    final currentSortCriteria = ref.watch(raceSortCriteriaProvider);
    final isAscending = ref.watch(sortAscendingProvider);

    final dropdownStyle = TextStyle(
      color: AppColors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    final dropdownIconColor = AppColors.greyLight;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.underBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.filter_alt_outlined,
                  size: 20,
                  color: AppColors.primaryRed,
                ),
              ),
              Expanded(
                child: _buildDropdown<RaceFilterOption>(
                  context: context,
                  value: currentFilter,
                  items: RaceFilterOption.values,
                  label: 'Filtrar por',
                  style: dropdownStyle,
                  iconColor: dropdownIconColor,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(raceFilterProvider.notifier).state = value;
                    }
                  },
                  itemBuilder: (filter) {
                    switch (filter) {
                      case RaceFilterOption.publicas: return 'Públicas';
                      case RaceFilterOption.privadas: return 'Privadas';
                      case RaceFilterOption.todas: default: return 'Todas';
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.sort_outlined,
                  size: 20,
                  color: AppColors.primaryRed,
                ),
              ),
              Expanded(
                child: _buildDropdown<RaceSortCriteria>(
                  context: context,
                  value: currentSortCriteria,
                  items: RaceSortCriteria.values,
                  label: 'Ordenar por',
                  style: dropdownStyle,
                  iconColor: dropdownIconColor,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(raceSortCriteriaProvider.notifier).state = value;
                    }
                  },
                  itemBuilder: (sort) {
                    switch (sort) {
                      case RaceSortCriteria.proximidade: return 'Proximidade';
                      case RaceSortCriteria.distancia: return 'Distância';
                      case RaceSortCriteria.data: return 'Data';
                    }
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: AppColors.white,
                  size: 20,
                ),
                tooltip: isAscending ? "Ordem Crescente" : "Ordem Decrescente",
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: () {
                  ref.read(sortAscendingProvider.notifier).update((state) => !state);
                },
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required T value,
    required List<T> items,
    required String label,
    required TextStyle style,
    required Color iconColor,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: AppColors.underBackground,
        iconEnabledColor: iconColor,
        style: style,
        hint: Text(
          label,
          style: style.copyWith(color: AppColors.greyLight.withOpacity(0.7)),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              itemBuilder(item),
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}