// API service imports removed - use jlu_api_service.dart instead
import '../models/course.dart';
import '../models/grade.dart';

class ApiService {
  // TODO: 替换为吉林大学实际的API地址
  static const String baseUrl = 'https://your-jlu-api.com';
  
  // 这里使用模拟数据，等待用户提供真实API后替换
  
  // 获取课程表
  Future<List<Course>> getCourses() async {
    // TODO: 替换为真实API调用
    // final response = await http.get(Uri.parse('$baseUrl/courses'));
    // if (response.statusCode == 200) {
    //   List<dynamic> data = jsonDecode(response.body);
    //   return data.map((json) => Course.fromJson(json)).toList();
    // }
    
    // 模拟数据
    await Future.delayed(const Duration(seconds: 1));
    return _getMockCourses();
  }

  // 获取成绩
  Future<List<Grade>> getGrades() async {
    // TODO: 替换为真实API调用
    // final response = await http.get(Uri.parse('$baseUrl/grades'));
    // if (response.statusCode == 200) {
    //   List<dynamic> data = jsonDecode(response.body);
    //   return data.map((json) => Grade.fromJson(json)).toList();
    // }
    
    // 模拟数据
    await Future.delayed(const Duration(seconds: 1));
    return _getMockGrades();
  }

  // 模拟课程数据
  List<Course> _getMockCourses() {
    return [
      Course(
        id: '1',
        name: '高等数学',
        teacher: '张教授',
        location: '中心校区-东荣大厦A座201',
        weekday: 1,
        startSection: 1,
        endSection: 2,
        weeks: List.generate(16, (i) => i + 1),
        description: '必修课',
      ),
      Course(
        id: '2',
        name: '大学英语',
        teacher: '李老师',
        location: '中心校区-东荣大厦B座305',
        weekday: 1,
        startSection: 3,
        endSection: 4,
        weeks: List.generate(16, (i) => i + 1),
        description: '必修课',
      ),
      Course(
        id: '3',
        name: '计算机网络',
        teacher: '王教授',
        location: '南岭校区-计算机楼302',
        weekday: 2,
        startSection: 5,
        endSection: 6,
        weeks: List.generate(16, (i) => i + 1),
        description: '专业课',
      ),
      Course(
        id: '4',
        name: '数据结构',
        teacher: '赵老师',
        location: '南岭校区-计算机楼401',
        weekday: 3,
        startSection: 1,
        endSection: 3,
        weeks: List.generate(16, (i) => i + 1),
        description: '专业课',
      ),
      Course(
        id: '5',
        name: '大学物理',
        teacher: '刘教授',
        location: '中心校区-物理楼201',
        weekday: 4,
        startSection: 3,
        endSection: 4,
        weeks: List.generate(16, (i) => i + 1),
        description: '必修课',
      ),
      Course(
        id: '6',
        name: '思想政治',
        teacher: '陈老师',
        location: '中心校区-文科楼103',
        weekday: 5,
        startSection: 1,
        endSection: 2,
        weeks: [1, 3, 5, 7, 9, 11, 13, 15],
        description: '公共课',
      ),
    ];
  }

  // 模拟成绩数据
  List<Grade> _getMockGrades() {
    return [
      Grade(
        courseId: '1',
        courseName: '高等数学(上)',
        credit: '5.0',
        score: '92',
        gradePoint: '4.2',
        semester: '2024-2025学年第一学期',
        examType: '期末考试',
      ),
      Grade(
        courseId: '2',
        courseName: '大学英语(1)',
        credit: '3.0',
        score: '88',
        gradePoint: '3.8',
        semester: '2024-2025学年第一学期',
        examType: '期末考试',
      ),
      Grade(
        courseId: '3',
        courseName: '程序设计基础',
        credit: '4.0',
        score: '95',
        gradePoint: '4.5',
        semester: '2024-2025学年第一学期',
        examType: '期末考试',
      ),
      Grade(
        courseId: '4',
        courseName: '线性代数',
        credit: '3.0',
        score: '85',
        gradePoint: '3.5',
        semester: '2024-2025学年第一学期',
        examType: '期末考试',
      ),
    ];
  }
}
