import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/views/group/group_details_view.dart';
import 'package:friends_run/views/race/create_race/widgets/address_input_section.dart';
import 'package:friends_run/views/race/create_race/widgets/create_button.dart';
import 'package:friends_run/views/race/create_race/widgets/date_time_picker_field.dart';
import 'package:friends_run/views/race/create_race/widgets/distance_indicator.dart';
import 'package:friends_run/views/race/create_race/widgets/map_section.dart';
import 'package:friends_run/views/race/create_race/widgets/privacy_toggle.dart';
import 'package:friends_run/views/race/create_race/widgets/race_title_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:friends_run/core/providers/auth_provider.dart';
import 'package:friends_run/core/providers/race_provider.dart';
import 'package:friends_run/core/utils/colors.dart';

// Provider inicial do mapa
final initialMapPositionProvider = FutureProvider<CameraPosition>((ref) async {
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 14.0,
    );
  } catch (e) {
    debugPrint("Erro ao obter localização inicial: $e. Usando posição padrão.");
    return const CameraPosition(
      target: LatLng(-8.907086, -36.493979),
      zoom: 14.0,
    );
  }
});

class CreateRaceView extends ConsumerStatefulWidget {
  final String? groupId;
  final String? groupName;

  const CreateRaceView({super.key, this.groupId, this.groupName});

  @override
  ConsumerState<CreateRaceView> createState() => _CreateRaceViewState();
}

class _CreateRaceViewState extends ConsumerState<CreateRaceView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _startAddressController = TextEditingController();
  final _endAddressController = TextEditingController();

  // Estado
  DateTime? _selectedDateTime;
  late bool _isPrivate;
  LatLng? _startLatLng;
  LatLng? _endLatLng;
  final Set<Marker> _markers = {};
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;
  bool _isGeocodingStart = false;
  bool _isGeocodingEnd = false;
  double? _calculatedDistanceKm;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.groupId == null ? false : false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startAddressController.dispose();
    _endAddressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // MARK: - Helper Methods

  void _updateDistance() {
    if (_startLatLng == null || _endLatLng == null) {
      if (mounted) setState(() => _calculatedDistanceKm = null);
      return;
    }

    final distanceInMeters = Geolocator.distanceBetween(
      _startLatLng!.latitude, _startLatLng!.longitude,
      _endLatLng!.latitude, _endLatLng!.longitude,
    );

    if (mounted) {
      setState(() => _calculatedDistanceKm = distanceInMeters / 1000.0);
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _selectedDateTime ?? now;
    final validInitial = initial.isBefore(now) ? now : initial;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: validInitial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
    );

    if (pickedTime != null && mounted) {
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );
      });
    }
  }

  // MARK: - Map Methods

  void _onMapCreated(GoogleMapController controller) {
    if (!_mapControllerCompleter.isCompleted) {
      _mapControllerCompleter.complete(controller);
    }
    _mapController = controller;
  }

  void _updateMapMarker(LatLng position, {required bool isStartPoint}) {
    final markerId = MarkerId(isStartPoint ? 'start' : 'end');
    final newMarker = Marker(
      markerId: markerId,
      position: position,
      infoWindow: InfoWindow(title: isStartPoint ? 'Ponto Inicial' : 'Ponto Final'),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        isStartPoint ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
      ),
      draggable: true,
      onDragEnd: (newPos) => _onMarkerDragEnd(markerId.value, newPos),
    );

    if (mounted) {
      setState(() {
        _markers.removeWhere((m) => m.markerId == markerId);
        _markers.add(newMarker);
      });
    }
  }

  void _onMapTap(LatLng point) {
    final actionState = ref.read(raceNotifierProvider);
    if (actionState.isLoading) return;

    bool isStartPoint = _startLatLng == null || _endLatLng != null;

    if (_startLatLng != null && _endLatLng != null) {
      if (mounted) {
        setState(() {
          _endLatLng = null;
          _markers.removeWhere((m) => m.markerId.value == 'end');
          _endAddressController.clear();
          _calculatedDistanceKm = null;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Redefinindo ponto inicial. Toque novamente para o ponto final.')),
      );
      return;
    }

    if (isStartPoint) {
      _startLatLng = point;
    } else {
      _endLatLng = point;
    }

    _updateMapMarker(point, isStartPoint: isStartPoint);
    _reverseGeocodeAndUpdateField(point, isStartPoint: isStartPoint);
    _animateCameraToBounds();
    _updateDistance();
  }

  void _onMarkerDragEnd(String markerIdValue, LatLng newPosition) {
    final isStartPoint = markerIdValue == 'start';
    
    if (isStartPoint) {
      _startLatLng = newPosition;
    } else {
      _endLatLng = newPosition;
    }

    _updateMapMarker(newPosition, isStartPoint: isStartPoint);
    _reverseGeocodeAndUpdateField(newPosition, isStartPoint: isStartPoint);
    _updateDistance();
  }

  void _animateCameraToBounds() {
    if (_mapController == null) return;

    if (_startLatLng != null && _endLatLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _startLatLng!.latitude < _endLatLng!.latitude 
              ? _startLatLng!.latitude 
              : _endLatLng!.latitude,
          _startLatLng!.longitude < _endLatLng!.longitude 
              ? _startLatLng!.longitude 
              : _endLatLng!.longitude,
        ),
        northeast: LatLng(
          _startLatLng!.latitude > _endLatLng!.latitude 
              ? _startLatLng!.latitude 
              : _endLatLng!.latitude,
          _startLatLng!.longitude > _endLatLng!.longitude 
              ? _startLatLng!.longitude 
              : _endLatLng!.longitude,
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60.0));
    } else if (_startLatLng != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_startLatLng!, 15.0));
    } else if (_endLatLng != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_endLatLng!, 15.0));
    }
  }

  // MARK: - Geocoding Methods

  Future<void> _reverseGeocodeAndUpdateField(LatLng point, {required bool isStartPoint}) async {
    final controller = isStartPoint ? _startAddressController : _endAddressController;
    
    try {
      final placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
      final addressText = placemarks.isEmpty 
          ? "Detalhes do endereço não disponíveis"
          : _formatPlacemark(placemarks.first);

      if (mounted) {
        setState(() => controller.text = addressText);
      }
    } catch (e) {
      debugPrint("Erro na geocodificação reversa: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao buscar detalhes do endereço")),
        );
      }
    }
  }

  String _formatPlacemark(Placemark placemark) {
    return [
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
      placemark.postalCode
    ].where((s) => s != null && s.isNotEmpty).join(', ');
  }

  Future<void> _geocodeAddress({required bool isStartPoint}) async {
    final addressController = isStartPoint ? _startAddressController : _endAddressController;
    final address = addressController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um endereço para buscar')),
      );
      return;
    }

    if (mounted) {
      setState(() {
        if (isStartPoint) {
          _isGeocodingStart = true;
        } else {
          _isGeocodingEnd = true;
        }
      });
    }

    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Endereço "$address" não encontrado')),
        );
        return;
      }

      final location = locations.first;
      final foundLatLng = LatLng(location.latitude, location.longitude);

      if (isStartPoint) {
        _startLatLng = foundLatLng;
      } else {
        _endLatLng = foundLatLng;
      }

      _updateMapMarker(foundLatLng, isStartPoint: isStartPoint);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(foundLatLng, 15.0));
      _animateCameraToBounds();
    } catch (e) {
      debugPrint("Erro na geocodificação: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar coordenadas: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (isStartPoint) {
            _isGeocodingStart = false;
          } else {
            _isGeocodingEnd = false;
          }
        });
      }
    }
    _updateDistance();
  }

  void _clearMarkers() {
    if (mounted) {
      setState(() {
        _startLatLng = null;
        _endLatLng = null;
        _markers.clear();
        _startAddressController.clear();
        _endAddressController.clear();
        _calculatedDistanceKm = null;
      });
    }
  }

  String _formatAddress(String address) {
    if (address.isEmpty) return '';

    final replacements = {
      RegExp(r'\b(rua)\b', caseSensitive: false): 'R.',
      RegExp(r'\b(avenida)\b', caseSensitive: false): 'Av.',
      RegExp(r'\b(alameda)\b', caseSensitive: false): 'Al.',
      RegExp(r'\b(travessa)\b', caseSensitive: false): 'Tv.',
      RegExp(r'\b(praça|praca)\b', caseSensitive: false): 'Pç.',
      RegExp(r'\b(estrada)\b', caseSensitive: false): 'Estr.',
      RegExp(r'\b(rodovia)\b', caseSensitive: false): 'Rod.',
      RegExp(r'\b(largo)\b', caseSensitive: false): 'Lg.',
    };

    return replacements.entries.fold(
      address.replaceAll(RegExp(r'\s+'), ' ').trim(),
      (result, entry) => result.replaceAllMapped(entry.key, (_) => entry.value),
    );
  }

  Future<void> _createRace() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data e hora da corrida!')),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider).asData?.value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao obter informações do usuário')),
      );
      return;
    }

    final race = await ref.read(raceNotifierProvider.notifier).createRace(
      title: _titleController.text.trim(),
      date: _selectedDateTime!,
      startAddress: _formatAddress(_startAddressController.text),
      endAddress: _formatAddress(_endAddressController.text),
      owner: currentUser,
      isPrivate: widget.groupId != null ? false : _isPrivate,
      groupId: widget.groupId,
    );

    if (race != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corrida criada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      if (widget.groupId != null) {
        ref.invalidate(groupRacesProvider(widget.groupId!));
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(raceNotifierProvider);
    final initialCameraPositionAsync = ref.watch(initialMapPositionProvider);

    ref.listen<RaceActionState>(raceNotifierProvider, (_, next) {
      if (next.error != null && next.error!.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro: ${next.error!}"),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        ref.read(raceNotifierProvider.notifier).clearError();
      }
    });

    final appBarTitle = widget.groupId == null 
        ? 'Criar Nova Corrida' 
        : 'Nova Corrida: ${widget.groupName ?? 'Grupo'}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(appBarTitle, style: const TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: actionState.isLoading ? null : () => Navigator.pop(context),
        ),
        actions: [
          if (_markers.isNotEmpty)
            IconButton(
              tooltip: "Limpar marcadores e endereços",
              icon: const Icon(Icons.layers_clear, color: Colors.orangeAccent),
              onPressed: actionState.isLoading ? null : _clearMarkers,
            ),
        ],
      ),
      body: IgnorePointer(
        ignoring: actionState.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RaceTitleField(
                  controller: _titleController,
                  enabled: !actionState.isLoading,
                ),
                const SizedBox(height: 16),
                DateTimePickerField(
                  selectedDateTime: _selectedDateTime,
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: 20),
                if (_calculatedDistanceKm != null)
                  DistanceIndicator(distanceKm: _calculatedDistanceKm!),
                AddressInputSection(
                  startController: _startAddressController,
                  endController: _endAddressController,
                  isGeocodingStart: _isGeocodingStart,
                  isGeocodingEnd: _isGeocodingEnd,
                  onGeocode: _geocodeAddress,
                  enabled: !actionState.isLoading,
                ),
                const SizedBox(height: 20),
                MapSection(
                  initialCameraPositionAsync: initialCameraPositionAsync,
                  markers: _markers,
                  onMapCreated: _onMapCreated,
                  onMapTap: _onMapTap,
                ),
                const SizedBox(height: 20),
                if (widget.groupId == null) ...[
                  PrivacyToggle(
                    isPrivate: _isPrivate,
                    onChanged: (value) => setState(() => _isPrivate = value),
                  ),
                  const SizedBox(height: 30),
                ] else ...[
                  const SizedBox(height: 30),
                ],
                CreateRaceButton(
                  isLoading: actionState.isLoading,
                  onPressed: _createRace,
                ),
                if (actionState.isLoading)
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