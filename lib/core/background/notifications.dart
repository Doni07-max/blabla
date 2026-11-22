import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications (shown by the phone itself; no server, unlike FCM push).
///
/// The background task runs in a separate isolate, so [init] must be called
/// there as well as in `main()`. Plugin instances are not shared between isolates.
class AppNotifications {
  AppNotifications._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Android shows this channel in Settings → Apps → android_dev → Notifications.
  static const _likesChannel = AndroidNotificationDetails(
    'likes_digest',
    'Likes digest',
    channelDescription: 'Periodic summary of new likes on your posts',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<void> init() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  /// Android 13+ needs the POST_NOTIFICATIONS runtime permission.
  /// Returns true when notifications are allowed.
  static Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  static Future<void> showLikesDigest({required String title, required String body}) async {
    await init();
    await _plugin.show(
      id: 1, // same id → a new digest replaces the previous one
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: _likesChannel),
    );
  }
}
