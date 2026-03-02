import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';
import '../models/course.dart';
import '../widgets/course_card.dart';
import '../widgets/semester_switch_dialog.dart';
import 'course_edit_screen.dart';

class CourseTableScreen extends StatefulWidget {
  const CourseTableScreen({super.key});

  @override
  State<CourseTableScreen> createState() => _CourseTableScreenState();
}

class _CourseTableScreenState extends State<CourseTableScreen> {
  late PageController _weekPageController; // 周视图的PageView控制器
  late PageController _dayPageController; // 日视图的PageView控制器
  final List<String> _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  bool _isWeekView = true; // 默认为周视图
  int _displayWeek = 1; // 当前显示的周次
  
  // 性能优化缓存
  Map<String, Widget>? _weekViewCache; // 周视图缓存
  double? _cachedScreenWidth; // 缓存屏幕宽度
  Map<int, String>? _dateCache; // 日期缓存
  int? _cachedWeek; // 缓存的周次
  
  // 鲜艳的课程颜色池
  final List<Color> _courseColors = [
    const Color(0xFFFF6B6B), // 珊瑚红
    const Color(0xFF4ECDC4), // 青绿色
    const Color(0xFFFFE66D), // 柠檬黄
    const Color(0xFF95E1D3), // 薄荷绿
    const Color(0xFFFF8B94), // 粉红色
    const Color(0xFF6C5CE7), // 紫罗兰
    const Color(0xFFFEA47F), // 橙色
    const Color(0xFF6BCB77), // 草绿色
    const Color(0xFF4D96FF), // 天蓝色
    const Color(0xFFFD79A8), // 玫瑰粉
    const Color(0xFF00B894), // 翠绿色
    const Color(0xFFFDCB6E), // 金黄色
    const Color(0xFF74B9FF), // 浅蓝色
    const Color(0xFFFF7675), // 西瓜红
    const Color(0xFFA29BFE), // 淡紫色
    const Color(0xFF00CEC9), // 青色
    const Color(0xFFFAB1A0), // 桃色
    const Color(0xFF55EFC4), // 浅绿色
  ];
  
  // 课程名称到颜色的映射
  final Map<String, Color> _courseColorMap = {};

  @override
  void initState() {
    super.initState();
    // 立即初始化PageController，使用默认值
    _weekPageController = PageController(initialPage: 0);
    _dayPageController = PageController(initialPage: 0);
    
    // 在首帧后根据实际数据更新页面
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseService = Provider.of<CourseService>(context, listen: false);
      _displayWeek = courseService.currentWeek;
      // 跳转到当前周
      if (_weekPageController.hasClients) {
        _weekPageController.jumpToPage(courseService.currentWeek - 1);
      }
      // 跳转到今天
      final today = courseService.getTodayWeekday();
      if (_dayPageController.hasClients) {
        _dayPageController.jumpToPage(today - 1);
      }
      
      // 初始化缓存
      _clearCache();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    _dayPageController.dispose();
    _clearCache();
    super.dispose();
  }
  
  // 清除缓存
  void _clearCache() {
    _weekViewCache?.clear();
    _weekViewCache = null;
    _cachedScreenWidth = null;
    _dateCache?.clear();
    _dateCache = null;
    _cachedWeek = null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseService>(
      builder: (context, courseService, child) {
        if (courseService.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (courseService.error != null) {
          // 检查是否是401认证错误
          final is401Error = courseService.error!.contains('401') || 
                             courseService.error!.contains('Unauthorized');
          
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      is401Error ? Icons.lock_outline : Icons.error_outline,
                      size: 64,
                      color: is401Error ? Colors.orange : Colors.red,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      is401Error ? '登录已过期' : '加载失败',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      courseService.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (is401Error) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Cookie已失效，请重新登录获取最新数据',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!is401Error) ...[
                          ElevatedButton.icon(
                            onPressed: () => courseService.fetchCourses(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('重试'),
                          ),
                          const SizedBox(width: 16),
                        ],
                        OutlinedButton.icon(
                          onPressed: () async {
                            // 清除登录信息
                            await courseService.logout();
                            if (context.mounted) {
                              // 跳转到设置页面
                              Navigator.popUntil(context, (route) => route.isFirst);
                              // 导航到设置标签（假设是第3个标签）
                              DefaultTabController.of(context).animateTo(2);
                            }
                          },
                          icon: const Icon(Icons.login),
                          label: Text(is401Error ? '重新登录' : '去登录'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: is401Error ? Colors.orange : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('课程表'),
                Text(
                  _formatSemesterName(courseService.currentSemester),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            actions: [
              // 编辑课程按钮
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: '编辑课程',
                onPressed: () {
                  Navigator.pushNamed(context, '/course_edit');
                },
              ),
              // 视图切换按钮
              IconButton(
                icon: Icon(_isWeekView ? Icons.view_day : Icons.view_week),
                tooltip: _isWeekView ? '切换到日视图' : '切换到周视图',
                onPressed: () {
                  setState(() {
                    _isWeekView = !_isWeekView;
                  });
                },
              ),
              // 周数切换（左箭头）
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _displayWeek > 1
                    ? () {
                        if (_isWeekView) {
                          _weekPageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          setState(() {
                            _displayWeek--;
                            courseService.setCurrentWeek(_displayWeek);
                          });
                        }
                      }
                    : null,
              ),
              // 周数显示
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Text(
                    '第$_displayWeek周',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // 周数切换（右箭头）
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _displayWeek < 20
                    ? () {
                        if (_isWeekView) {
                          _weekPageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          setState(() {
                            _displayWeek++;
                            courseService.setCurrentWeek(_displayWeek);
                          });
                        }
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                tooltip: '切换学期',
                onPressed: () => showSemesterSwitchDialog(context),
              ),
            ],
          ),
          body: _isWeekView 
              ? PageView.builder(
                  controller: _weekPageController,
                  itemCount: 20,
                  onPageChanged: (page) {
                    // 清除当周次改变时的缓存
                    if (_cachedWeek != page + 1) {
                      _clearCache();
                    }
                    setState(() {
                      _displayWeek = page + 1;
                    });
                    courseService.setCurrentWeek(page + 1);
                  },
                  itemBuilder: (context, index) {
                    return _buildWeekView(courseService, index + 1);
                  },
                )
              : _buildDayView(courseService),
        );
      },
    );
  }

  // 日视图（原来的视图）
  Widget _buildDayView(CourseService courseService) {
    return Column(
      children: [
        // 星期标签
        Container(
          height: 50,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: _weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // 课程表内容
        Expanded(
          child: PageView.builder(
            controller: _dayPageController,
            itemCount: 7,
            itemBuilder: (context, weekdayIndex) {
              final courses = courseService.getCoursesByWeekAndDay(
                courseService.currentWeek,
                weekdayIndex + 1,
              );

              if (courses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_weekdays[weekdayIndex]}没有课程',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final color = _getCourseColor(courses[index].name);
                  return CourseCard(course: courses[index], courseColor: color);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 周视图（网格视图）- 性能优化版本
  Widget _buildWeekView(CourseService courseService, int week) {
    // 使用缓存机制提高性能
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 检查是否可以使用缓存
    if (_weekViewCache != null && 
        _cachedScreenWidth == screenWidth && 
        _cachedWeek == week) {
      final cacheKey = 'week_$week';
      if (_weekViewCache!.containsKey(cacheKey)) {
        return _weekViewCache![cacheKey]!;
      }
    }
    
    // 初始化缓存
    _weekViewCache ??= {};
    _cachedScreenWidth = screenWidth;
    _cachedWeek = week;
    
    // 预计算布局参数
    final layoutParams = _calculateLayoutParams(screenWidth);
    
    // 预处理课程数据
    final weekData = _preprocessWeekData(courseService, week);
    
    // 构建视图
    final widget = _buildOptimizedWeekGrid(courseService, week, layoutParams, weekData);
    
    // 缓存结果
    _weekViewCache!['week_$week'] = widget;
    
    return widget;
  }
  
  // 计算布局参数（缓存）
  Map<String, double> _calculateLayoutParams(double screenWidth) {
    const padding = 8.0;
    final availableWidth = screenWidth - padding;
    final sectionColumnWidth = availableWidth * 0.10;
    final dayColumnWidth = (availableWidth - sectionColumnWidth) / 7;
    const cellHeight = 56.0;
    
    return {
      'padding': padding,
      'sectionColumnWidth': sectionColumnWidth,
      'dayColumnWidth': dayColumnWidth,
      'cellHeight': cellHeight,
    };
  }
  
  // 预处理周数据
  Map<String, dynamic> _preprocessWeekData(CourseService courseService, int week) {
    // 缓存日期计算
    _dateCache ??= {};
    final dates = <int, String>{};
    final semesterStartDate = courseService.semesterStartDate;
    
    for (int weekday = 1; weekday <= 7; weekday++) {
      final cacheKey = week * 10 + weekday;
      if (_dateCache!.containsKey(cacheKey)) {
        dates[weekday] = _dateCache![cacheKey]!;
      } else {
        String dateStr = '--/--';
        if (semesterStartDate != null) {
          final currentDate = semesterStartDate.add(Duration(days: (week - 1) * 7 + (weekday - 1)));
          dateStr = '${currentDate.month}/${currentDate.day}';
        }
        dates[weekday] = dateStr;
        _dateCache![cacheKey] = dateStr;
      }
    }
    
    // 预计算课程分组
    final courseGroups = <int, Map<String, List<Course>>>{};
    final today = courseService.getTodayWeekday();
    final isCurrentWeek = week == courseService.currentWeek;
    
    for (int weekday = 1; weekday <= 7; weekday++) {
      final courses = courseService.getCoursesByWeekAndDay(week, weekday);
      final inactiveCourses = courseService.getInactiveCoursesByWeekday(weekday, week);
      
      // 简化分组逻辑
      final isToday = isCurrentWeek && weekday == today && _isToday(semesterStartDate, week, weekday);
      
      courseGroups[weekday] = {
        'active': isToday ? courses : <Course>[],
        'normal': isToday ? <Course>[] : courses,
        'inactive': courses.isEmpty ? inactiveCourses : <Course>[],
      };
    }
    
    return {
      'dates': dates,
      'courseGroups': courseGroups,
      'today': today,
      'isCurrentWeek': isCurrentWeek,
    };
  }
  
  // 检查是否为今天（优化后的日期检查）
  bool _isToday(DateTime? semesterStartDate, int week, int weekday) {
    if (semesterStartDate == null) return false;
    
    final currentDate = semesterStartDate.add(Duration(days: (week - 1) * 7 + (weekday - 1)));
    final today = DateTime.now();
    
    return currentDate.year == today.year && 
           currentDate.month == today.month && 
           currentDate.day == today.day;
  }
  
  // 构建优化的周网格
  Widget _buildOptimizedWeekGrid(
    CourseService courseService, 
    int week, 
    Map<String, double> layoutParams,
    Map<String, dynamic> weekData,
  ) {
    const maxSections = 12;
    final cellHeight = layoutParams['cellHeight']!;
    final dates = weekData['dates'] as Map<int, String>;
    final courseGroups = weekData['courseGroups'] as Map<int, Map<String, List<Course>>>;
    final today = weekData['today'] as int;
    final isCurrentWeek = weekData['isCurrentWeek'] as bool;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: layoutParams['padding']! / 2),
      child: Column(
        children: [
          // 优化的表头
          _buildOptimizedHeader(layoutParams, dates, today, isCurrentWeek),
          // 优化的课程网格
          _buildOptimizedGrid(layoutParams, courseGroups, maxSections, cellHeight),
        ],
      ),
    );
  }
  
  // 构建优化的表头
  Widget _buildOptimizedHeader(
    Map<String, double> layoutParams, 
    Map<int, String> dates, 
    int today, 
    bool isCurrentWeek,
  ) {
    return Row(
      children: [
        // 节次列标题
        Container(
          width: layoutParams['sectionColumnWidth']!,
          height: 28,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: const Center(
            child: Text('节次', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
          ),
        ),
        // 星期列标题
        ...List.generate(7, (index) {
          final weekday = index + 1;
          final isToday = isCurrentWeek && weekday == today;
          final dateStr = dates[weekday] ?? '--/--';

          return Container(
            width: layoutParams['dayColumnWidth']!,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
              color: isToday
                  ? Colors.amber.withOpacity(0.3)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _weekdays[index],
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
                      fontSize: 10,
                      color: isToday ? Colors.amber.shade900 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 8, 
                      color: isToday ? Colors.amber.shade900 : Colors.grey[700]
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
  
  // 构建优化的网格
  Widget _buildOptimizedGrid(
    Map<String, double> layoutParams,
    Map<int, Map<String, List<Course>>> courseGroups,
    int maxSections,
    double cellHeight,
  ) {
    return SizedBox(
      height: maxSections * cellHeight,
      child: Row(
        children: [
          // 节次列
          _buildSectionColumn(layoutParams, maxSections, cellHeight),
          // 课程列
          ...List.generate(7, (dayIndex) {
            final weekday = dayIndex + 1;
            final groups = courseGroups[weekday]!;
            return _buildDayColumn(layoutParams, groups, cellHeight, maxSections);
          }),
        ],
      ),
    );
  }
  
  // 构建节次列
  Widget _buildSectionColumn(Map<String, double> layoutParams, int maxSections, double cellHeight) {
    return Column(
      children: List.generate(maxSections, (sectionIndex) {
        final section = sectionIndex + 1;
        final timeStr = Course(
          id: '', name: '', teacher: '', location: '', weekday: 1,
          startSection: section, endSection: section, weeks: [], description: ''
        ).getTimeRange();
        
        return Container(
          width: layoutParams['sectionColumnWidth']!,
          height: cellHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$section', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              Text(timeStr, style: const TextStyle(fontSize: 8, color: Colors.grey)),
            ],
          ),
        );
      }),
    );
  }
  
  // 构建单天列
  Widget _buildDayColumn(
    Map<String, double> layoutParams,
    Map<String, List<Course>> courseGroups,
    double cellHeight,
    int maxSections,
  ) {
    final activeCourses = courseGroups['active']!;
    final normalCourses = courseGroups['normal']!;
    final inactiveCourses = courseGroups['inactive']!;
    final isToday = activeCourses.isNotEmpty;
    
    return SizedBox(
      width: layoutParams['dayColumnWidth']!,
      child: Stack(
        children: [
          // 背景网格
          Column(
            children: List.generate(maxSections, (sectionIndex) {
              return Container(
                height: cellHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  color: isToday ? Colors.amber.withOpacity(0.05) : null,
                ),
              );
            }),
          ),
          // 课程块 - 使用更简单的逻辑
          ..._buildCourseBlocks(activeCourses, cellHeight, false),
          ..._buildCourseBlocks(normalCourses, cellHeight, false),
          ..._buildCourseBlocks(inactiveCourses, cellHeight, true),
        ],
      ),
    );
  }
  
  // 构建课程块（简化版）
  List<Widget> _buildCourseBlocks(List<Course> courses, double cellHeight, bool isInactive) {
    return courses.map((course) {
      final top = (course.startSection - 1) * cellHeight;
      final height = (course.endSection - course.startSection + 1) * cellHeight;
      return Positioned(
        top: top,
        left: 0,
        right: 0,
        height: height,
        child: _buildMergedCourseCell(course, isInactive, isWeekView: true),
      );
    }).toList();
  }

  // 根据课程名称获取颜色
  Color _getCourseColor(String courseName) {
    if (_courseColorMap.containsKey(courseName)) {
      return _courseColorMap[courseName]!;
    }
    final colorIndex = _courseColorMap.length % _courseColors.length;
    final color = _courseColors[colorIndex];
    _courseColorMap[courseName] = color;
    return color;
  }

  // 合并单元格的课程显示（完整高度）
  Widget _buildMergedCourseCell(Course course, bool isInactive, {bool isWeekView = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final baseColor = _getCourseColor(course.name);

    return InkWell(
      onTap: () => _showCourseDetailDialog(course),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: isWeekView ? const EdgeInsets.all(2) : const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isInactive
              ? baseColor.withOpacity(0.25)
              : baseColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isInactive
                ? baseColor.withOpacity(0.4)
                : baseColor.withOpacity(0.8),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              course.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 10 : 11,
                color: isInactive
                    ? Colors.white.withOpacity(0.6)
                    : Colors.white,
                shadows: isInactive ? null : [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // 地点信息
            if (course.location.isNotEmpty) ...[
              Text(
                _shortenLocation(course.location),
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withOpacity(isInactive ? 0.5 : 0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
            ],
            // 上课时间和周次（仅在日视图显示）
            if (!isWeekView) ...[
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 9,
                    color: Colors.white.withOpacity(isInactive ? 0.5 : 0.9),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      '${course.getTimeRange()} (${course.startSection}-${course.endSection}节)',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white.withOpacity(isInactive ? 0.5 : 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            // 周次信息（周视图不显示）
            if (course.weeks.isNotEmpty && !isWeekView) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 9,
                    color: Colors.white.withOpacity(isInactive ? 0.5 : 0.9),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      '第${course.weeks.first}-${course.weeks.last}周',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white.withOpacity(isInactive ? 0.5 : 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 显示课程详细信息对话框
  void _showCourseDetailDialog(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                course.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Icons.person, '授课教师', course.teacher),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.location_on, '上课地点', course.location),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.access_time,
                '上课时间',
                '${_weekdays[course.weekday - 1]} 第${course.startSection}-${course.endSection}节',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.schedule,
                '时间段',
                course.getTimeRange(),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.calendar_today,
                '上课周次',
                _formatWeeks(course.weeks),
              ),
              if (course.description != null && course.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow(Icons.info_outline, '备注', course.description!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseEditScreen(course: course),
                ),
              );
            },
            child: const Text('编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 构建详细信息行
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '未设置' : value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 格式化周次显示
  String _formatWeeks(List<int> weeks) {
    if (weeks.isEmpty) return '全部周次';
    
    // 如果是连续的周次，显示为范围
    if (weeks.length > 2 && _isConsecutive(weeks)) {
      return '第${weeks.first}-${weeks.last}周';
    }
    
    // 否则显示为列表
    if (weeks.length > 10) {
      return '第${weeks.take(10).join('、')}...周';
    }
    return '第${weeks.join('、')}周';
  }

  // 检查是否为连续周次
  bool _isConsecutive(List<int> weeks) {
    for (int i = 1; i < weeks.length; i++) {
      if (weeks[i] != weeks[i - 1] + 1) {
        return false;
      }
    }
    return true;
  }

  // 简化地点名称（去掉校区前缀等）
  String _shortenLocation(String location) {
    // 移除常见的校区前缀
    location = location
        .replaceAll('前卫-', '')
        .replaceAll('中心校区-', '')
        .replaceAll('南岭校区-', '')
        .replaceAll('和平校区-', '')
        .replaceAll('朝阳校区-', '');
    return location;
  }
  
  // 格式化学期名称显示
  String _formatSemesterName(String semester) {
    // 将 "2025-2026-2" 转换为 "2025-2026学年第2学期"
    final parts = semester.split('-');
    if (parts.length >= 3) {
      return '${parts[0]}-${parts[1]}学年第${parts[2]}学期';
    }
    return semester;
  }
}
