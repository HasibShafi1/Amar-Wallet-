import 'package:uuid/uuid.dart';

class ReminderModel {
  final String id;
  final String type; // 'bill' | 'budget' | 'goal' | 'daily'
  final String title;
  final String body;
  final DateTime scheduledAt;
  final bool isRecurring;
  final String? linkedId; // Subscription or goal ID

  ReminderModel({
    String? id,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledAt,
    this.isRecurring = false,
    this.linkedId,
  }) : id = id ?? const Uuid().v4();
}
