import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GoogleMapsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  final String _apiKey;
  final http.Client _httpClient;

  GoogleMapsService({http.Client? client, String? apiKey})
    : _apiKey = apiKey ?? "AIzaSyB1UI408vrCdPjZAfN8b3bbr9HCnJyVhFM",
      _httpClient = client ?? http.Client();

  Future<String> getRouteMapImage({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    int width = 600,
    int height = 300,
    int zoom = 13,
    String mapType = 'roadmap',
    String mode = 'walking',
  }) async {
    try {
      // Primeiro tenta obter a rota completa com polyline
      final directionsResponse = await _getDirections(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        mode: mode,
      );

      if (directionsResponse != null) {
        final centerLat = (startLat + endLat) / 2;
        final centerLng = (startLng + endLng) / 2;

        return _buildStaticMapUrl(
          startLat: startLat,
          startLng: startLng,
          endLat: endLat,
          endLng: endLng,
          width: width,
          height: height,
          centerLat: centerLat,
          centerLng: centerLng,
          zoom: zoom,
          mapType: mapType,
          path: directionsResponse,
        );
      }
    } catch (e) {
      debugPrint('Erro ao obter rota detalhada: $e');
    }

    // Fallback para rota simples
    return _getSimpleRouteUrl(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      width: width,
      height: height,
      zoom: zoom,
      mapType: mapType,
    );
  }

  Future<String?> _getDirections({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String mode,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/directions/json?'
      'origin=$startLat,$startLng&'
      'destination=$endLat,$endLng&'
      'mode=$mode&'
      'key=$_apiKey',
    );

    try {
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return data['routes'][0]['overview_polyline']['points'] as String;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao obter direções: $e');
      return null;
    }
  }

  String _buildStaticMapUrl({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required int width,
    required int height,
    required double centerLat,
    required double centerLng,
    required int zoom,
    required String mapType,
    String? path,
  }) {
    final buffer =
        StringBuffer('$_baseUrl/staticmap?')
          ..write('size=${width}x$height&')
          ..write('maptype=$mapType&')
          ..write('markers=color:green%7Clabel:S%7C$startLat,$startLng&')
          ..write('markers=color:red%7Clabel:F%7C$endLat,$endLng&');

    if (path != null) {
      buffer.write('path=enc:$path&');
    } else {
      buffer.write(
        'path=color:0x0000ff80%7Cweight:5%7C$startLat,$startLng%7C$endLat,$endLng&',
      );
    }

    buffer
      ..write('center=$centerLat,$centerLng&')
      ..write('zoom=$zoom&')
      ..write('key=$_apiKey');

    return buffer.toString();
  }

  String _getSimpleRouteUrl({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required int width,
    required int height,
    required int zoom,
    required String mapType,
  }) {
    final centerLat = (startLat + endLat) / 2;
    final centerLng = (startLng + endLng) / 2;

    return _buildStaticMapUrl(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      width: width,
      height: height,
      centerLat: centerLat,
      centerLng: centerLng,
      zoom: zoom,
      mapType: mapType,
      path: null,
    );
  }

  Future<String> getShortAddress(double lat, double lng) async {
    try {
      final response = await _httpClient.get(
        Uri.parse(
          '$_baseUrl/geocode/json?'
          'latlng=$lat,$lng&'
          'key=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return _simplifyAddress(
            data['results'][0]['formatted_address'] as String,
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao obter endereço: $e');
    }

    return 'Local desconhecido';
  }

  String _simplifyAddress(String fullAddress) {
    try {
      final parts = fullAddress.split(',').map((p) => p.trim()).toList();

      if (parts.length > 2) {
        // Remove componentes menos importantes (como país, CEP)
        return parts.take(2).join(', ');
      }
      return fullAddress;
    } catch (e) {
      debugPrint('Erro ao simplificar endereço: $e');
      return fullAddress;
    }
  }

  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      final response = await _httpClient.get(
        Uri.parse(
          '$_baseUrl/geocode/json?address=${Uri.encodeComponent(address)}&key=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return {'lat': location['lat'], 'lng': location['lng']};
        }
      }
    } catch (e) {
      debugPrint('Erro ao obter coordenadas: $e');
    }

    return null;
  }

  // Fecha o client HTTP quando não for mais necessário
  void dispose() {
    _httpClient.close();
  }
}
