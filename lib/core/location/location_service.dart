import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Check if location permissions are granted
  Future<bool> hasPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Request location permissions
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates in kilometers
  /// Using Haversine formula
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const double earthRadius = 6371; // Radius of Earth in kilometers

    final double dLat = _toRadians(endLat - startLat);
    final double dLng = _toRadians(endLng - startLng);

   final double a =
    math.sin(dLat / 2) * math.sin(dLat / 2) +
    math.cos(_toRadians(startLat)) *
        math.cos(_toRadians(endLat)) *
        math.sin(dLng / 2) *
        math.sin(dLng / 2);

   final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * 3.141592653589793 / 180;
  }

  /// Format distance for display
  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      final meters = (distanceInKm * 1000).round();
      return '$meters m';
    }
    if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
    return '${distanceInKm.toStringAsFixed(0)} km';
  }
}
