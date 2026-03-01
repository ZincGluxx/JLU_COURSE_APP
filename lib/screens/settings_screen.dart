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
              return ListTile(
                title: const Text('当前周次'),
                subtitle: Text('第${courseService.currentWeek}周'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final result = await showDialog<int>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('选择当前周次'),
                      children: List.generate(20, (index) {
                        final week = index + 1;
                        return SimpleDialogOption(
                          child: Text('第$week周'),
                          onPressed: () => Navigator.pop(context, week),
                        );
                      }),
                    ),
                  );
                  
                  if (result != null) {
                    courseService.setCurrentWeek(result);
                  }
                },
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: '数据管理'),
          // 重新获取课表
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.blue),
            title: const Text('重新获取课表'),
            subtitle: const Text('登录并重新导入课程数据'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('重新获取课表'),
                  content: const Text('将清除现有课表数据并重新登录获取'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true && context.mounted) {
                // 跳转到登录页面
                final courseService = Provider.of<CourseService>(context, listen: false);
                courseService.clearCourses(); // 清除现有数据
                
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
                
                if (result == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ 课表已更新')),
                  );
                }
              }
            },
          ),

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
          const _SectionHeader(title: '关于'),
          ListTile(
            title: const Text('应用名称'),
            subtitle: const Text('吉林大学课程表'),
          ),
          ListTile(
            title: const Text('版本'),
            subtitle: const Text('1.0.0'),
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
                          '1️⃣ 点击"重新获取课表"\n'
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
                          '• 调整周次：在设置中修改当前周次',
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
