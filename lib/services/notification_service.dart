// lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static bool _askedExactAlarm = false;

  static const _channel = AndroidNotificationDetails(
    'reminders_v2',
    'Reminders',
    channelDescription: 'Daily medication and check reminders',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    category: AndroidNotificationCategory.reminder,
    visibility: NotificationVisibility.public,
  );

  static const _details = NotificationDetails(
    android: _channel,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    ),
  );

  /// Call once from main() after WidgetsFlutterBinding.ensureInitialized().
  static Future<void> init() async {
    if (kIsWeb || _ready) return;
    try {
      tzdata.initializeTimeZones();
      // The app targets Iraq, so use Baghdad time (UTC+3).
      tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: settings);
      // Create the high-importance channel up-front so the system shows
      // heads-up alerts with sound.
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'reminders_v2',
              'Reminders',
              description: 'Daily medication and check reminders',
              importance: Importance.max,
            ),
          );
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService.init failed: $e');
    }
  }

  /// Asks for notification permission (Android 13+ / iOS) and, on Android 12+,
  /// for the "Alarms & reminders" permission so reminders fire on time.
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final a = await android?.requestNotificationsPermission();
      final i = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (android != null && !_askedExactAlarm) {
        final canExact = await android.canScheduleExactNotifications() ?? true;
        if (!canExact) {
          _askedExactAlarm = true; // only open the settings page once
          await android.requestExactAlarmsPermission();
        }
      }
      return (a ?? i ?? false);
    } catch (e) {
      debugPrint('NotificationService.requestPermission failed: $e');
      return false;
    }
  }

  /// Re-creates one daily notification per enabled reminder row
  /// (rows from ReminderRepository.loadAll()).
  static Future<void> syncReminders(List<Map<String, dynamic>> rows) async {
    if (kIsWeb) return;
    if (!_ready) await init();
    if (!_ready) return;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canExact = await android?.canScheduleExactNotifications() ?? false;

    await _plugin.cancelAll();
    for (final row in rows) {
      if (row['enabled'] != true) continue;
      final parts = (row['time_of_day']?.toString() ?? '').split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final now = tz.TZDateTime.now(tz.local);
      var when = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (!when.isAfter(now)) when = when.add(const Duration(days: 1));

      final id = row['id'].toString().hashCode & 0x7fffffff;
      final title = 'Asthma Care';
      final body = row['title']?.toString() ?? '';

      Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: mode,
        matchDateTimeComponents: DateTimeComponents.time, // repeats daily
      );

      try {
        await schedule(
          canExact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } on PlatformException catch (e) {
        // Exact alarms not permitted -> fall back to a (slightly delayed) alarm.
        debugPrint('Exact schedule failed (${e.code}); using inexact.');
        try {
          await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
        } catch (e2) {
          debugPrint('Schedule failed: $e2');
        }
      } catch (e) {
        debugPrint('Schedule failed: $e');
      }
    }
  }
}