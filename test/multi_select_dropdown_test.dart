import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_select_dropdown/multi_select_dropdown.dart';

void main() {
  testWidgets('MultiSelectDropdownServer renders without crashing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiSelectDropdownServer<String>(
            items: const ['One', 'Two', 'Three'],
            selectedItems: const [],
            getLabel: (v) => v,
            compareFn: (a, b) => a == b,
            onChanged: (items) {},
          ),
        ),
      ),
    );

    expect(find.byType(MultiSelectDropdownServer<String>), findsOneWidget);
  });
}
