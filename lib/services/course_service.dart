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
  DateTime? _semesterStartDate; // 学期开始日期（总是星期一）
  String _currentSemester = '2025-2026-2'; // 当前学期
  List<String> _availableSemesters = ['2025-2026-2']; // 可用学期列表
  Map<String, List<Course>> _semesterCourses = {}; // 各学期的课程数据

  List<Course> get courses => _courses;
  int get currentWeek => _currentWeek;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get semesterStartDate => _semesterStartDate;
  String get currentSemester => _currentSemester;
  List<String> get availableSemesters => _availableSemesters;
  
  bool get isLoggedIn => _apiService.isLoggedIn;

  final JluApiService _apiService = JluApiService();
  
  CourseService() {
    // 初始化时加载缓存数据和设置
    _loadSettings();
    loadCachedCourses();
    _updateCurrentWeek();
  }
  
  // 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startDateStr = prefs.getString('semester_start_date');
      if (startDateStr != null) {
        _semesterStartDate = DateTime.parse(startDateStr);
      }
      
      // 加载当前学期
      _currentSemester = prefs.getString('current_semester') ?? '2025-2026-2';
      
      // 加载可用学期列表
      final semesterListStr = prefs.getString('available_semesters');
      if (semesterListStr != null) {
        _availableSemesters = List<String>.from(json.decode(semesterListStr));
      }
      
      // 加载各学期的课程数据
      for (String semester in _availableSemesters) {
        final coursesJson = prefs.getString('courses_$semester');
        if (coursesJson != null) {
          final coursesList = json.decode(coursesJson) as List;
          _semesterCourses[semester] = coursesList
              .map((courseData) => Course.fromJson(courseData))
              .toList();
        }
      }
      
      // 设置当前学期的课程
      _courses = _semesterCourses[_currentSemester] ?? [];
    } catch (e) {
      print('加载设置失败: $e');
    }
  }
  
  // 根据当前日期自动更新周次
  void _updateCurrentWeek() {
    if (_semesterStartDate == null) return;
    
    final now = DateTime.now();
    final diff = now.difference(_semesterStartDate!);
    final week = (diff.inDays / 7).floor() + 1;
    
    if (week > 0 && week <= 20) {
      _currentWeek = week;
      notifyListeners();
    }
  }
  
  // 设置开学日期（必须是星期一）
  Future<void> setSemesterStartDate(DateTime date) async {
    // 确保是星期一
    if (date.weekday != DateTime.monday) {
      throw Exception('开学日期必须是星期一');
    }
    
    _semesterStartDate = date;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('semester_start_date', date.toIso8601String());
      print('✅ 已保存开学日期: ${date.toString().substring(0, 10)}');
    } catch (e) {
      print('❌ 保存开学日期失败: $e');
    }
    
    _updateCurrentWeek();
  }
  
  // 获取今天是星期几（1-7）
  int getTodayWeekday() {
    return DateTime.now().weekday;
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

  // 获取某个星期和节次的所有课程（不限周次）
  List<Course> getCoursesByWeekdayAndSection(int weekday, int section) {
    return _courses.where((course) {
      return course.weekday == weekday &&
             section >= course.startSection &&
             section <= course.endSection;
    }).toList();
  }
  
  // 获取某个星期某天在当前周没有但其他周有的课程（只返回最近的一个）
  List<Course> getInactiveCoursesByWeekday(int weekday, int currentWeek) {
    final allCoursesForWeekday = _courses.where((course) => course.weekday == weekday).toList();
    final inactiveCourses = allCoursesForWeekday
        .where((course) => !course.weeks.contains(currentWeek))
        .toList();
    
    // 只显示最近的一个非本周课程
    if (inactiveCourses.isNotEmpty) {
      // 找到离当前周最近的课程
      Course? closestCourse;
      int minDistance = 999;
      
      for (var course in inactiveCourses) {
        for (var week in course.weeks) {
          final distance = (week - currentWeek).abs();
          if (distance < minDistance) {
            minDistance = distance;
            closestCourse = course;
          }
        }
      }
      
      return closestCourse != null ? [closestCourse] : [];
    }
    
    return [];
  }
  
  // 获取某个星期和节次在当前周没有但其他周有的课程（只返回最近的一个）
  List<Course> getInactiveCoursesByWeekdayAndSection(int weekday, int section, int currentWeek) {
    final inactiveCourses = getCoursesByWeekdayAndSection(weekday, section)
        .where((course) => !course.weeks.contains(currentWeek))
        .toList();
    
    // 只显示最近的一个非本周课程
    if (inactiveCourses.isNotEmpty) {
      // 找到离当前周最近的课程
      Course? closestCourse;
      int minDistance = 999;
      
      for (var course in inactiveCourses) {
        for (var week in course.weeks) {
          final distance = (week - currentWeek).abs();
          if (distance < minDistance) {
            minDistance = distance;
            closestCourse = course;
          }
        }
      }
      
      return closestCourse != null ? [closestCourse] : [];
    }
    
    return [];
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
    // 合并连续节次的相同课程
    _courses = _mergeContinuousCourses(courses);
    
    // 保存到SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = _courses.map((c) => c.toJson()).toList();
      await prefs.setString('cached_courses', jsonEncode(coursesJson));
      print('✅ 已保存 ${_courses.length} 门课程到本地（原始${courses.length}门）');
    } catch (e) {
      print('❌ 保存课程失败: $e');
    }
    
    notifyListeners();
  }

  // 合并连续节次的相同课程
  List<Course> _mergeContinuousCourses(List<Course> courses) {
    if (courses.isEmpty) return courses;
    
    // 按照星期、开始节次排序
    final sortedCourses = List<Course>.from(courses)
      ..sort((a, b) {
        if (a.weekday != b.weekday) return a.weekday.compareTo(b.weekday);
        return a.startSection.compareTo(b.startSection);
      });
    
    final merged = <Course>[];
    Course? current;
    
    for (final course in sortedCourses) {
      if (current == null) {
        current = course;
        continue;
      }
      
      // 检查是否可以与当前课程合并：
      // 1. 同一天
      // 2. 相同的课程名称、老师、地点
      // 3. 相同的周次列表
      // 4. 节次连续（当前课程的结束节次+1 = 下一个课程的开始节次）
      if (current.weekday == course.weekday &&
          current.name == course.name &&
          current.teacher == course.teacher &&
          current.location == course.location &&
          _areWeeksEqual(current.weeks, course.weeks) &&
          current.endSection + 1 == course.startSection) {
        // 合并：扩展当前课程的结束节次
        current = Course(
          id: current.id,
          name: current.name,
          teacher: current.teacher,
          location: current.location,
          weekday: current.weekday,
          startSection: current.startSection,
          endSection: course.endSection,
          weeks: current.weeks,
          description: current.description,
        );
      } else {
        // 不能合并，保存当前课程，开始新的课程
        merged.add(current);
        current = course;
      }
    }
    
    // 添加最后一个课程
    if (current != null) {
      merged.add(current);
    }
    
    return merged;
  }
  
  // 比较两个周次列表是否相等
  bool _areWeeksEqual(List<int> weeks1, List<int> weeks2) {
    if (weeks1.length != weeks2.length) return false;
    for (int i = 0; i < weeks1.length; i++) {
      if (weeks1[i] != weeks2[i]) return false;
    }
    return true;
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

  // 添加自定义课程
  Future<void> addCustomCourse(Course course) async {
    try {
      _courses.add(course);
      await _saveCourses();
      notifyListeners();
    } catch (e) {
      print('❌ 添加自定义课程失败: $e');
      rethrow;
    }
  }
  
  // 设置课程列表（从外部导入）
  Future<void> setCourses(List<Course> courses) async {
    try {
      _courses = courses;
      _semesterCourses[_currentSemester] = courses;
      await _saveCourses();
      notifyListeners();
      print('✅ 已设置 ${courses.length} 门课程到学期 $_currentSemester');
    } catch (e) {
      print('❌ 设置课程失败: $e');
      rethrow;
    }
  }

  // 更新自定义课程
  Future<void> updateCustomCourse(Course updatedCourse) async {
    try {
      final index = _courses.indexWhere((c) => c.id == updatedCourse.id);
      if (index != -1) {
        _courses[index] = updatedCourse;
        await _saveCourses();
        notifyListeners();
      }
    } catch (e) {
      print('❌ 更新自定义课程失败: $e');
      rethrow;
    }
  }

  // 删除自定义课程
  Future<void> deleteCustomCourse(String courseId) async {
    try {
      _courses.removeWhere((c) => c.id == courseId);
      await _saveCourses();
      notifyListeners();
    } catch (e) {
      print('❌ 删除自定义课程失败: $e');
      rethrow;
    }
  }

  // 保存课程到本地
  Future<void> _saveCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 保存当前学期的课程
      final coursesJson = _courses.map((c) => c.toJson()).toList();
      await prefs.setString('courses_$_currentSemester', jsonEncode(coursesJson));
      
      // 同时保存到旧的缓存键（兼容性）
      await prefs.setString('cached_courses', jsonEncode(coursesJson));
    } catch (e) {
      print('❌ 保存课程失败: $e');
      rethrow;
    }
  }
  
  // 切换学期
  Future<void> switchSemester(String semester) async {
    if (_currentSemester == semester) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 保存当前学期的课程
      _semesterCourses[_currentSemester] = _courses;
      await _saveCourses();
      
      // 切换到新学期
      _currentSemester = semester;
      _courses = _semesterCourses[semester] ?? [];
      
      // 保存当前学期设置
      await prefs.setString('current_semester', semester);
      
      // 如果新学期不在可用列表中，添加它
      if (!_availableSemesters.contains(semester)) {
        _availableSemesters.add(semester);
        await prefs.setString('available_semesters', jsonEncode(_availableSemesters));
      }
      
      print('✅ 切换到学期: $semester，课程数量: ${_courses.length}');
      notifyListeners();
    } catch (e) {
      print('❌ 切换学期失败: $e');
      rethrow;
    }
  }
  
  // 从HTML解析学期信息
  String? parseSemesterFromHtml(String htmlContent) {
    try {
      // 查找学期标签：<label id="dqxnxq2" class="bh-form-label jxrw-label-term" value="2025-2026-2">2025-2026学年第2学期</label>
      final RegExp semesterLabelRegex = RegExp(
        r'<label[^>]+class="[^"]*jxrw-label-term[^"]*"[^>]+value="([^"]+)"[^>]*>',
        caseSensitive: false,
      );
      
      final match = semesterLabelRegex.firstMatch(htmlContent);
      if (match != null) {
        final semester = match.group(1);
        print('✅ 从HTML解析到学期: $semester');
        return semester;
      }
      
      // 备用解析方法：直接搜索学期格式
      final RegExp semesterRegex = RegExp(r'(\d{4}-\d{4}-[12])');
      final semesterMatch = semesterRegex.firstMatch(htmlContent);
      if (semesterMatch != null) {
        final semester = semesterMatch.group(1);
        print('✅ 从HTML备用解析到学期: $semester');
        return semester;
      }
      
      print('❌ 未能从HTML解析到学期信息');
      return null;
    } catch (e) {
      print('❌ 解析HTML学期信息失败: $e');
      return null;
    }
  }
  
  // 导入新学期课表（接受已解析好的课程列表）
  Future<void> importSemesterCourses(String htmlContent, {String? semester, List<Course>? courses}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // 解析学期信息
      final parsedSemester = semester ?? parseSemesterFromHtml(htmlContent);
      if (parsedSemester == null) {
        throw Exception('无法从课表数据中识别学期信息');
      }
      
      // 使用传入的课程数据，如果没有则报错（解析工作由WebView组件完成）
      if (courses == null || courses.isEmpty) {
        throw Exception('没有解析到课程数据，请先通过WebView解析课表');
      }
      
      // 保存到对应学期
      _semesterCourses[parsedSemester] = courses;
      
      // 如果是新学期，添加到可用列表
      if (!_availableSemesters.contains(parsedSemester)) {
        _availableSemesters.add(parsedSemester);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('available_semesters', jsonEncode(_availableSemesters));
      }
      
      // 保存课程数据
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = courses.map((c) => c.toJson()).toList();
      await prefs.setString('courses_$parsedSemester', jsonEncode(coursesJson));
      
      print('✅ 成功导入学期 $parsedSemester 的 ${courses.length} 门课程');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('❌ 导入学期课表失败: $e');
      notifyListeners();
      rethrow;
    }
  }
  
  // 删除学期数据
  Future<void> deleteSemester(String semester) async {
    if (semester == _currentSemester) {
      throw Exception('不能删除当前使用的学期');
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 删除课程数据
      await prefs.remove('courses_$semester');
      
      // 从可用列表中移除
      _availableSemesters.remove(semester);
      _semesterCourses.remove(semester);
      
      // 更新可用学期列表
      await prefs.setString('available_semesters', jsonEncode(_availableSemesters));
      
      print('✅ 已删除学期: $semester');
      notifyListeners();
    } catch (e) {
      print('❌ 删除学期失败: $e');
      rethrow;
    }
  }
}
