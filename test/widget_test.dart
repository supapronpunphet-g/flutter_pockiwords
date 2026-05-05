// Placeholder widget tests. The main app requires Firebase initialization,
// which is not available in unit tests. Detailed widget tests for individual
// screens will be added in later phases with mocked services.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pockiwords/utils/theme.dart';
import 'package:flutter_pockiwords/widgets/pocki_button.dart';

void main() {
  testWidgets('PockiButton renders label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: PockiButton(label: 'Tap me', onPressed: () {}),
      ),
    ));
    expect(find.text('Tap me'), findsOneWidget);
  });
}
