// Semper Move приложение тестілері
//
// Негізгі функцияларды тексеру үшін widget тесттері

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('Semper Move app smoke test', (WidgetTester tester) async {

    await tester.pumpWidget(const SemperMoveApp());
    
    await tester.pump(const Duration(seconds: 3));
    
    expect(find.text('SEMPER MOVE'), findsWidgets);
  });
}
