import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Notification service for scheduled workout reminders
/// Handles: 30 min before, 5 min before, and at workout time
class NotificationService {
  static final _instance = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  /// Initialize notifications - call once on app startup
  static Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('app_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _instance.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _isInitialized = true;
  }

  /// Request notification permissions
  /// Returns true if permission granted, false otherwise
  static Future<bool> requestPermission() async {
    // Android 13+ requires runtime permission
    final hasPermission = await _instance
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();

    if (hasPermission == false) {
      // Request permission
      final result = await _instance
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      return result ?? false;
    }

    return hasPermission ?? true;
  }

  /// Schedule notifications for a workout
  /// Schedules 3 notifications: 30 mins before, 5 mins before, and at start time
  static Future<void> scheduleWorkoutReminders({
    required int scheduleEntryId,
    required String workoutName,
    required DateTime scheduledDateTime,
  }) async {
    if (!_isInitialized) await initialize();

    // Schedule notification at 30 minutes before
    await _scheduleNotification(
      id: scheduleEntryId * 1000 + 1, // Unique ID
      title: '📢 Workout Reminder',
      body: '$workoutName starts in 30 minutes',
      scheduledDateTime: scheduledDateTime.subtract(Duration(minutes: 30)),
    );

    // Schedule notification at 5 minutes before
    await _scheduleNotification(
      id: scheduleEntryId * 1000 + 2,
      title: '⏰ Get Ready!',
      body: '$workoutName starts in 5 minutes',
      scheduledDateTime: scheduledDateTime.subtract(Duration(minutes: 5)),
    );

    // Schedule notification at start time
    await _scheduleNotification(
      id: scheduleEntryId * 1000 + 3,
      title: '🚀 Time to Work Out!',
      body: 'Start your $workoutName workout now',
      scheduledDateTime: scheduledDateTime,
    );
  }

  /// Internal method to schedule a single notification
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
  }) async {
    try {
      // Only schedule if in the future
      if (scheduledDateTime.isBefore(DateTime.now())) {
        return;
      }

      final tz.TZDateTime tzScheduledDateTime = tz.TZDateTime.from(
        scheduledDateTime,
        tz.local,
      );

      const androidDetails = AndroidNotificationDetails(
        'workout_reminders',
        'Workout Reminders',
        channelDescription: 'Reminders for scheduled workouts',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _instance.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  /// Cancel notifications for a specific workout
  static Future<void> cancelWorkoutReminders(int scheduleEntryId) async {
    try {
      // Cancel all 3 notifications for this workout
      await _instance.cancel(scheduleEntryId * 1000 + 1);
      await _instance.cancel(scheduleEntryId * 1000 + 2);
      await _instance.cancel(scheduleEntryId * 1000 + 3);
    } catch (e) {
      print('Error canceling notifications: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _instance.cancelAll();
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }

  /// Notification response handler
  static void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap (navigate to workout, etc.)
    print('Notification tapped: ${response.payload}');
  }

  /// Show immediate test notification
  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _instance.show(
      0,
      '✅ Notifications Working',
      'Your reminders are set up correctly!',
      notificationDetails,
    );
  }
}
