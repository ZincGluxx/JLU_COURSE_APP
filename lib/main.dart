import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/course_edit_screen.dart';
import 'services/course_service.dart';
import 'services/widget_service.dart';
import 'widgets/webview_data_importer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化桌面小组件服务
  await WidgetService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CourseService()),
      ],
      child: MaterialApp(
        title: '吉林大学课程表',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0), // 吉大蓝
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0), // 吉大蓝
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system, // 跟随系统主题
        home: const HomeScreen(),
        routes: {
          '/course_edit': (context) => const CourseEditScreen(),
          '/webview_import': (context) => Scaffold(
            appBar: AppBar(
              title: const Text('导入课表'),
            ),
            body: Consumer<CourseService>(
              builder: (context, courseService, child) {
                return WebViewDataImporter(
                  onCoursesImported: (courses) async {
                    await courseService.setCourses(courses);
                    if (context.mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                );
              },
            ),
          ),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
