import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../models/course.dart';

/// WebView数据导入组件
/// 
/// 让用户在教务Web中浏览，从 HTML页面提取课程表数据
class WebViewDataImporter extends StatefulWidget {
  /// 初始URL（教务系统首页）
  final String initialUrl;
  
  /// 课程数据导入完成回调
  final Function(List<Course> courses)? onCoursesImported;
  
  const WebViewDataImporter({
    super.key,
    this.initialUrl = 'https://iedu.jlu.edu.cn/jwapp/sys/funauthapp/api/getAppConfig/jlukb.do',
    this.onCoursesImported,
  });

  @override
  State<WebViewDataImporter> createState() => _WebViewDataImporterState();
}

class _WebViewDataImporterState extends State<WebViewDataImporter> {
  late final WebViewController? _controller;
  bool _isLoading = true;
  String _currentUrl = '';
  bool _isImporting = false;
  String _pageType = 'unknown'; // 'course_table', 'unknown'
  
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeWebView();
    } else {
      _controller = null;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            await _detectPageType();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  /// 检测当前页面类型
  Future<void> _detectPageType() async {
    if (_controller == null) return;

    try {
      // 检测是否包含课表相关元素
      final hasCourseTable = await _controller!.runJavaScriptReturningResult(
        '''
        (function() {
          // 检查是否有课表相关的标识
          var hasCourseTable = document.querySelector('table.course-table') !== null ||
                               document.querySelector('#kbtable') !== null ||
                               document.body.innerHTML.includes('课程表') ||
                               document.body.innerHTML.includes('课表');
          return hasCourseTable;
        })();
        '''
      );

      setState(() {
        if (hasCourseTable.toString() == 'true') {
          _pageType = 'course_table';
        } else {
          _pageType = 'unknown';
        }
      });
    } catch (e) {
      print('检测页面类型失败: $e');
    }
  }

  /// 从HTML提取课程表数据
  Future<void> _extractCourseTable() async {
    if (_controller == null || _isImporting) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final result = await _controller!.runJavaScriptReturningResult(
        '''
        (function() {
          var courses = [];
          
          // 尝试多种可能的表格结构
          // 方法1: 查找标准课表格子
          var cells = document.querySelectorAll('td.course-cell, td[data-course], .kbcontent');
          
          if (cells.length > 0) {
            cells.forEach(function(cell, index) {
              // 提取课程信息
              var courseName = '';
              var teacher = '';
              var location = '';
              var weeks = '';
              var sections = '';
              
              // 从单元格文本中解析
              var text = cell.innerText || cell.textContent;
              var lines = text.split('\\n').filter(function(l) { return l.trim(); });
              
              if (lines.length > 0) {
                courseName = lines[0];
                for (var i = 1; i < lines.length; i++) {
                  var line = lines[i];
                  if (line.includes('周') && line.match(/\\d+/)) {
                    weeks = line;
                  } else if (line.includes('节')) {
                    sections = line;
                  } else if (line.match(/[A-Z]\\d+/)) {
                    location = line;
                  } else if (!teacher && line.length < 10) {
                    teacher = line;
                  }
                }
              }
              
              // 获取单元格位置（星期几、第几节）
              var weekday = 0;
              var section = 0;
              
              // 从data属性或位置推断
              if (cell.dataset.weekday) {
                weekday = parseInt(cell.dataset.weekday);
              }
              if (cell.dataset.section) {
                section = parseInt(cell.dataset.section);
              }
              
              // 如果没有data属性，从行列位置推断
              if (weekday === 0 || section === 0) {
                var row = cell.parentElement;
                var table = row.parentElement;
                var rowIndex = Array.from(table.children).indexOf(row);
                var colIndex = Array.from(row.children).indexOf(cell);
                
                if (rowIndex > 0) section = rowIndex;
                if (colIndex > 0) weekday = colIndex;
              }
              
              if (courseName && weekday > 0 && section > 0) {
                courses.push({
                  name: courseName,
                  teacher: teacher,
                  location: location,
                  weekday: weekday,
                  section: section,
                  weeks: weeks,
                  rawText: text
                });
              }
            });
          }
          
          // 方法2: 查找所有包含课程信息的div
          if (courses.length === 0) {
            var courseInfos = document.querySelectorAll('.course-info, .kb-item, [class*="course"]');
            courseInfos.forEach(function(elem) {
              var text = elem.innerText || elem.textContent;
              if (text && text.length > 5) {
                var lines = text.split('\\n').filter(function(l) { return l.trim(); });
                if (lines.length > 0) {
                  courses.push({
                    name: lines[0],
                    teacher: lines[1] || '',
                    location: lines[2] || '',
                    weekday: 0,
                    section: 0,
                    weeks: '',
                    rawText: text
                  });
                }
              }
            });
          }
          
          // 方法3: 返回整个页面HTML供Flutter端解析
          if (courses.length === 0) {
            return {
              success: false,
              html: document.body.innerHTML,
              message: '未找到标准课表结构，返回HTML供进一步解析'
            };
          }
          
          return {
            success: true,
            courses: courses,
            count: courses.length
          };
        })();
        '''
      );

      // 解析结果
      final jsonResult = jsonDecode(result.toString());
      
      if (jsonResult['success'] == true) {
        final coursesData = jsonResult['courses'] as List;
        final courses = _parseCourses(coursesData);
        
        if (courses.isNotEmpty) {
          widget.onCoursesImported?.call(courses);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ 成功导入 ${courses.length} 门课程'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          _showErrorDialog('未能解析到课程数据');
        }
      } else {
        // 显示HTML供用户检查
        _showHtmlDialog(jsonResult['html']);
      }
    } catch (e) {
      print('提取课程表失败: $e');
      _showErrorDialog('数据提取失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  /// 解析课程数据
  List<Course> _parseCourses(List coursesData) {
    List<Course> courses = [];
    
    for (var data in coursesData) {
      try {
        // 解析周次
        List<int> weeks = _parseWeeks(data['weeks'] ?? '');
        
        // 解析节次范围
        int startSection = data['section'] ?? 1;
        int endSection = startSection + 1; // 默认2节课
        
        if (data['sections'] != null) {
          var sectionMatch = RegExp(r'(\d+)-(\d+)').firstMatch(data['sections']);
          if (sectionMatch != null) {
            startSection = int.parse(sectionMatch.group(1)!);
            endSection = int.parse(sectionMatch.group(2)!);
          }
        }
        
        courses.add(Course(
          id: '${data['name']}_${data['weekday']}_$startSection',
          name: data['name'] ?? '未知课程',
          teacher: data['teacher'] ?? '',
          location: data['location'] ?? '',
          weekday: data['weekday'] ?? 1,
          startSection: startSection,
          endSection: endSection,
          weeks: weeks.isEmpty ? List.generate(16, (i) => i + 1) : weeks,
          description: data['rawText'],
        ));
      } catch (e) {
        print('解析课程失败: $e');
      }
    }
    
    return courses;
  }

  /// 解析周次字符串
  List<int> _parseWeeks(String weeksStr) {
    List<int> weeks = [];
    
    // 匹配 "1-16周" 或 "1,3,5周" 等格式
    var rangeMatch = RegExp(r'(\d+)-(\d+)').firstMatch(weeksStr);
    if (rangeMatch != null) {
      int start = int.parse(rangeMatch.group(1)!);
      int end = int.parse(rangeMatch.group(2)!);
      for (int i = start; i <= end; i++) {
        weeks.add(i);
      }
    } else {
      // 匹配逗号分隔的周次
      var matches = RegExp(r'\d+').allMatches(weeksStr);
      for (var match in matches) {
        weeks.add(int.parse(match.group(0)!));
      }
    }
    
    return weeks;
  }

  /// 从HTML提取成绩数据
  Future<void> _extractGrades() async {
    if (_controller == null || _isImporting) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final result = await _controller!.runJavaScriptReturningResult(
        '''
        (function() {
          var grades = [];
          
          // 查找成绩表格
          var rows = document.querySelectorAll('table tr, .grade-row');
          
          rows.forEach(function(row) {
            var cells = row.querySelectorAll('td');
            if (cells.length >= 4) {
              var courseName = cells[0].innerText.trim();
              var credit = cells[1].innerText.trim();
              var score = cells[2].innerText.trim();
              var gpa = cells[3].innerText.trim();
              
              if (courseName && score) {
                grades.push({
                  courseName: courseName,
                  credit: credit,
                  score: score,
                  gpa: gpa
                });
              }
            }
          });
          
          return {
            success: grades.length > 0,
            grades: grades,
            count: grades.length
          };
        })();
        '''
      );

      final jsonResult = jsonDecode(result.toString());
      
      if (jsonResult['success'] == true) {
        final gradesData = jsonResult['grades'] as List;
        final grades = _parseGrades(gradesData);
        
        if (grades.isNotEmpty) {
          widget.onGradesImported?.call(grades);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ 成功导入 ${grades.length} 门课程成绩'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        _showErrorDialog('未找到成绩数据');
      }
    } catch (e) {
      print('提取成绩失败: $e');
      _showErrorDialog('成绩提取失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  /// 解析成绩数据
  List<Grade> _parseGrades(List gradesData) {
    List<Grade> grades = [];
    
    for (var data in gradesData) {
      try {
        grades.add(Grade(
          courseId: '', // HTML中可能没有courseId
          courseName: data['courseName'],
          credit: data['credit'] ?? '0',
          score: data['score'],
          gradePoint: data['gpa'] ?? '0',
          semester: '', // HTML中可能需要从页面其他地方提取学期信息
        ));
      } catch (e) {
        print('解析成绩失败: $e');
      }
    }
    
    return grades;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入失败'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showHtmlDialog(String html) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('页面结构'),
        content: SingleChildScrollView(
          child: SelectableText(
            html,
            style: const TextStyle(fontSize: 10),
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

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Center(
        child: Text('Web平台不支持WebView'),
      );
    }

    return Column(
      children: [
        // 顶部工具栏
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // 返回按钮
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (await _controller!.canGoBack()) {
                    _controller!.goBack();
                  }
                },
                tooltip: '后退',
              ),
              // 前进按钮
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () async {
                  if (await _controller!.canGoForward()) {
                    _controller!.goForward();
                  }
                },
                tooltip: '前进',
              ),
              // 刷新按钮
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _controller!.reload();
                },
                tooltip: '刷新',
              ),
              const Spacer(),
              // 导入课表按钮
              if (_pageType == 'course_table')
                FilledButton.icon(
                  onPressed: _isImporting ? null : _extractCourseTable,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.event, size: 20),
                  label: const Text('导入课表'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        // URL显示
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          width: double.infinity,
          child: Text(
            _currentUrl,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 使用说明
        Container(
          color: Colors.blue.shade50,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '请在下方浏览器中登录教务系统，导航到课表页面，然后点击上方的导入按钮',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        // WebView
        Expanded(
          child: Stack(
            children: [
              if (_controller != null)
                WebViewWidget(controller: _controller!),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
