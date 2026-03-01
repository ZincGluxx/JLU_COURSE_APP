import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/course_service.dart';
import '../models/course.dart';
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
          // 导入课表JSON
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.green),
            title: const Text('导入课表JSON'),
            subtitle: const Text('从浏览器控制台获取的JSON数据'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showImportJsonDialog(context),
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
            subtitle: const Text('2.0.0 (简化版)'),
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

/// 显示导入JSON对话框
void _showImportJsonDialog(BuildContext context) {
  final TextEditingController jsonController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.upload_file, color: Colors.green),
          SizedBox(width: 8),
          Text('导入课表JSON'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '粘贴从浏览器控制台获取的JSON数据',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 12),
            TextField(
              controller: jsonController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: '[\n  {\n    "name": "课程名",\n    ...\n  }\n]',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 如何获取JSON数据？',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1. 电脑浏览器打开课表页面\n'
                    '2. 按F12打开控制台\n'
                    '3. 运行提取脚本\n'
                    '4. 复制生成的JSON',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _showDetailedGuide(context);
                    },
                    child: Text(
                      '📖 查看完整指南',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            final jsonText = jsonController.text.trim();
            if (jsonText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('请输入JSON数据')),
              );
              return;
            }
            
            Navigator.pop(context);
            await _importCoursesFromJson(context, jsonText);
          },
          child: Text('导入'),
        ),
      ],
    ),
  );
}

/// 从JSON导入课程
Future<void> _importCoursesFromJson(BuildContext context, String jsonText) async {
  try {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在导入课程...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    // 解析JSON
    final List<dynamic> jsonList = jsonDecode(jsonText);
    final List<Course> courses = [];
    
    for (var item in jsonList) {
      if (item is! Map<String, dynamic>) continue;
      
      try {
        final course = Course(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + courses.length.toString(),
          name: item['name']?.toString() ?? '未知课程',
          teacher: item['teacher']?.toString() ?? '',
          location: item['location']?.toString() ?? '',
          weekday: (item['weekday'] is int) ? item['weekday'] : int.tryParse(item['weekday']?.toString() ?? '1') ?? 1,
          startSection: (item['startSection'] is int) ? item['startSection'] : int.tryParse(item['startSection']?.toString() ?? '1') ?? 1,
          endSection: (item['sections'] is int) 
              ? ((item['startSection'] is int ? item['startSection'] : int.tryParse(item['startSection']?.toString() ?? '1') ?? 1) + item['sections'] - 1)
              : (item['endSection'] is int ? item['endSection'] : int.tryParse(item['endSection']?.toString() ?? '2') ?? 2),
          weeks: (item['weeks'] is List) 
              ? (item['weeks'] as List).map((w) => w is int ? w : int.tryParse(w?.toString() ?? '1') ?? 1).toList()
              : List.generate(16, (i) => i + 1),
        );
        courses.add(course);
      } catch (e) {
        print('解析课程失败: $e, 数据: $item');
      }
    }
    
    if (courses.isEmpty) {
      if (context.mounted) Navigator.pop(context); // 关闭加载对话框
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('导入失败'),
              ],
            ),
            content: Text('未能解析到有效的课程数据\n\n请检查JSON格式是否正确'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('确定'),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    // 保存课程
    final courseService = Provider.of<CourseService>(context, listen: false);
    await courseService.saveCourses(courses);
    
    if (context.mounted) Navigator.pop(context); // 关闭加载对话框
    
    // 显示成功消息
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('导入成功'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ 成功导入 ${courses.length} 门课程'),
              SizedBox(height: 12),
              Text(
                '已添加到课程表中，可以在主页查看',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('确定'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      // 尝试关闭加载对话框
      Navigator.of(context, rootNavigator: true).pop();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('导入失败'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('解析JSON数据失败'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '错误: $e',
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              SizedBox(height: 12),
              Text(
                '请检查：\n'
                '1. JSON格式是否正确\n'
                '2. 是否复制了完整的数据\n'
                '3. 数据是否包含必需字段',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('确定'),
            ),
          ],
        ),
      );
    }
  }
}

/// 显示详细指南
void _showDetailedGuide(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.help_outline, color: Colors.blue),
          SizedBox(width: 8),
          Text('JSON导入指南'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '完整步骤：',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 12),
            _buildGuideStep('1', '在电脑浏览器打开 i.jlu.edu.cn'),
            _buildGuideStep('2', '登录并进入"我的课表"页面'),
            _buildGuideStep('3', '按 F12 打开浏览器控制台'),
            _buildGuideStep('4', '点击 Console (控制台) 标签'),
            _buildGuideStep('5', '粘贴提取脚本并按回车运行'),
            _buildGuideStep('6', 'JSON数据会自动复制到剪贴板'),
            _buildGuideStep('7', '在此应用中粘贴并导入'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📄 完整提取脚本',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '请查看项目中的文件：\nGET_COURSE_DATA_NEW.md',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('知道了'),
        ),
      ],
    ),
  );
}

Widget _buildGuideStep(String number, String text) {
  return Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ),
      ],
    ),
  );
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
