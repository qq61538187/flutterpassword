// FlutterPassword 组件测试

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('基础组件测试', (WidgetTester tester) async {
    // 创建一个简单的测试 widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('FlutterPassword'),
        ),
      ),
    );

    // 验证文本存在
    expect(find.text('FlutterPassword'), findsOneWidget);
  });
}
