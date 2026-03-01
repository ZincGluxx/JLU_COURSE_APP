import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/course.dart';
import 'jlu_api_service.dart';

class CourseService extends ChangeNotifier {
  List<Course> _courses = [];
  int _currentWeek = 1;
  bool _isLoading = false;
  String? _error;

  List<Course> get courses => _courses;
  int get currentWeek => _currentWeek;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get isLoggedIn => _apiService.isLoggedIn;

  final JluApiService _apiService = JluApiService();
  
  CourseService() {
    // 初始化时加载缓存数据
    loadCachedCourses();
  }
  
  Future<void> _initLogin() async {
    await _apiService.restoreLoginFromCache();
    notifyListeners();
  }

  // 获取课程表（仅从缓存加载）
  Future<void> fetchCourses() async {
    // 应用启动时从缓存加载课程数据
    // 不再通过API获取，所有课程数据都通过WebView导入
    await loadCachedCourses();
  }

  // 根据周次和星期获取课程
  List<Course> getCoursesByWeekAndDay(int week, int weekday) {
    return _courses.where((course) {
      return course.weeks.contains(week) && course.weekday == weekday;
    }).toList()
      ..sort((a, b) => a.startSection.compareTo(b.startSection));
  }

  // 设置当前周
  void setCurrentWeek(int week) {
    _currentWeek = week;
    notifyListeners();
  }
  
  // 退出登录
  Future<void> logout() async {
    await _apiService.logout();
    _courses = [];
    _currentWeek = 1;
    _error = null;
    notifyListeners();
  }

  // 保存课程（从HTML导入）
  Future<void> saveCourses(List<Course> courses) async {
    _courses = courses;
    
    // 保存到SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = courses.map((c) => c.toJson()).toList();
      await prefs.setString('cached_courses', jsonEncode(coursesJson));
      print('✅ 已保存 ${courses.length} 门课程到本地');
    } catch (e) {
      print('❌ 保存课程失败: $e');
    }
    
    notifyListeners();
  }

  // 清除课程数据
  Future<void> clearCourses() async {
    _courses = [];
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_courses');
      print('✅ 已清除课程数据');
    } catch (e) {
      print('❌ 清除课程数据失败: $e');
    }
    
    notifyListeners();
  }

  // 从本地加载缓存的课程
  Future<void> loadCachedCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJsonStr = prefs.getString('cached_courses');
      
      if (coursesJsonStr != null) {
        final coursesJson = jsonDecode(coursesJsonStr) as List;
        _courses = coursesJson.map((json) => Course.fromJson(json)).toList();
        print('✅ 从缓存加载了 ${_courses.length} 门课程');
        notifyListeners();
      }
    } catch (e) {
      print('❌ 加载缓存课程失败: $e');
    }
  }
}
