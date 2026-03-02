import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';

class SemesterSwitchDialog extends StatefulWidget {
  const SemesterSwitchDialog({super.key});

  @override
  State<SemesterSwitchDialog> createState() => _SemesterSwitchDialogState();
}

class _SemesterSwitchDialogState extends State<SemesterSwitchDialog> {
  String? _selectedSemester;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseService>(
      builder: (context, courseService, child) {
        final currentSemester = courseService.currentSemester;
        final availableSemesters = courseService.availableSemesters;
        
        // 默认选择当前学期
        _selectedSemester ??= currentSemester;

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('学期切换'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择要切换到的学期：',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ...availableSemesters.map((semester) {
                final semesterName = _formatSemesterName(semester);
                final isCurrentSemester = semester == currentSemester;
                
                return Card(
                  elevation: isCurrentSemester ? 4 : 1,
                  color: isCurrentSemester 
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Theme.of(context).cardColor,
                  child: RadioListTile<String>(
                    title: Text(
                      semesterName,
                      style: TextStyle(
                        fontWeight: isCurrentSemester ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentSemester 
                            ? Theme.of(context).primaryColor 
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: isCurrentSemester 
                        ? Text(
                            '当前学期', 
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          )
                        : null,
                    value: semester,
                    groupValue: _selectedSemester,
                    onChanged: _isLoading ? null : (value) {
                      setState(() {
                        _selectedSemester = value;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                );
              }).toList(),
              if (availableSemesters.length <= 1)
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline, 
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '只有一个学期数据\\n请通过"导入新课表"添加更多学期',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            if (availableSemesters.length > 1)
              FilledButton(
                onPressed: _isLoading || _selectedSemester == currentSemester 
                    ? null 
                    : _switchSemester,
                child: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('切换'),
              ),

          ],
        );
      },
    );
  }

  // 格式化学期名称显示
  String _formatSemesterName(String semester) {
    // 将 "2025-2026-2" 转换为 "2025-2026学年第2学期"
    final parts = semester.split('-');
    if (parts.length >= 3) {
      return '${parts[0]}-${parts[1]}学年第${parts[2]}学期';
    }
    return semester;
  }

  // 切换学期
  Future<void> _switchSemester() async {
    if (_selectedSemester == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final courseService = Provider.of<CourseService>(context, listen: false);
      await courseService.switchSemester(_selectedSemester!);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已切换到${_formatSemesterName(_selectedSemester!)}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('切换学期失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// 显示学期切换对话框的便捷方法
void showSemesterSwitchDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const SemesterSwitchDialog(),
  );
}