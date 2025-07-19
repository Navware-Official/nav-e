import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionHandler {
  static Future<bool> checkAndRequestPermission(State state) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (state.mounted) {
        ScaffoldMessenger.of(state.context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      if (state.mounted) {
        ScaffoldMessenger.of(state.context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied')),
        );
      }
      return false;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        if (state.mounted) {
          ScaffoldMessenger.of(state.context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return false;
      }
    }
    return true;
  }
}