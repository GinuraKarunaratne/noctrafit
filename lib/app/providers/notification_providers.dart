import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';

/// Provider for notification service - singleton
final notificationServiceProvider = Provider((ref) {
  return NotificationService();
});

/// Provider to request notification permissions
final requestNotificationPermissionProvider =
    FutureProvider<bool>((ref) async {
  return await NotificationService.requestPermission();
});

/// Provider to initialize notifications
final initializeNotificationsProvider = FutureProvider<void>((ref) async {
  await NotificationService.initialize();
});
