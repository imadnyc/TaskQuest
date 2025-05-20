import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart'; // For kIsWeb

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) {
      // Local notifications are not typically used on web in the same way
      print("Local notifications not initialized for web.");
      return;
    }

    // Initialize timezone database
    tz.initializeTimeZones();
    // You might need to set the local location based on user's timezone if not using UTC for notifications
    // For simplicity, we'll schedule in UTC or device's local time directly later.

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Ensure you have ic_launcher.png in android/app/src/main/res/mipmap

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    // Create a default Android channel (important for Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_due_channel', // id
      'Task Due Reminders', // title
      description: 'Channel for task due date reminders.', // description
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permissions for Android 13+ (POST_NOTIFICATIONS)
    // and for iOS (handled by _requestIOSPermissions)
    if (!kIsWeb) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();

      await _requestIOSPermissions(); // This handles iOS
    }
  }

  Future<void> _requestIOSPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Callback for when a notification is tapped
  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
    // Here you could navigate to a specific task if you pass task ID in payload
    // e.g., MyApp.navigatorKey.currentState?.pushNamed('/task-details', arguments: payload);
  }

  // Callback for older iOS versions (before iOS 10)
  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, navigating to a specific page if needed.
    debugPrint('onDidReceiveLocalNotification: id=$id, title=$title, payload=$payload');
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb) return; // No local notifications on web for this simple setup

    // Ensure the scheduled time is in the future
    if (scheduledDate.isBefore(DateTime.now())) {
        print("Attempted to schedule notification in the past. Ignoring.");
        return;
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local), // Convert to TZDateTime
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_due_channel', // <<< CORRECTED CHANNEL ID
          'Task Expiry Notifications', // channel_name (can keep or align with channel creation)
          channelDescription: 'Notifications for upcoming task deadlines.', // (can keep or align)
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, // Added required parameter
    );
    print("Notification scheduled for id $id at $scheduledDate");
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancel(id);
    print("Cancelled notification with id $id");
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancelAll();
    print("Cancelled all notifications");
  }

  // Example method to show a test notification immediately
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Test Notification', // Title
      'This is a test notification from NotificationService.', // Body
      platformChannelSpecifics,
    );
  }
} 