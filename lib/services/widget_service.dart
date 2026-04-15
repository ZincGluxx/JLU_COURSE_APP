import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../services/course_service.dart';

/// 桌面小组件服务
/// 
/// 提供桌面小组件功能，支持：
/// - 显示今日课程安排
/// - 显示下一节课信息
/// - 课程倒计时显示
/// - 快速查看本周课程
class WidgetService {
  static const String _widgetName = 'JLUCourseWidget';
  
  /// 初始化桌面小组件
  static Future<bool> initialize() async {
    try {
      await HomeWidget.setAppGroupId('group.jlu.course.app');
      print('✅ 桌面小组件服务初始化成功');
      return true;
    } catch (e) {
      print('❌ 桌面小组件初始化失败: $e');
      return false;
    }
  }
  
  /// 更新桌面小组件数据
  /// 
  /// [courseService] 课程服务实例
  static Future<void> updateWidget(CourseService courseService) async {
    try {
      await initialize();
      
      final today = DateTime.now();
      final weekday = today.weekday;
      final currentWeek = courseService.currentWeek;
      
      // 获取今日课程
      final todayCourses = courseService.getCoursesByWeekAndDay(currentWeek, weekday);
      
      // 获取下一节课
      final nextCourse = _getNextCourse(todayCourses, today);
      
      // 准备小组件数据
      final widgetData = {
        'date': '${today.month}/${today.day}',
        'weekday': _getWeekdayName(weekday),
        'week': '第$currentWeek周',
        'courseCount': todayCourses.length,
        'courses': todayCourses.map((course) => {
          'name': course.name,
          'location': course.location,
          'teacher': course.teacher,
          'time': '${course.startSection}-${course.endSection}节',
          'timeRange': course.getTimeRange(),
        }).toList(),
        'nextCourse': nextCourse != null ? {
          'name': nextCourse.name,
          'location': nextCourse.location,
          'time': nextCourse.getTimeRange(),
          'countdown': _getCountdownText(nextCourse, today),
        } : null,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      };
      
      // 更新小组件数据
      await HomeWidget.saveWidgetData<String>('widgetData', jsonEncode(widgetData));
      
      // 更新小组件UI
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
      
      print('✅ 桌面小组件数据更新成功');
      print('📅 今日课程数量: ${todayCourses.length}');
      if (nextCourse != null) {
        print('⏰ 下节课: ${nextCourse.name} (${nextCourse.getTimeRange()})');
      }
      
    } catch (e) {
      print('❌ 更新桌面小组件失败: $e');
    }
  }
  
  /// 获取下一节课
  static Course? _getNextCourse(List<Course> todayCourses, DateTime now) {
    if (todayCourses.isEmpty) return null;
    
    final currentTime = now.hour * 60 + now.minute;
    
    // 课程时间表 (分钟)，对应吉林大学实际作息时间
    final classSchedule = {
      1: 8 * 60 + 0,   // 8:00
      2: 8 * 60 + 55,  // 8:55
      3: 10 * 60 + 0,  // 10:00
      4: 10 * 60 + 55, // 10:55
      5: 13 * 60 + 30, // 13:30
      6: 14 * 60 + 25, // 14:25
      7: 15 * 60 + 30, // 15:30
      8: 16 * 60 + 25, // 16:25
      9: 18 * 60 + 20, // 18:20
      10: 19 * 60 + 6,  // 19:06（吉大实际作息时间）
      11: 20 * 60 + 0,  // 20:00
      12: 20 * 60 + 46, // 20:46
    };
    
    // 找到下一节课
    Course? nextCourse;
    int? nearestTime;
    
    for (final course in todayCourses) {
      final courseTime = classSchedule[course.startSection];
      if (courseTime != null && courseTime > currentTime) {
        if (nearestTime == null || courseTime < nearestTime) {
          nearestTime = courseTime;
          nextCourse = course;
        }
      }
    }
    
    return nextCourse;
  }
  
  /// 获取倒计时文本
  static String _getCountdownText(Course course, DateTime now) {
    final courseTime = _getCourseDateTime(course, now);
    if (courseTime == null) return '';
    
    final difference = courseTime.difference(now);
    if (difference.isNegative) return '进行中';
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours小时$minutes分钟后';
    } else {
      return '$minutes分钟后';
    }
  }
  
  /// 获取课程具体时间
  static DateTime? _getCourseDateTime(Course course, DateTime date) {
    final classSchedule = {
      1: const TimeOfDay(hour: 8, minute: 0),
      2: const TimeOfDay(hour: 8, minute: 55),
      3: const TimeOfDay(hour: 10, minute: 0),
      4: const TimeOfDay(hour: 10, minute: 55),
      5: const TimeOfDay(hour: 13, minute: 30),
      6: const TimeOfDay(hour: 14, minute: 25),
      7: const TimeOfDay(hour: 15, minute: 30),
      8: const TimeOfDay(hour: 16, minute: 25),
      9: const TimeOfDay(hour: 18, minute: 20),
      10: const TimeOfDay(hour: 19, minute: 6),  // 19:06（吉大实际作息时间）
      11: const TimeOfDay(hour: 20, minute: 0),
      12: const TimeOfDay(hour: 20, minute: 46),
    };
    
    final time = classSchedule[course.startSection];
    if (time == null) return null;
    
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
  
  /// 获取星期名称
  static String _getWeekdayName(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }
  
  /// 设置自动更新
  static Future<void> enableAutoUpdate(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('widget_auto_update', enabled);
    
    if (enabled) {
      // 这里可以设置定时更新逻辑
      print('✅ 已启用桌面小组件自动更新');
    } else {
      print('❌ 已禁用桌面小组件自动更新');
    }
  }
  
  /// 检查自动更新状态
  static Future<bool> isAutoUpdateEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('widget_auto_update') ?? true;
  }
  
  /// 手动刷新小组件
  static Future<void> refreshWidget() async {
    try {
      // 这里需要获取CourseService实例
      // 实际使用时应该从Provider或其他状态管理中获取
      print('🔄 正在刷新桌面小组件...');
      
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
      
      print('✅ 桌面小组件刷新完成');
    } catch (e) {
      print('❌ 刷新桌面小组件失败: $e');
    }
  }
  
  /// 获取小组件配置
  static Future<Map<String, dynamic>> getWidgetConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'showNextCourse': prefs.getBool('widget_show_next_course') ?? true,
      'showCourseCount': prefs.getBool('widget_show_course_count') ?? true,
      'showLocation': prefs.getBool('widget_show_location') ?? true,
      'showTeacher': prefs.getBool('widget_show_teacher') ?? false,
      'autoUpdate': prefs.getBool('widget_auto_update') ?? true,
      'transparentBackground': prefs.getBool('widget_transparent_bg') ?? false,
    };
  }
  
  /// 更新小组件配置
  static Future<void> updateWidgetConfig(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final entry in config.entries) {
      if (entry.value is bool) {
        await prefs.setBool(entry.key, entry.value);
      } else if (entry.value is int) {
        await prefs.setInt(entry.key, entry.value);
      } else if (entry.value is String) {
        await prefs.setString(entry.key, entry.value);
      }
    }
    
    print('✅ 桌面小组件配置已更新');
  }
}