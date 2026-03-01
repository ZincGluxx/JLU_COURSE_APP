import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';
import '../models/course.dart';
import '../widgets/course_card.dart';

class CourseTableScreen extends StatefulWidget {
  const CourseTableScreen({super.key});

  @override
  State<CourseTableScreen> createState() => _CourseTableScreenState();
}

class _CourseTableScreenState extends State<CourseTableScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  final List<String> _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  bool _isWeekView = false; // 是否为周视图

  @override
  void initState() {
    super.initState();
    // 不需要自动调用fetchCourses，因为CourseService构造函数已经加载了缓存
    // 如果用户需要刷新，可以在设置页面手动触发
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            title: const Text('课程表'),
            actions: [
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
              PopupMenuButton<int>(
                icon: Text('第${courseService.currentWeek}周'),
                onSelected: (week) {
                  courseService.setCurrentWeek(week);
                },
                itemBuilder: (context) => List.generate(
                  20,
                  (index) => PopupMenuItem(
                    value: index + 1,
                    child: Text('第${index + 1}周'),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => courseService.fetchCourses(),
              ),
            ],
          ),
          body: _isWeekView 
              ? _buildWeekView(courseService)
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
            controller: _pageController,
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
                  return CourseCard(course: courses[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 周视图（网格视图）
  Widget _buildWeekView(CourseService courseService) {
    const int maxSections = 12; // 最多12节课
    
    // 获取屏幕宽度并计算列宽
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 16.0; // 左右padding
    final availableWidth = screenWidth - padding;
    
    // 计算动态列宽：节次列占10%，其余平均分配给7天
    final sectionColumnWidth = availableWidth * 0.12;
    final dayColumnWidth = (availableWidth - sectionColumnWidth) / 7;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: padding / 2),
      child: Column(
        children: [
          // 表头
          Row(
            children: [
              // 左上角节次标题
              Container(
                width: sectionColumnWidth,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: const Center(
                  child: Text('节次', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              // 星期标题
              ..._weekdays.map((day) => Container(
                width: dayColumnWidth,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )),
            ],
          ),
          // 课程网格
          ...List.generate(maxSections, (sectionIndex) {
            final section = sectionIndex + 1;
            return Row(
              children: [
                // 节次列
                Container(
                  width: sectionColumnWidth,
                  height: 70,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Text('$section', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                // 每天的课程
                ...List.generate(7, (dayIndex) {
                  final weekday = dayIndex + 1;
                  final courses = courseService.getCoursesByWeekAndDay(
                    courseService.currentWeek,
                    weekday,
                  ).where((course) => 
                    section >= course.startSection && 
                    section <= course.endSection
                  ).toList();

                  return Container(
                    width: dayColumnWidth,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: courses.isNotEmpty
                        ? _buildWeekViewCourseCell(courses.first, section == courses.first.startSection)
                        : null,
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  // 周视图单个课程单元格
  Widget _buildWeekViewCourseCell(Course course, bool isFirstSection) {
    if (!isFirstSection) {
      // 不是起始节次，显示为延续（添加点击事件）
      return InkWell(
        onTap: () => _showCourseDetailDialog(course),
        child: Container(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        ),
      );
    }

    // 获取屏幕宽度，根据设备调整显示内容
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return InkWell(
      onTap: () => _showCourseDetailDialog(course),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 课程名称
            Text(
              course.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 9 : 10,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // 教师名称
            if (course.teacher.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: isSmallScreen ? 8 : 9,
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      course.teacher,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 7 : 8,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
            ],
            // 地点信息（小屏幕也显示，但更简洁）
            if (course.location.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: isSmallScreen ? 8 : 9,
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      _shortenLocation(course.location),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 7 : 8,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
            ],
            // 节次和时间
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: isSmallScreen ? 8 : 9,
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '${course.startSection}-${course.endSection}节',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 7 : 8,
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
        .replaceAll('中心校区-', '')
        .replaceAll('南岭校区-', '')
        .replaceAll('和平校区-', '')
        .replaceAll('朝阳校区-', '');
    return location;
  }
}
