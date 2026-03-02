import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: '显示设置'),
          Consumer<CourseService>(
            builder: (context, courseService, child) {
              final startDate = courseService.semesterStartDate;
              final dateDisplay = startDate != null
                  ? '${startDate.year}年${startDate.month.toString().padLeft(2, '0')}月'
                    '${startDate.day.toString().padLeft(2, '0')}日'
                  : '暂未设置';
              return ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('开学日期'),
                subtitle: Text(
                  startDate != null
                      ? '$dateDisplay（当前第${courseService.currentWeek}周）'
                      : '点击设置开学日期，自动计算周次',
                ),
                trailing: const Icon(Icons.edit_calendar, size: 20),
                onTap: () async {
                  final now = DateTime.now();
                  final initial = startDate ??
                      now.subtract(Duration(days: now.weekday - 1));
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    selectableDayPredicate: (date) =>
                        date.weekday == DateTime.monday,
                    helpText: '选择开学日期（仅可选星期一）',
                  );
                  if (picked != null && context.mounted) {
                    try {
                      await courseService.setSemesterStartDate(picked);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('设置失败: $e')),
                        );
                      }
                    }
                  }
                },
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: '数据管理'),
          // 导入新学期课表 - 展开样式
          const _ImportCoursesSection(),

          // 清除所有数据
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('清除所有数据'),
            subtitle: const Text('删除所有课表和缓存'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('清除数据'),
                    ],
                  ),
                  content: const Text('此操作将删除所有课程数据，无法恢复！'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('确定删除'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true && context.mounted) {
                final courseService = Provider.of<CourseService>(context, listen: false);
                await courseService.clearCourses();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ 数据已清除'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          const Divider(),
          const _SectionHeader(title: '学期管理'),
          Consumer<CourseService>(
            builder: (context, courseService, child) {
              final semesters = courseService.availableSemesters;
              if (semesters.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    '暂无已保存的课表，请先导入课表。',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              String fmt(String s) {
                final p = s.split('-');
                return p.length >= 3 ? '${p[0]}-${p[1]}学年第${p[2]}学期' : s;
              }

              return Column(
                children: semesters.map((s) {
                  final isCurrent = s == courseService.currentSemester;
                  return ListTile(
                    leading: Icon(
                      isCurrent ? Icons.event_available : Icons.event_note,
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      fmt(s),
                      style: isCurrent
                          ? TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                    subtitle: isCurrent ? const Text('当前学期') : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isCurrent)
                          TextButton(
                            onPressed: () async {
                              await courseService.switchSemester(s);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('已切换到 ${fmt(s)}')),
                                );
                              }
                            },
                            child: const Text('切换'),
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: isCurrent ? Colors.grey : Colors.red,
                          ),
                          tooltip: isCurrent ? '无法删除当前学期' : '删除该学期课表',
                          onPressed: isCurrent
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Row(
                                        children: [
                                          Icon(Icons.warning, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text('删除课表'),
                                        ],
                                      ),
                                      content: Text(
                                          '确定删除「${fmt(s)}」的课表？\n此操作不可恢复。'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: TextButton.styleFrom(
                                              foregroundColor: Colors.red),
                                          child: const Text('删除'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && context.mounted) {
                                    await courseService.deleteSemester(s);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text('已删除 ${fmt(s)}')),
                                      );
                                    }
                                  }
                                },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: '关于'),
          ListTile(
            title: const Text('应用名称'),
            subtitle: const Text('吉林大学课程表'),
          ),
          ListTile(
            title: const Text('版本'),
            subtitle: const Text('1.1.0'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('作者'),
            subtitle: const Text('ZincGlux'),
          ),
          ListTile(
            leading: const Icon(Icons.balance),
            title: const Text('开源协议'),
            subtitle: const Text('GNU General Public License v3.0'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.balance),
                      SizedBox(width: 8),
                      Text('GPL v3'),
                    ],
                  ),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Copyright (C) 2026  ZincGlux\n\n'
                      'This program is free software: you can redistribute it and/or modify '
                      'it under the terms of the GNU General Public License as published by '
                      'the Free Software Foundation, either version 3 of the License, or '
                      '(at your option) any later version.\n\n'
                      'This program is distributed in the hope that it will be useful, '
                      'but WITHOUT ANY WARRANTY; without even the implied warranty of '
                      'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the '
                      'GNU General Public License for more details.\n\n'
                      'You should have received a copy of the GNU General Public License '
                      'along with this program. If not, see https://www.gnu.org/licenses/',
                      style: TextStyle(fontSize: 13, height: 1.6),
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
            },
          ),
          ListTile(
            title: const Text('使用说明'),
            subtitle: const Text('点击查看详细说明'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('使用说明'),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '获取课表',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1️⃣ 点击"导入课表"\n'
                          '2️⃣ 在浏览器中登录 i.jlu.edu.cn\n'
                          '3️⃣ 找到并打开"我的课表"\n'
                          '4️⃣ 点击右上角下载按钮提取数据\n',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '查看课表',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• 日视图：左右滑动切换星期\n'
                          '• 周视图：点击顶部切换按钮\n'
                          '• 课程详情：点击课程格子查看详细信息\n'
                          '• 周次计算：在设置中设置开学日期后自动计算',
                          style: TextStyle(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('知道了'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ImportCoursesSection extends StatefulWidget {
  const _ImportCoursesSection();

  @override
  State<_ImportCoursesSection> createState() => _ImportCoursesSectionState();
}

class _ImportCoursesSectionState extends State<_ImportCoursesSection> {
  bool _isExpanded = false;

  Future<void> _handleLogin(BuildContext context, {required bool isVpn}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(isVpnMode: isVpn),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 课表已更新')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.download_rounded, color: Colors.teal),
          title: const Text('导入课表'),
          subtitle: const Text('选择登录方式并导入课程数据'),
          trailing: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
          ),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        if (_isExpanded) ...[
          Padding(
            padding: const EdgeInsets.only(left: 56, right: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.web, color: Colors.blue),
                  title: const Text('普通登录'),
                  subtitle: const Text('通过 i.jlu.edu.cn 登录'),
                  onTap: () => _handleLogin(context, isVpn: false),
                  dense: true,
                ),
                ListTile(
                  leading: const Icon(Icons.vpn_key, color: Colors.orange),
                  title: const Text('VPN登录'),
                  subtitle: const Text('通过 vpn.jlu.edu.cn 登录'),
                  onTap: () => _handleLogin(context, isVpn: true),
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
