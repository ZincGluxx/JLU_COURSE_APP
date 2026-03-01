// 吉林大学课程表应用测试

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jlu_course_app/main.dart';

void main() {
  testWidgets('应用基础组件测试', (WidgetTester tester) async {
    // 构建应用并触发一帧
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 验证底部导航栏存在
    expect(find.byType(NavigationBar), findsOneWidget);
    
    // 验证至少有一些文本显示
    expect(find.byType(Text), findsWidgets);
    
    // 验证有图标
    expect(find.byType(Icon), findsWidgets);
  });
}
