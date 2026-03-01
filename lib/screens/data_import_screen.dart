import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/webview_data_importer.dart';
import '../services/course_service.dart';
import '../models/course.dart';

/// 数据导入页面
/// 
/// 使用WebView让用户在教务系统中浏览并导入课表数据
class DataImportScreen extends StatefulWidget {
  const DataImportScreen({super.key});

  @override
  State<DataImportScreen> createState() => _DataImportScreenState();
}

class _DataImportScreenState extends State<DataImportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入课表'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: WebViewDataImporter(
        onCoursesImported: (courses) {
          _handleCoursesImported(courses);
        },
      ),
    );
  }

  /// 处理课程导入
  void _handleCoursesImported(List<Course> courses) {
    final courseService = Provider.of<CourseService>(context, listen: false);
    
    // 保存课程到本地
    courseService.saveCourses(courses);
    
    // 显示导入成功对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
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
            Text('已成功导入 ${courses.length} 门课程'),
            const SizedBox(height: 12),
            const Text(
              '课程数据已保存到本地，您可以返回主页查看课程表。',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
              Navigator.pop(context); // 返回主页
            },
            child: const Text('返回主页'),
          ),
        ],
      ),
    );
  }
}
