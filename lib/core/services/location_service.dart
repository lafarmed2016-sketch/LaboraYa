import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final String department;
  final String province;
  final String district;
  final double latitude;
  final double longitude;

  LocationResult({
    required this.department,
    required this.province,
    required this.district,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  static Future<LocationResult?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('El servicio de ubicación GPS está desactivado. Por favor, actívalo en tu dispositivo.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permiso de ubicación denegado.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('El permiso de ubicación está denegado permanentemente. Actívalo en la configuración de la app.');
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          position = lastKnown;
        } else {
          throw Exception('No se pudo obtener la ubicación GPS actual ni la última conocida. Activa tu GPS.');
        }
      }

      String department = 'Lima';
      String province = 'Lima';
      String district = 'Miraflores';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            department = _cleanLocationString(place.administrativeArea!);
          }
          if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
            province = _cleanLocationString(place.subAdministrativeArea!);
          }
          final candidateDistrict = place.locality ?? place.subLocality;
          if (candidateDistrict != null && candidateDistrict.isNotEmpty) {
            district = _cleanLocationString(candidateDistrict);
          }
        }
      } catch (e) {
        debugPrint('Geocoding notice: $e');
      }

      return LocationResult(
        department: department,
        province: province,
        district: district,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('No se pudo obtener la ubicación: $e');
    }
  }

  static String _cleanLocationString(String input) {
    return input
        .replaceAll('Region de ', '')
        .replaceAll('Región de ', '')
        .replaceAll('Departamento de ', '')
        .replaceAll('Provincia de ', '')
        .replaceAll('Municipalidad de ', '')
        .trim();
  }
}
