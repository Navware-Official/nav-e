import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class to set up test environment
class TestHelpers {
  /// Sets up SharedPreferences for testing
  static void setupSharedPreferences({Map<String, Object>? values}) {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(values ?? <String, Object>{});
  }

  /// Sets up method channel mocks for platform-specific services
  static void setupMethodChannelMocks() {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock for SharedPreferences
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getAll') {
              return <String, dynamic>{};
            }
            return null;
          });

    // Mock for Geolocator
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geolocator'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'checkPermission':
                return 3; // LocationPermission.always
              case 'requestPermission':
                return 3; // LocationPermission.always
              case 'isLocationServiceEnabled':
                return true;
              default:
                return null;
            }
          });
  }

  /// Cleanup method channels after tests
  static void cleanupMethodChannels() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geolocator'),
          null);
  }
}