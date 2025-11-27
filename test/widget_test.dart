import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myflutter/main.dart';

void main() {
  testWidgets('Jewel Calc app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Verify that our app has the correct title
    expect(find.text('💎 Jewel Calc 💎'), findsOneWidget);

    // Verify that Customer Information section exists
    expect(find.text('Customer Information'), findsOneWidget);

    // Verify that Item Calculation section exists
    expect(find.text('Item Calculation'), findsOneWidget);

    // Verify that Amount Calculation section exists
    expect(find.text('Amount Calculation'), findsOneWidget);

    // Verify that settings icon exists
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // Verify that refresh icon exists
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('Settings dialog opens', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Tap the settings icon
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Verify that settings dialog is displayed
    expect(find.text('⚙️ Base Values Configuration'), findsOneWidget);
    expect(find.text('Metal Rates (₹ per gram)'), findsOneWidget);
    expect(find.text('Wastage Settings'), findsOneWidget);
    expect(find.byKey(const Key('settings_making_charges')), findsOneWidget);
  });

  testWidgets('Print button exists', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Verify that Print button exists (not Download PDF)
    expect(find.text('Print'), findsOneWidget);
    expect(find.byIcon(Icons.print), findsOneWidget);
    expect(find.text('Download PDF'), findsNothing);
  });

  testWidgets('Reset button clears all inputs', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Find and enter text in the weight field
    final weightField = find.widgetWithText(TextField, 'Weight (gm)');
    await tester.tap(weightField);
    await tester.enterText(weightField, '10');
    await tester.pumpAndSettle();

    // Verify weight was entered
    expect(find.text('10'), findsOneWidget);

    // Tap the reset button
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    // Verify the field is cleared (the text "10" should not be found in the weight field anymore)
    final weightTextField = tester.widget<TextField>(weightField);
    expect(weightTextField.controller?.text, isEmpty);
  });

  testWidgets('Reset to Defaults keeps settings dialog open', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Open settings dialog
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Verify dialog is open
    expect(find.text('⚙️ Base Values Configuration'), findsOneWidget);

    // Tap Reset to Defaults button
    await tester.tap(find.text('Reset to Defaults'));
    await tester.pumpAndSettle();

    // Verify dialog is still open
    expect(find.text('⚙️ Base Values Configuration'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('Wastage field shows calculated value', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Open settings to set wastage percentage
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Set gold wastage to 10%
    final goldWastageField = find.widgetWithText(TextField, 'Gold Wastage (%)');
    await tester.enterText(goldWastageField, '10');
    await tester.pumpAndSettle();

    // Save settings
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Enter weight
    final weightField = find.widgetWithText(TextField, 'Weight (gm)');
    await tester.enterText(weightField, '10');
    await tester.pumpAndSettle();

    // Verify wastage field is populated with calculated value (10 * 10% = 1.000)
    final wastageField = tester.widget<TextField>(find.widgetWithText(TextField, 'Wastage (gm)'));
    expect(wastageField.controller?.text, '1.000');
  });

  testWidgets('Add Item button exists and is initially disabled', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Verify that Add Item to List button exists
    expect(find.text('Add Item to List'), findsOneWidget);
    expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);

    // Scroll to make the button visible
    final addItemButtonFinder = find.byKey(const Key('add_item_button'));
    await tester.ensureVisible(addItemButtonFinder);
    await tester.pumpAndSettle();

    // Verify button is disabled when no weight is entered
    final addItemButton = tester.widget<ElevatedButton>(addItemButtonFinder);
    expect(addItemButton.onPressed, isNull);
  });

  testWidgets('Add Item button becomes enabled when weight is entered', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Enter weight
    final weightField = find.widgetWithText(TextField, 'Weight (gm)');
    await tester.enterText(weightField, '10');
    await tester.pumpAndSettle();

    // Scroll to make the button visible
    final addItemButtonFinder = find.byKey(const Key('add_item_button'));
    await tester.ensureVisible(addItemButtonFinder);
    await tester.pumpAndSettle();

    // Verify Add Item button is now enabled
    final addItemButton = tester.widget<ElevatedButton>(addItemButtonFinder);
    expect(addItemButton.onPressed, isNotNull);
  });

  testWidgets('Adding item shows items list section', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Initially, Added Items section should not exist
    expect(find.textContaining('Added Items'), findsNothing);

    // Enter weight
    final weightField = find.widgetWithText(TextField, 'Weight (gm)');
    await tester.enterText(weightField, '10');
    await tester.pumpAndSettle();

    // Scroll to and tap Add Item button
    final addItemButton = find.text('Add Item to List');
    await tester.ensureVisible(addItemButton);
    await tester.pumpAndSettle();
    await tester.tap(addItemButton);
    await tester.pumpAndSettle();

    // Verify Added Items section now appears
    expect(find.textContaining('Added Items'), findsOneWidget);

    // Verify delete icon exists for the added item
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('Removing item hides items list when empty', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Enter weight and add item
    final weightField = find.widgetWithText(TextField, 'Weight (gm)');
    await tester.enterText(weightField, '10');
    await tester.pumpAndSettle();

    // Scroll to and tap Add Item button
    final addItemButton = find.text('Add Item to List');
    await tester.ensureVisible(addItemButton);
    await tester.pumpAndSettle();
    await tester.tap(addItemButton);
    await tester.pumpAndSettle();

    // Verify Added Items section exists
    expect(find.textContaining('Added Items'), findsOneWidget);

    // Scroll to and tap delete button
    final deleteButton = find.byIcon(Icons.delete);
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Verify Added Items section is gone
    expect(find.textContaining('Added Items'), findsNothing);
  });

  testWidgets('Reset clears items list', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Enter weight and add item
    final weightField = find.widgetWithText(TextField, 'Weight (gm)');
    await tester.enterText(weightField, '10');
    await tester.pumpAndSettle();

    // Scroll to and tap Add Item button
    final addItemButton = find.text('Add Item to List');
    await tester.ensureVisible(addItemButton);
    await tester.pumpAndSettle();
    await tester.tap(addItemButton);
    await tester.pumpAndSettle();

    // Verify Added Items section exists
    expect(find.textContaining('Added Items'), findsOneWidget);

    // Tap reset button
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    // Verify Added Items section is gone after reset
    expect(find.textContaining('Added Items'), findsNothing);
  });

  test('JewelItem calculates correctly', () {
    final item = JewelItem(
      type: 'Gold 22K/916',
      weightGm: 10.0,
      wastageGm: 1.0,
      ratePerGram: 6000.0,
      makingCharges: 350.0,
    );

    // Net weight = 10 + 1 = 11
    expect(item.netWeightGm, 11.0);

    // J Amount = 11 * 6000 = 66000
    expect(item.jAmount, 66000.0);

    // Item Total = 66000 + 350 = 66350
    expect(item.itemTotal, 66350.0);
  });
}
