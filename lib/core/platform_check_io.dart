import 'dart:io' show Platform;

/// True when running on Android (VM/mobile).
bool get isAndroidPlatform => Platform.isAndroid;
