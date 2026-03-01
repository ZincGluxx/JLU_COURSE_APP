import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../models/course.dart';

/// 简化的WebView登录组件
/// 
/// 用户登录 i.jlu.edu.cn，在课表页面自动提取数据
class SimpleWebViewLogin extends StatefulWidget {
  /// 课程数据提取完成回调
  final Function(List<Course> courses) onCoursesExtracted;
  
  const SimpleWebViewLogin({
    super.key,
    required this.onCoursesExtracted,
  });

  @override
  State<SimpleWebViewLogin> createState() => _SimpleWebViewLoginState();
}

class _SimpleWebViewLoginState extends State<SimpleWebViewLogin> {
  late final WebViewController? _controller;
  bool _isLoading = true;
  String _currentUrl = '';
  bool _isExtracting = false;
  
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
    // 直接加载 i.jlu.edu.cn
    final initialUrl = 'https://i.jlu.edu.cn';
    
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
            
            // 检测是否在课表页面
            await _checkCourseTablePage();
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }

  /// 检测是否在课表页面
  Future<void> _checkCourseTablePage() async {
    if (_controller == null || _isExtracting || !mounted) return;

    try {
      // 检查页面是否包含课表相关元素
      final hasCourseTable = await _controller!.runJavaScriptReturningResult(
        '''
        (function() {
          // 检查是否有课表
          var hasTable = document.querySelector('.kbcontent') !== null ||
                        document.querySelector('#kbtable') !== null ||
                        document.querySelector('table[id*="kb"]') !== null ||
                        document.body.innerHTML.includes('课表') ||
                        document.title.includes('课表');
          return hasTable;
        })();
        '''
      );

      if (hasCourseTable.toString() == 'true' && mounted) {
        // 显示提取按钮
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ 检测到课表页面，可以提取数据'),
            action: SnackBarAction(
              label: '提取',
              onPressed: _extractCourseTable,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('检测课表页面失败: $e');
    }
  }

  /// 从当前页面提取课表数据（带智能重试）
  Future<void> _extractCourseTable() async {
    if (_controller == null || _isExtracting || !mounted) return;

    setState(() {
      _isExtracting = true;
    });

    // 显示加载提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('正在提取课表数据...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }

    try {
      // 先等待页面加载完成（给动态内容一些加载时间）
      await Future.delayed(const Duration(seconds: 2));
      
      // 尝试提取，最多重试3次
      for (int attempt = 1; attempt <= 3; attempt++) {
        final result = await _attemptExtraction();
        
        if (result['success'] == true) {
          // 提取成功
          await _handleSuccessfulExtraction(result);
          return;
        } else if (result['debug']?['bodyIsEmpty'] == true && attempt < 3) {
          // 页面是动态加载的，等待更长时间后重试
          print('页面内容为空，等待3秒后重试 (尝试 $attempt/3)');
          await Future.delayed(const Duration(seconds: 3));
          continue;
        } else if (attempt == 3) {
          // 最后一次尝试失败
          await _handleFailedExtraction(result);
          return;
        }
      }
    } catch (e) {
      print('提取课程表失败: $e');
      _showErrorDialog('数据提取失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExtracting = false;
        });
      }
    }
  }

  /// 尝试提取数据
  Future<Map<String, dynamic>> _attemptExtraction() async {
    final result = await _controller!.runJavaScriptReturningResult(
        r'''
        (function() {
          var courses = [];
          
          // 方法1: 查找 .mtt_arrange_item (吉林大学教务系统专用)
          var mttItems = document.querySelectorAll('.mtt_arrange_item');
          
          if (mttItems.length > 0) {
            console.log('找到', mttItems.length, '个课程（.mtt_arrange_item）');
            
            mttItems.forEach(function(item) {
              try {
                // 提取课程名称
                var kcmcDiv = item.querySelector('.mtt_item_kcmc');
                if (!kcmcDiv) return;
                
                var courseName = kcmcDiv.childNodes[0] ? kcmcDiv.childNodes[0].textContent.trim() : '';
                if (!courseName) return;
                
                // 提取教师
                var teacherDiv = item.querySelector('.mtt_item_jxbmc');
                var teacher = teacherDiv ? teacherDiv.textContent.trim() : '';
                
                // 提取地点和时间信息
                var roomDiv = item.querySelector('.mtt_item_room');
                var roomText = roomDiv ? roomDiv.textContent.trim() : '';
                
                // 解析周次 (格式: "2-10周,星期5,第1节-第4节,地点")
                var weeks = '';
                var weekday = 0;
                var startSection = 0;
                var sections = 0;
                var location = '';
                
                if (roomText) {
                  // 解析周次 (如: "2-10周")
                  var weekMatch = roomText.match(/(\\d+)-(\\d+)周/);
                  if (weekMatch) {
                    weeks = weekMatch[1] + '-' + weekMatch[2];
                  }
                  
                  // 解析星期 (如: "星期5")
                  var dayMatch = roomText.match(/星期(\\d+)/);
                  if (dayMatch) {
                    weekday = parseInt(dayMatch[1]);
                  }
                  
                  // 解析节次 (如: "第1节-第4节")
                  var sectionMatch = roomText.match(/第(\\d+)节-第(\\d+)节/);
                  if (sectionMatch) {
                    startSection = parseInt(sectionMatch[1]);
                    var endSection = parseInt(sectionMatch[2]);
                    sections = endSection - startSection + 1;
                  }
                  
                  // 解析地点 (在最后一部分)
                  var locationMatch = roomText.match(/第\\d+节-第\\d+节,(.+?)\$/);
                  if (locationMatch) {
                    location = locationMatch[1].replace(/<[^>]+>/g, '').trim();
                  }
                }
                
                // 从父TD元素获取位置信息（作为备选）
                var parentTd = item.closest('td');
                if (parentTd && (!weekday || !startSection)) {
                  var dataWeek = parentTd.getAttribute('data-week');
                  var dataBeginUnit = parentTd.getAttribute('data-begin-unit');
                  var dataEndUnit = parentTd.getAttribute('data-end-unit');
                  
                  if (dataWeek && !weekday) {
                    weekday = parseInt(dataWeek);
                  }
                  if (dataBeginUnit && !startSection) {
                    startSection = parseInt(dataBeginUnit);
                  }
                  if (dataEndUnit && !sections) {
                    sections = parseInt(dataEndUnit) - startSection + 1;
                  }
                }
                
                // 只添加有效的课程
                if (courseName && weekday > 0 && startSection > 0) {
                  courses.push({
                    name: courseName,
                    teacher: teacher,
                    location: location,
                    weekday: weekday,
                    startSection: startSection,
                    sections: sections || 2,
                    weeks: weeks,
                    rawText: roomText
                  });
                }
              } catch (e) {
                console.error('解析课程失败:', e);
              }
            });
          }
          
          // 方法2: 查找 .kbcontent 课表格子（其他系统）
          if (courses.length === 0) {
            var kbcells = document.querySelectorAll('.kbcontent');
            
            if (kbcells.length > 0) {
              kbcells.forEach(function(cell) {
                var html = cell.innerHTML;
                var text = cell.innerText || cell.textContent;
                var lines = text.split('\\n').map(function(l) { return l.trim(); }).filter(function(l) { return l; });
                
                if (lines.length > 0) {
                  var courseName = lines[0];
                  var teacher = '';
                  var location = '';
                  var weeks = '';
                  var sections = '';
                  
                  // 解析文本
                  for (var i = 1; i < lines.length; i++) {
                    var line = lines[i];
                    if (line.includes('周')) {
                      weeks = line;
                    } else if (line.includes('节')) {
                      sections = line;
                    } else if (line.match(/教\\d+|楼|室/)) {
                      location = line;
                    } else if (!teacher && line.length < 10) {
                      teacher = line;
                    }
                  }
                  
                  // 获取位置信息（星期和节次）
                  var parentTd = cell.closest('td');
                  var weekday = 0;
                  var startSection = 0;
                  
                  if (parentTd) {
                    // 从 data 属性获取
                    var dataWeekday = parentTd.getAttribute('data-weekday');
                    var dataSection = parentTd.getAttribute('data-section');
                    
                    if (dataWeekday) weekday = parseInt(dataWeekday);
                    if (dataSection) startSection = parseInt(dataSection);
                    
                    // 如果没有 data 属性，从位置推断
                    if (!weekday || !startSection) {
                      var row = parentTd.parentElement;
                      var table = row.parentElement;
                      var rowIndex = Array.from(table.children).indexOf(row);
                      var colIndex = Array.from(row.children).indexOf(parentTd);
                      
                      if (rowIndex > 0) startSection = rowIndex;
                      if (colIndex > 0) weekday = colIndex;
                    }
                  }
                  
                  if (courseName && weekday > 0 && startSection > 0) {
                    courses.push({
                      name: courseName,
                      teacher: teacher,
                      location: location,
                      weekday: weekday,
                      startSection: startSection,
                      weeks: weeks,
                      sections: sections,
                      rawText: text
                    });
                  }
                }
              });
            }
          }
          
          // 方法3: 查找表格中的课程信息
          if (courses.length === 0) {
            var tables = document.querySelectorAll('table[id*="kb"], table.kb-table, #kbtable, table.wut_table');
            tables.forEach(function(table) {
              var rows = table.querySelectorAll('tr');
              rows.forEach(function(row, rowIndex) {
                if (rowIndex === 0) return; // 跳过表头
                
                var cells = row.querySelectorAll('td');
                cells.forEach(function(cell, colIndex) {
                  if (colIndex === 0) return; // 跳过第一列（节次列）
                  
                  var text = cell.innerText || cell.textContent;
                  if (text && text.trim() && text.length > 5) {
                    var lines = text.split('\\n').map(function(l) { return l.trim(); }).filter(function(l) { return l; });
                    if (lines.length > 0) {
                      courses.push({
                        name: lines[0],
                        teacher: lines[1] || '',
                        location: lines[2] || '',
                        weekday: colIndex,
                        startSection: rowIndex,
                        weeks: '',
                        sections: '',
                        rawText: text.trim()
                      });
                    }
                  }
                });
              });
            });
          }
          
          // 方法4: 尝试从JavaScript全局变量中获取（一些系统把数据存在JS变量里）
          if (courses.length === 0) {
            try {
              // 常见的课表数据变量名
              var possibleVars = ['kbData', 'courseData', 'scheduleData', 'tableData', 'kbList'];
              for (var varName of possibleVars) {
                if (window[varName] && Array.isArray(window[varName])) {
                  window[varName].forEach(function(item) {
                    if (item.name || item.courseName) {
                      courses.push({
                        name: item.name || item.courseName || item.kcmc || '',
                        teacher: item.teacher || item.teacherName || item.jsxm || '',
                        location: item.location || item.classroom || item.cdmc || '',
                        weekday: item.weekday || item.xqj || item.day || 1,
                        startSection: item.startSection || item.jc || item.section || 1,
                        weeks: item.weeks || item.zcd || '',
                        sections: item.sections || item.jcs || '',
                        rawText: JSON.stringify(item)
                      });
                    }
                  });
                  if (courses.length > 0) break;
                }
              }
            } catch (e) {
              console.log('检查JS变量失败:', e);
            }
          }
          
          // 调试信息：统计页面元素
          var debugInfo = {
            mttItemsCount: document.querySelectorAll('.mtt_arrange_item').length,
            kbcontentCount: document.querySelectorAll('.kbcontent').length,
            tablesCount: document.querySelectorAll('table').length,
            kbTablesCount: document.querySelectorAll('table[id*="kb"]').length,
            wutTableCount: document.querySelectorAll('table.wut_table').length,
            pageTitle: document.title,
            pageUrl: window.location.href,
            bodyText: document.body.innerText.substring(0, 500),
            bodyHtmlLength: document.body.innerHTML.length,
            bodyIsEmpty: document.body.innerHTML.trim().length < 100,
            readyState: document.readyState,
            hasJQuery: typeof window.jQuery !== 'undefined',
            foundMethods: []
          };
          
          // 记录使用了哪些提取方法
          if (courses.length > 0) {
            if (document.querySelectorAll('.mtt_arrange_item').length > 0) {
              debugInfo.foundMethods.push('.mtt_arrange_item (吉大教务系统)');
            }
            if (document.querySelectorAll('.kbcontent').length > 0) {
              debugInfo.foundMethods.push('.kbcontent');
            }
            if (document.querySelectorAll('table[id*="kb"]').length > 0) {
              debugInfo.foundMethods.push('table[id*="kb"]');
            }
          }
          
          if (courses.length === 0) {
            // 提供更详细的错误信息
            var errorMsg = '未找到课表数据';
            if (debugInfo.bodyIsEmpty) {
              errorMsg += '\n\n⚠️ 页面内容为空或未加载完成\n可能原因：\n1. 页面使用JavaScript动态加载\n2. 需要等待更长时间\n3. 需要先登录';
            }
            
            return {
              success: false,
              error: errorMsg,
              debug: debugInfo,
              html: document.body.innerHTML.substring(0, 3000)
            };
          }
          
          return {
            success: true,
            courses: courses,
            count: courses.length,
            debug: debugInfo
          };
        })();
        '''
    );
    
    return jsonDecode(result.toString());
  }

  /// 处理成功的提取
  Future<void> _handleSuccessfulExtraction(Map<String, dynamic> result) async {
    final coursesData = result['courses'] as List;
    final courses = _parseCourses(coursesData);
    
    if (courses.isNotEmpty) {
      widget.onCoursesExtracted(courses);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 成功提取 ${courses.length} 门课程'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // 延迟后返回
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } else {
      _showErrorDialog('未能解析到有效的课程数据');
    }
  }

  /// 处理失败的提取
  Future<void> _handleFailedExtraction(Map<String, dynamic> result) async {
    final debug = result['debug'];
    String debugText = '';
    String errorMsg = result['error'] ?? '未找到课表数据';
    
    if (debug != null) {
      debugText = '\n\n📊 调试信息：\n';
      debugText += '• .mtt_arrange_item: ${debug['mttItemsCount']}\n';
      debugText += '• .kbcontent 元素: ${debug['kbcontentCount']}\n';
      debugText += '• Table 元素: ${debug['tablesCount']}\n';
      debugText += '• 课表 Table: ${debug['kbTablesCount']}\n';
      if (debug['wutTableCount'] != null && debug['wutTableCount'] > 0) {
        debugText += '• wut_table: ${debug['wutTableCount']}\n';
      }
      debugText += '• 页面状态: ${debug['readyState']}\n';
      debugText += '• 页面标题: ${debug['pageTitle']}\n';
      
      // 检查是否是动态页面
      if (debug['bodyIsEmpty'] == true) {
        debugText += '\n⚠️ 页面内容为空或未加载！\n';
        debugText += '💡 建议方案：\n';
        debugText += '1. 使用JSON导入方式（更可靠）\n';
        debugText += '2. 或等待页面完全加载后重试\n';
        debugText += '3. 查看详细指南：设置 → 使用指南';
      }
      
      if (debug['foundMethods'] != null && (debug['foundMethods'] as List).isNotEmpty) {
        debugText += '\n✅ 使用方法: ${(debug['foundMethods'] as List).join(', ')}';
      }
    }
    
    _showErrorDialog(errorMsg + debugText);
  }

  /// 旧的提取方法（保持兼容）
  Future<void> _extractCourseTableOld() async {
    if (_controller == null || _isExtracting || !mounted) return;

    setState(() {
      _isExtracting = true;
    });

    try {
      final result = await _attemptExtraction();

      // 解析结果
      final jsonResult = result;
      
      if (jsonResult['success'] == true) {
        await _handleSuccessfulExtraction(jsonResult);
      } else {
        await _handleFailedExtraction(jsonResult);
      }
    } catch (e) {
      print('提取课程表失败: $e');
      _showErrorDialog('数据提取失败: $e');
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
    
    for (var data in coursesData) {
      try {
        // 解析周次
        List<int> weeks = _parseWeeks(data['weeks'] ?? '');
        if (weeks.isEmpty) {
          weeks = List.generate(16, (i) => i + 1); // 默认1-16周
        }
        
        // 解析节次范围
        int startSection = (data['startSection'] as num?)?.toInt() ?? 1;
        int endSection = startSection + 1;
        
        // 优先使用 sections 字段（数字类型，表示跨几节课）
        if (data['sections'] != null && data['sections'] is num && (data['sections'] as num) > 0) {
          endSection = startSection + (data['sections'] as num).toInt() - 1;
        } else if (data['sections'] != null && data['sections'] is String && data['sections'].isNotEmpty) {
          // 兼容旧格式：字符串格式的节次范围（如 "1-2"）
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
          weeks: weeks,
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
    
    if (weeksStr.isEmpty) return weeks;
    
    // 匹配 "1-16周"
    var rangeMatch = RegExp(r'(\d+)-(\d+)').firstMatch(weeksStr);
    if (rangeMatch != null) {
      int start = int.parse(rangeMatch.group(1)!);
      int end = int.parse(rangeMatch.group(2)!);
      for (int i = start; i <= end; i++) {
        weeks.add(i);
      }
      return weeks;
    }
    
    // 匹配逗号分隔的周次
    var matches = RegExp(r'\d+').allMatches(weeksStr);
    for (var match in matches) {
      weeks.add(int.parse(match.group(0)!));
    }
    
    return weeks;
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

  /// 显示页面调试信息
  Future<void> _showPageDebugInfo() async {
    if (_controller == null) return;

    try {
      final result = await _controller!.runJavaScriptReturningResult(
        '''
        (function() {
          // 收集页面信息
          var info = {
            title: document.title,
            url: window.location.href,
            kbcontentCount: document.querySelectorAll('.kbcontent').length,
            tablesCount: document.querySelectorAll('table').length,
            kbTablesCount: document.querySelectorAll('table[id*="kb"]').length,
            bodyTextPreview: document.body.innerText.substring(0, 300),
            htmlPreview: document.body.innerHTML.substring(0, 2000)
          };
          
          // 查找可能的课表元素
          var possibleElements = [];
          
          // 检查 .kbcontent
          var kbcells = document.querySelectorAll('.kbcontent');
          if (kbcells.length > 0) {
            possibleElements.push('.kbcontent: ' + kbcells.length + ' 个');
            if (kbcells.length > 0) {
              info.sampleKbcontent = kbcells[0].innerText.substring(0, 200);
            }
          }
          
          // 检查 table
          var tables = document.querySelectorAll('table[id*="kb"]');
          if (tables.length > 0) {
            possibleElements.push('table[id*="kb"]: ' + tables.length + ' 个');
          }
          
          info.possibleElements = possibleElements.join(', ');
          
          return JSON.stringify(info);
        })();
        '''
      );

      final info = jsonDecode(result.toString());
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.blue),
              SizedBox(width: 8),
              Text('页面调试信息'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDebugItem('📄 页面标题', info['title'] ?? '无'),
                _buildDebugItem('🔗 当前URL', info['url'] ?? '无'),
                const Divider(),
                const Text('课表元素统计:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDebugItem('.kbcontent', '${info['kbcontentCount']} 个'),
                _buildDebugItem('table', '${info['tablesCount']} 个'),
                _buildDebugItem('table[id*="kb"]', '${info['kbTablesCount']} 个'),
                if (info['possibleElements']?.toString().isNotEmpty ?? false) ...[
                  const Divider(),
                  _buildDebugItem('✅ 找到', info['possibleElements']),
                ],
                if (info['sampleKbcontent'] != null) ...[
                  const Divider(),
                  const Text('示例内容:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      info['sampleKbcontent'].toString(),
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ],
                const Divider(),
                const Text('页面文本预览:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    info['bodyTextPreview']?.toString() ?? '无内容',
                    style: const TextStyle(fontSize: 11),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // 复制HTML到剪贴板
                final html = info['htmlPreview']?.toString() ?? '';
                if (html.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('HTML已复制（前2000字符）')),
                  );
                }
              },
              child: const Text('复制HTML'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog('获取调试信息失败: $e');
    }
  }

  Widget _buildDebugItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.blue),
            ),
          ],
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('登录并获取课表'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 调试按钮
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: _showPageDebugInfo,
            tooltip: '查看页面信息',
          ),
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller?.reload();
            },
            tooltip: '刷新',
          ),
          // 手动提取按钮
          IconButton(
            icon: _isExtracting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onPressed: _isExtracting ? null : _extractCourseTable,
            tooltip: '提取课表',
          ),
        ],
      ),
      body: Column(
        children: [
          // 使用说明
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '使用步骤',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. 在下方登录 i.jlu.edu.cn\n'
                  '2. 导航到"我的课表"页面\n'
                  '3. 等待页面加载完成\n'
                  '4. 点击右上角下载图标提取数据',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
          // URL显示
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            width: double.infinity,
            child: Row(
              children: [
                Icon(Icons.link, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentUrl.isEmpty ? '正在加载...' : _currentUrl,
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
