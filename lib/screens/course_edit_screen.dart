import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../services/course_service.dart';

class CourseEditScreen extends StatefulWidget {
  final Course? course; // 如果是null则表示新增课程
  
  const CourseEditScreen({super.key, this.course});

  @override
  State<CourseEditScreen> createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends State<CourseEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _teacherController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  
  int _selectedWeekday = 1;
  int _startSection = 1;
  int _endSection = 2;
  List<int> _selectedWeeks = [];
  bool _isAllWeeks = false;
  
  final List<String> _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course?.name ?? '');
    _teacherController = TextEditingController(text: widget.course?.teacher ?? '');
    _locationController = TextEditingController(text: widget.course?.location ?? '');
    _descriptionController = TextEditingController(text: widget.course?.description ?? '');
    
    if (widget.course != null) {
      _selectedWeekday = widget.course!.weekday;
      _startSection = widget.course!.startSection;
      _endSection = widget.course!.endSection;
      _selectedWeeks = List.from(widget.course!.weeks);
    } else {
      // 默认选择前16周
      _selectedWeeks = List.generate(16, (index) => index + 1);
      _isAllWeeks = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveCourse() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入课程名称')),
      );
      return;
    }

    if (_selectedWeeks.isEmpty && !_isAllWeeks) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择上课周次')),
      );
      return;
    }

    final courseService = Provider.of<CourseService>(context, listen: false);
    
    final course = Course(
      id: widget.course?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      teacher: _teacherController.text.trim(),
      location: _locationController.text.trim(),
      weekday: _selectedWeekday,
      startSection: _startSection,
      endSection: _endSection,
      weeks: _isAllWeeks ? List.generate(20, (index) => index + 1) : _selectedWeeks,
      description: _descriptionController.text.trim(),
    );

    if (widget.course == null) {
      courseService.addCustomCourse(course);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('课程添加成功')),
      );
    } else {
      courseService.updateCustomCourse(course);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('课程修改成功')),
      );
    }
    
    Navigator.pop(context);
  }

  void _deleteCourse() {
    if (widget.course == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定要删除课程 "${widget.course!.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final courseService = Provider.of<CourseService>(context, listen: false);
              courseService.deleteCustomCourse(widget.course!.id);
              Navigator.pop(context); // 关闭对话框
              Navigator.pop(context); // 返回课程表
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('课程删除成功')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course == null ? '添加课程' : '编辑课程'),
        actions: [
          if (widget.course != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCourse,
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCourse,
          ),
        ],
      ),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 课程名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '课程名称 *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // 任课教师
            TextFormField(
              controller: _teacherController,
              decoration: const InputDecoration(
                labelText: '任课教师',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // 上课地点
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '上课地点',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // 星期选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('上课时间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedWeekday,
                      decoration: const InputDecoration(
                        labelText: '星期',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(7, (index) => 
                        DropdownMenuItem(
                          value: index + 1,
                          child: Text(_weekdays[index]),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedWeekday = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 节次选择
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _startSection,
                            decoration: const InputDecoration(
                              labelText: '开始节次',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(12, (index) => 
                              DropdownMenuItem(
                                value: index + 1,
                                child: Text('第${index + 1}节'),
                              ),
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _startSection = value;
                                  if (_endSection < value) {
                                    _endSection = value;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _endSection,
                            decoration: const InputDecoration(
                              labelText: '结束节次',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(12, (index) => index + 1)
                                .where((section) => section >= _startSection)
                                .map((section) => DropdownMenuItem(
                                  value: section,
                                  child: Text('第${section}节'),
                                ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _endSection = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 周次选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('上课周次', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('全学期'),
                      subtitle: const Text('选择所有周次'),
                      value: _isAllWeeks,
                      onChanged: (value) {
                        setState(() {
                          _isAllWeeks = value;
                          if (value) {
                            _selectedWeeks = List.generate(20, (index) => index + 1);
                          }
                        });
                      },
                    ),
                    if (!_isAllWeeks) ...[
                      const SizedBox(height: 8),
                      const Text('选择具体周次：'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: List.generate(20, (index) {
                          final week = index + 1;
                          final isSelected = _selectedWeeks.contains(week);
                          return FilterChip(
                            label: Text('$week'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedWeeks.add(week);
                                  _selectedWeeks.sort();
                                } else {
                                  _selectedWeeks.remove(week);
                                }
                              });
                            },
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 备注
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}