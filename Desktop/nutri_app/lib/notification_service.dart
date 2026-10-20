import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  Future<void> showNotification({int id = 0, String? title, String? body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'nutriapp_notifications',
      'Recordatorios NutriApp',
      channelDescription: 'Canal para alertas y recordatorios de comidas',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalnotificationsPluginShowSafe(id, title, body, details);
  }

  // Método auxiliar interno para evitar conflictos de nombres
  Future<void> flutterLocalnotificationsPluginShowSafe(
      int id, String? title, String? body, NotificationDetails details) async {
    await flutterLocalNotificationsPlugin.show(id, title, body, details);
  }
}