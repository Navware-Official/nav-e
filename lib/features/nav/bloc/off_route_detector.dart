import 'package:nav_e/core/notifications/nav_notification_service.dart';

/// Tracks off-route state with debounce and reroute cooldown logic.
///
/// Call [update] on each position tick. Returns `true` when the reroute
/// threshold has been crossed and a cooldown allows re-triggering.
class OffRouteDetector {
  OffRouteDetector({required double thresholdM}) : _thresholdM = thresholdM;

  double _thresholdM;
  int _count = 0;
  bool _notified = false;
  DateTime? _lastRerouteAt;

  /// Update threshold (e.g. after loading user preference on session start).
  set threshold(double value) => _thresholdM = value;

  /// Processes the latest distance-from-route value.
  ///
  /// Returns `true` when the BLoC should dispatch a [NavReroute] event.
  bool update(double distanceFromRouteM) {
    final isOffRoute = distanceFromRouteM > _thresholdM;
    if (isOffRoute) {
      _count++;
      if (!_notified) {
        _notified = true;
        NavNotificationService.instance.showOffRoute();
      }
      final lastReroute = _lastRerouteAt;
      final cooldownOk =
          lastReroute == null ||
          DateTime.now().difference(lastReroute).inSeconds > 30;
      return _count >= 3 && cooldownOk;
    } else {
      _count = 0;
      _notified = false;
      return false;
    }
  }

  /// Called when rerouting begins so the cooldown timer is reset.
  void markRerouting() {
    _lastRerouteAt = DateTime.now();
    _count = 0;
  }

  /// Whether [distanceFromRouteM] exceeds the threshold.
  bool isOffRoute(double distanceFromRouteM) =>
      distanceFromRouteM > _thresholdM;
}
