import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/simple_webview_login.dart';
import '../services/course_service.dart';
import '../models/course.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入课表'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                '欢迎使用\n吉林大学课程表',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '简单三步获取您的课表',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () async {
                  final courseService =
                      Provider.of<CourseService>(context, listen: false);

                  // 跳转到 WebView，课程提取后透传回来
                  final courses = await Navigator.push<List<Course>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SimpleWebViewLogin(
                        onCoursesExtracted: (c) => Navigator.pop(context, c),
                      ),
                    ),
                  );

                  if (courses != null && courses.isNotEmpty && context.mounted) {
                    final saved = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => _SemesterSaveDialog(
                        courseService: courseService,
                        courses: courses,
                      ),
                    );
                    if (saved == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('登录并获取课表'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          '使用说明',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1️⃣ 登录 i.jlu.edu.cn\n'
                      '2️⃣ 找到并打开"我的课表"\n'
                      '3️⃣ 点击右上角下载按钮',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 学期保存对话框 ────────────────────────────────────────────────────────────

class _SemesterSaveDialog extends StatefulWidget {
  final CourseService courseService;
  final List<Course> courses;

  const _SemesterSaveDialog({
    required this.courseService,
    required this.courses,
  });

  @override
  State<_SemesterSaveDialog> createState() => _SemesterSaveDialogState();
}

class _SemesterSaveDialogState extends State<_SemesterSaveDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String? _error;

  static final _semesterRegex = RegExp(r'^\d{4}-\d{4}-[12]$');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: widget.courseService.currentSemester);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(String s) {
    final p = s.split('-');
    return p.length >= 3 ? '${p[0]}-${p[1]}学年第${p[2]}学期' : s;
  }

  Future<void> _save() async {
    final semester = _controller.text.trim();
    if (!_semesterRegex.hasMatch(semester)) {
      setState(() => _error = '格式应为 YYYY-YYYY-N，例如 2025-2026-2');
      return;
    }
    setState(() { _isSaving = true; _error = null; });

    try {
      await widget.courseService.saveCoursesForSemester(semester, widget.courses);
    } catch (e) {
      if (mounted) setState(() { _isSaving = false; _error = '保存失败: $e'; });
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, true); // 关闭对话框，返回 true

    // 若保存的是新学期，询问是否立即切换
    if (semester != widget.courseService.currentSemester) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('保存成功'),
          content: Text(
            '课表已保存为「${_fmt(semester)}」\n'
            '当前仍在「${_fmt(widget.courseService.currentSemester)}」\n\n'
            '是否立即切换到新学期？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('稍后切换'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await widget.courseService.switchSemester(semester);
              },
              child: const Text('立即切换'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.courseService.availableSemesters;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.save_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('保存课表'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '已提取 ${widget.courses.length} 门课程',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            const Text('请输入学期标识'),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '例如 2025-2026-2',
                border: const OutlineInputBorder(),
                errorText: _error,
                helperText: '格式：开始年-结束年-学期（1上/2下）',
                isDense: true,
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (available.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '已有学期（点击填入）',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: available.map((s) {
                  final isCurrent = s == widget.courseService.currentSemester;
                  return ActionChip(
                    label: Text(_fmt(s), style: const TextStyle(fontSize: 11)),
                    backgroundColor: isCurrent
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    onPressed: () {
                      _controller.text = s;
                      setState(() => _error = null);
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}
