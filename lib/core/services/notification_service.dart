import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Centralized notification service for Smart Reminders.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'amar_wallet_channel',
      'Amar Wallet',
      channelDescription: 'Financial notifications and reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Convenience methods for different notification types ──────────────────

  /// Budget alert when spending crosses threshold
  Future<void> showBudgetAlert(String category, int percent, String limit) async {
    await showNotification(
      id: 'budget_$category'.hashCode,
      title: '⚠️ Budget Alert: $category',
      body: 'You\'ve used $percent% of your $limit $category budget.',
    );
  }

  /// Subscription due reminder
  Future<void> showSubscriptionDue(String name, String amount) async {
    await showNotification(
      id: 'sub_$name'.hashCode,
      title: '🔔 Subscription Due: $name',
      body: '$name payment of $amount is due soon.',
    );
  }

  /// Goal progress encouragement
  Future<void> showGoalNudge(String title, int percent) async {
    await showNotification(
      id: 'goal_$title'.hashCode,
      title: '🎯 Goal Progress: $title',
      body: 'You\'re $percent% to your goal! Keep saving!',
    );
  }

  /// Daily spending summary
  Future<void> showDailySummary(String amount, int count) async {
    await showNotification(
      id: 'daily_summary'.hashCode,
      title: '📊 Daily Spending Summary',
      body: 'Today you spent $amount across $count transactions.',
    );
  }
}
