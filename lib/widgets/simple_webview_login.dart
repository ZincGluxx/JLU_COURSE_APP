import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/course.dart';

/// 简单的WebView登录和课表提取组件
/// 专门适配吉林大学教务系统 (i.jlu.edu.cn) 和校园VPN (vpn.jlu.edu.cn)
class SimpleWebViewLogin extends StatefulWidget {
  final Function(List<Course> courses) onCoursesExtracted;
  final bool isVpnMode;

  const SimpleWebViewLogin({
    super.key,
    required this.onCoursesExtracted,
    this.isVpnMode = false,
  });

  @override
  State<SimpleWebViewLogin> createState() => _SimpleWebViewLoginState();
}

class _SimpleWebViewLoginState extends State<SimpleWebViewLogin> {
  WebViewController? _controller;
  bool _isExtracting = false;
  double _loadingProgress = 0;
  String _currentUrl = '';

  @override
  Widget build(BuildContext context) {
    final loginTitle = widget.isVpnMode ? 'VPN登录并获取课表' : '登录并获取课表';
    final loginUrl = widget.isVpnMode ? 'vpn.jlu.edu.cn' : 'i.jlu.edu.cn';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loginTitle),
        actions: [
          // 提取按钮 - 根据模式检测不同的URL
          if (_shouldShowExtractButton())
            IconButton(
              icon: _isExtracting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download),
              onPressed: _isExtracting ? null : _extractCourseTable,
              tooltip: '点击这里获取课程',
            ),
        ],
      ),
      body: Column(
        children: [
          // 加载进度条
          if (_loadingProgress < 1.0)
            LinearProgressIndicator(value: _loadingProgress),
          // 使用说明
          Container(
            color: widget.isVpnMode ? Colors.orange[50] : Colors.blue[50],
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline, 
                      size: 18, 
                      color: widget.isVpnMode ? Colors.orange[700] : Colors.blue[700]
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '使用指南',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.isVpnMode ? Colors.orange[700] : Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isVpnMode
                      ? '1️⃣ 在下方网页中登录 $loginUrl\n'
                        '2️⃣ 通过VPN访问内网教务系统\n'  
                        '3️⃣ 找到"我的课表"页面\n'
                        '4️⃣ 看到课表后，点击右上角下载图标'
                      : '1️⃣ 在下方网页中登录 $loginUrl\n'
                        '2️⃣ 登录后会自动跳转到课表页面\n'
                        '3️⃣ 看到课表后，点击右上角下载图标',
                  style: TextStyle(
                    fontSize: 13, 
                    color: widget.isVpnMode ? Colors.orange[700] : Colors.blue[700]
                  ),
                ),
              ],
            ),
          ),
          // WebView
          Expanded(
            child: WebViewWidget(controller: _getController()),
          ),
        ],
      ),
    );
  }

  bool _shouldShowExtractButton() {
    if (widget.isVpnMode) {
      // VPN模式下检测更多可能的URL
      return _currentUrl.contains('jlu.edu.cn') || 
             _currentUrl.contains('vpn.jlu.edu.cn') ||
             _currentUrl.contains('iedu.jlu.edu.cn');
    } else {
      // 普通模式下检测原有的URL
      return _currentUrl.contains('i.jlu.edu.cn') || 
             _currentUrl.contains('iedu.jlu.edu.cn');
    }
  }

  WebViewController _getController() {
    if (_controller != null) return _controller!;

    final initialUrl = widget.isVpnMode 
        ? 'https://vpn.jlu.edu.cn' 
        : 'https://i.jlu.edu.cn';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _currentUrl = url;
              _loadingProgress = 0;
            });
          },
          onProgress: (progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _loadingProgress = 1.0;
              _currentUrl = url;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));

    return _controller!;
  }

  /// 提取课程表
  Future<void> _extractCourseTable() async {
    if (_controller == null || _isExtracting) return;

    setState(() {
      _isExtracting = true;
    });

    try {
      // 执行JavaScript提取课程数据
      final result = await _controller!.runJavaScriptReturningResult(
        '''
        (function() {
          var courses = [];
          
          // 查找吉大教务系统的课表元素
          var items = document.querySelectorAll('.mtt_arrange_item');
          
          console.log('[提取] 找到', items.length, '个课程元素');
          
          if (items.length === 0) {
            return {
              success: false,
              error: '未找到课表数据\\n请确保已经打开了"我的课表"页面',
              count: 0
            };
          }
          
          // 遍历每个课程元素
          items.forEach(function(item, idx) {
            try {
              // 1. 提取课程名称
              var nameEl = item.querySelector('.mtt_item_kcmc');
              if (!nameEl || !nameEl.childNodes[0]) {
                console.log('[课程', idx, '] 跳过：缺少课程名称');
                return;
              }
              
              var name = nameEl.childNodes[0].textContent.trim();
              if (!name) {
                console.log('[课程', idx, '] 跳过：课程名称为空');
                return;
              }
              
              // 2. 提取教师
              var teacherEl = item.querySelector('.mtt_item_jxbmc');
              var teacher = teacherEl ? teacherEl.textContent.trim() : '';
              
              // 3. 提取时间地点信息
              var roomEl = item.querySelector('.mtt_item_room');
              if (!roomEl) {
                console.log('[课程', idx, name, '] 跳过：缺少时间地点元素');
                return;
              }
              
              var roomText = roomEl.textContent.trim();
              
              // 4. 解析周次（"2-10周" -> [2,3,4,5,6,7,8,9,10]）
              var weeks = [];
              var weekMatch = roomText.match(/(\\d+)-(\\d+)周/);
              if (weekMatch) {
                var start = parseInt(weekMatch[1]);
                var end = parseInt(weekMatch[2]);
                for (var w = start; w <= end; w++) {
                  weeks.push(w);
                }
              } else {
                var singleMatch = roomText.match(/(\\d+)周/);
                if (singleMatch) {
                  weeks.push(parseInt(singleMatch[1]));
                }
              }
              
              if (weeks.length === 0) {
                console.log('[课程', idx, name, '] 跳过：周次解析失败，原文:', roomText);
                return;
              }
              
              // 5. 解析星期（"星期5" -> 5）
              var weekday = 0;
              var dayMatch = roomText.match(/星期(\\d+)/);
              if (dayMatch) {
                weekday = parseInt(dayMatch[1]);
              }
              
              if (!weekday || weekday < 1 || weekday > 7) {
                console.log('[课程', idx, name, '] 跳过：星期解析失败');
                return;
              }
              
              // 6. 解析节次（"第1节-第4节" -> startSection=1, sections=4）
              var startSection = 0;
              var sections = 1;
              var sectionMatch = roomText.match(/第(\\d+)节-第(\\d+)节/);
              if (sectionMatch) {
                startSection = parseInt(sectionMatch[1]);
                var endSection = parseInt(sectionMatch[2]);
                sections = endSection - startSection + 1;
              } else {
                var singleMatch = roomText.match(/第(\\d+)节/);
                if (singleMatch) {
                  startSection = parseInt(singleMatch[1]);
                  sections = 1;
                }
              }
              
              if (startSection < 1) {
                console.log('[课程', idx, name, '] 跳过：节次解析失败');
                return;
              }
              
              // 7. 解析地点（逗号分隔的第4部分）
              var location = '';
              var parts = roomText.split(',');
              if (parts.length >= 4) {
                location = parts[3].replace(/<[^>]+>/g, '').trim();
              }
              
              // 8. 构建课程对象
              var course = {
                name: name,
                teacher: teacher,
                location: location,
                weekday: weekday,
                startSection: startSection,
                sections: sections,
                weeks: weeks
              };
              
              courses.push(course);
              console.log('[课程', idx, '] ✅', name, '周次:', weeks.length, '星期:', weekday, '节次:', startSection, '-', (startSection + sections - 1));
              
            } catch (e) {
              console.error('[课程', idx, '] 解析失败:', e);
            }
          });
          
          console.log('[提取] 成功解析', courses.length, '/', items.length, '门课程');
          
          // 直接返回对象，不要JSON.stringify（WebView会自动转换）
          return {
            success: true,
            courses: courses,
            count: courses.length
          };
          
        })();
        '''
      );

      print('📥 JavaScript返回结果类型: ${result.runtimeType}');

      // 解析结果 - WebView可能返回String或Map
      dynamic jsonResult;
      
      if (result is String) {
        print('📥 结果是字符串，尝试JSON解析');
        try {
          jsonResult = jsonDecode(result);
        } catch (e) {
          print('❌ JSON解析失败: $e');
          throw Exception('JSON解析失败: $e');
        }
      } else if (result is Map) {
        print('📥 结果已经是Map对象');
        jsonResult = result;
      } else {
        print('❌ 未知的返回类型: ${result.runtimeType}');
        throw Exception('未知的JavaScript返回类型: ${result.runtimeType}');
      }
      
      print('✅ 解析成功，类型: ${jsonResult.runtimeType}');
      
      // 确保jsonResult是Map
      Map<String, dynamic> jsonMap;
      if (jsonResult is Map) {
        jsonMap = Map<String, dynamic>.from(jsonResult);
      } else {
        throw Exception('解析后的结果不是Map类型');
      }
      
      if (jsonMap['success'] == true) {
        final coursesList = jsonMap['courses'];
        
        print('📚 courses字段类型: ${coursesList.runtimeType}');
        
        if (coursesList == null || coursesList is! List || coursesList.isEmpty) {
          _showErrorDialog('未能提取到任何课程');
          return;
        }
        
        final courses = _parseCourses(coursesList);
        
        if (courses.isNotEmpty) {
          widget.onCoursesExtracted(courses);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ 成功提取 ${courses.length} 门课程'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // 延迟后返回
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) Navigator.pop(context, true);
            });
          }
        } else {
          _showErrorDialog('解析课程数据失败\n可能数据格式不正确');
        }
      } else {
        _showErrorDialog(jsonMap['error']?.toString() ?? '提取失败');
      }
      
    } catch (e, stackTrace) {
      print('❌ 提取课程表异常: $e');
      print('❌ 堆栈跟踪: $stackTrace');
      _showErrorDialog('提取失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExtracting = false;
        });
      }
    }
  }

  /// 解析课程数据
  List<Course> _parseCourses(List coursesData) {
    List<Course> courses = [];
    
    print('📊 开始解析 ${coursesData.length} 门课程数据');
    
    for (int i = 0; i < coursesData.length; i++) {
      try {
        var data = coursesData[i];
        
        print('📝 解析课程 $i: 类型=${data.runtimeType}');
        
        // 确保data是Map类型
        if (data is! Map) {
          print('❌ 课程 $i 数据不是Map类型，跳过');
          continue;
        }
        
        Map<String, dynamic> courseData = Map<String, dynamic>.from(data);
        
        print('   - name: ${courseData['name']}');
        print('   - weekday: ${courseData['weekday']}');
        print('   - weeks type: ${courseData['weeks'].runtimeType}');
        print('   - weeks: ${courseData['weeks']}');
        
        // 解析周次（数组格式）
        List<int> weeks = [];
        if (courseData['weeks'] is List) {
          weeks = (courseData['weeks'] as List).map((e) => (e as num).toInt()).toList();
        }
        
        if (weeks.isEmpty) {
          print('⚠️ 课程 ${courseData['name']} 周次为空，设置为1-16周');
          weeks = List.generate(16, (i) => i + 1);
        }
        
        // 解析节次
        int startSection = (courseData['startSection'] as num?)?.toInt() ?? 1;
        int sections = (courseData['sections'] as num?)?.toInt() ?? 2;
        int endSection = startSection + sections - 1;
        
        // 创建课程对象
        courses.add(Course(
          id: '${courseData['name']}_${courseData['weekday']}_$startSection',
          name: courseData['name'] ?? '未知课程',
          teacher: courseData['teacher'] ?? '',
          location: courseData['location'] ?? '',
          weekday: (courseData['weekday'] as num?)?.toInt() ?? 1,
          startSection: startSection,
          endSection: endSection,
          weeks: weeks,
          description: null,
        ));
        
        print('   ✅ 成功解析');
        
      } catch (e, stackTrace) {
        print('❌ 解析课程 $i 失败: $e');
        print('   堆栈: $stackTrace');
      }
    }
    
    print('✅ 总共成功解析 ${courses.length} 门课程');
    return courses;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提取失败'),
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
}
