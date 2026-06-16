import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'solar_calculator.dart';

class CircadianService {
  static final CircadianService _instance = CircadianService._();
  factory CircadianService() => _instance;
  CircadianService._();

  static const _keyEnabled = 'circadian_enabled';
  static const _keyLat = 'circadian_lat';
  static const _keyLon = 'circadian_lon';
  static const _sunsetIdBase = 1000;
  static const _sunriseInfoIdBase = 2000;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
    if (value) {
      await scheduleForNextDays();
    } else {
      await cancelAll();
    }
  }

  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  /// Returns cached coordinates, fetching from GPS only if no cache exists.
  /// Never re-prompts — only checks permission status, never requests it.
  Future<({double lat, double lon})?> _coords() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_keyLat);
    final lon = prefs.getDouble(_keyLon);
    if (lat != null && lon != null) return (lat: lat, lon: lon);
    return _fetchAndCache(prefs);
  }

  Future<({double lat, double lon})?> _fetchAndCache(
      SharedPreferences prefs) async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      await prefs.setDouble(_keyLat, pos.latitude);
      await prefs.setDouble(_keyLon, pos.longitude);
      return (lat: pos.latitude, lon: pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> scheduleForNextDays() async {
    await init();
    await _plugin.cancelAll();

    final c = await _coords();
    if (c == null) return;

    // Use UTC for all scheduling — TZDateTime.from(utcTime, tz.UTC) fires at
    // exactly the right moment without needing to know the named local timezone.
    final nowUtc = tz.TZDateTime.now(tz.UTC);

    for (int day = 0; day < 7; day++) {
      final date = DateTime.now().add(Duration(days: day));

      // Sunset notification: 60 min before local sunset
      final sunsetUtc = SolarCalculator.sunset(
          c.lat, c.lon, DateTime(date.year, date.month, date.day));
      if (sunsetUtc != null) {
        final sunsetLocal = sunsetUtc.toLocal();
        final notifyLocal = sunsetLocal.subtract(const Duration(minutes: 60));
        final tzNotify =
            tz.TZDateTime.from(notifyLocal.toUtc(), tz.UTC);
        if (tzNotify.isAfter(nowUtc)) {
          final h = sunsetLocal.hour.toString().padLeft(2, '0');
          final m = sunsetLocal.minute.toString().padLeft(2, '0');
          await _schedule(
            id: _sunsetIdBase + day,
            title: 'Sunset in 60 minutes',
            body: 'Today\'s sunset is at $h:$m. Step outside.',
            at: tzNotify,
          );
        }
      }

      // 8 PM notification: tomorrow's sunrise time
      final tomorrow = DateTime(date.year, date.month, date.day + 1);
      final sunriseUtc = SolarCalculator.sunrise(c.lat, c.lon, tomorrow);
      if (sunriseUtc != null) {
        final sunriseLocal = sunriseUtc.toLocal();
        final eightPmLocal =
            DateTime(date.year, date.month, date.day, 20, 0);
        final tzEightPm =
            tz.TZDateTime.from(eightPmLocal.toUtc(), tz.UTC);
        if (tzEightPm.isAfter(nowUtc)) {
          final h = sunriseLocal.hour.toString().padLeft(2, '0');
          final m = sunriseLocal.minute.toString().padLeft(2, '0');
          await _schedule(
            id: _sunriseInfoIdBase + day,
            title: 'Tomorrow\'s sunrise',
            body: 'The sun rises at $h:$m tomorrow. Set your alarm.',
            at: tzEightPm,
          );
        }
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime at,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      at,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: false,
        ),
        android: AndroidNotificationDetails(
          'circadian',
          'Circadian Reminders',
          channelDescription: 'Sunset and sunrise timing reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<bool> testNotification() async {
    await init();
    final granted = await requestPermission();
    if (!granted) return false;
    await _plugin.show(
      9999,
      'Circadian test',
      'Notifications are working.',
      const NotificationDetails(
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        android: AndroidNotificationDetails(
          'circadian',
          'Circadian Reminders',
          channelDescription: 'Sunset and sunrise timing reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
    return true;
  }

  Future<({DateTime? sunrise, DateTime? sunset})?> todayTimes() async {
    final c = await _coords();
    if (c == null) return null;
    final today = DateTime.now();
    final sunriseUtc = SolarCalculator.sunrise(c.lat, c.lon, today);
    final sunsetUtc = SolarCalculator.sunset(c.lat, c.lon, today);
    return (
      sunrise: sunriseUtc?.toLocal(),
      sunset: sunsetUtc?.toLocal(),
    );
  }
}
