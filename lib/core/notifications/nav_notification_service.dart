import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles local push notifications for navigation events (off-route, rerouted).
class NavNotificationService {
  NavNotificationService._();
  static final NavNotificationService instance = NavNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'nav_alerts';
  static const _channelName = 'Navigation Alerts';
  static const _channelDesc = 'Off-route and reroute notifications';

  static const _idOffRoute = 1;
  static const _idRerouted = 2;

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Request Android 13+ notification permission.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showOffRoute() =>
      _show(id: _idOffRoute, title: 'Off route', body: 'Recalculating…');

  Future<void> showRerouted() => _show(
    id: _idRerouted,
    title: 'Route updated',
    body: 'A new route has been calculated.',
  );

  Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      onlyAlertOnce: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }
}
