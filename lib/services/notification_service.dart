import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/course.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _enabled = true;

  static Future<void> initialize() async {
    if (kIsWeb) {
      _enabled = false;
      return;
    }

    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // 处理点击通知的逻辑
      },
    );
  }

  // 请求通知权限
  static Future<bool> requestPermission() async {
    if (!_enabled) return false;

    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  // 为课程设置提醒
  static Future<void> scheduleCourseReminder(
    Course course,
    int week,
    DateTime semesterStartDate, {
    int minutesBefore = 15,
  }) async {
    if (!_enabled) return;

    // 计算课程的实际日期和时间
    final courseDate = semesterStartDate.add(Duration(days: (week - 1) * 7 + course.weekday - 1));
    
    // 解析课程开始时间
    final timeRange = course.getTimeRange();
    final startTime = timeRange.split('-')[0];
    final timeParts = startTime.split(':');
    
    final courseDateTime = DateTime(
      courseDate.year,
      courseDate.month,
      courseDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
    
    // 提前提醒时间
    final reminderTime = courseDateTime.subtract(Duration(minutes: minutesBefore));
    
    if (reminderTime.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        course.id.hashCode,
        '课程提醒',
        '${course.name}将在$minutesBefore分钟后开始\n地点：${course.location}',
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'course_reminder',
            '课程提醒',
            channelDescription: '课程开始前的提醒通知',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // 取消课程提醒
  static Future<void> cancelCourseReminder(String courseId) async {
    if (!_enabled) return;
    await _notifications.cancel(courseId.hashCode);
  }

  // 取消所有提醒
  static Future<void> cancelAllReminders() async {
    if (!_enabled) return;
    await _notifications.cancelAll();
  }

  // 获取待处理的通知
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_enabled) return <PendingNotificationRequest>[];
    return await _notifications.pendingNotificationRequests();
  }
}
