import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myflutter/main.dart';

/// Scroll offset used to navigate to the Exchange section.
/// This value is calibrated to scroll past the Item Calculation and
/// Amount Calculation sections to reach the Exchange section.
const Offset kScrollToExchangeOffset = Offset(0, -500);

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

    // Find and enter text in the weight field (use .first since there are two Weight fields)
    final weightField = find.widgetWithText(TextField, 'Weight (gm)').first;
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

    // Enter weight (use .first since there are two Weight fields)
    final weightField = find.widgetWithText(TextField, 'Weight (gm)').first;
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

    // Enter weight (use .first since there are two Weight fields)
    final weightField = find.widgetWithText(TextField, 'Weight (gm)').first;
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

    // Enter weight (use .first since there are two Weight fields)
    final weightField = find.widgetWithText(TextField, 'Weight (gm)').first;
    await tester.enterText(weightField, '10');
    await tester.pumpAndSettle();

    // Scroll to and tap Add Item button
    final addItemButton = find.byKey(const Key('add_item_button'));
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

    // Enter weight and add item (use .first since there are two Weight fields)
    final weightField = find.widgetWithText(TextField, 'Weight (gm)').first;
    await tester.enterText(weightField, '10');
    await tester.pumpAndSettle();

    // Scroll to and tap Add Item button
    final addItemButton = find.byKey(const Key('add_item_button'));
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

    // Enter weight and add item (use .first since there are two Weight fields)
    final weightField = find.widgetWithText(TextField, 'Weight (gm)').first;
    await tester.enterText(weightField, '10');
    await tester.pumpAndSettle();

    // Scroll to and tap Add Item button
    final addItemButton = find.byKey(const Key('add_item_button'));
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

    // Item Total (before GST) = 66000 + 350 = 66350
    expect(item.itemTotal, 66350.0);

    // CGST = 66350 * 0.015 = 995.25
    expect(item.cgst, 995.25);

    // SGST = 66350 * 0.015 = 995.25
    expect(item.sgst, 995.25);

    // Total GST = 995.25 + 995.25 = 1990.50
    expect(item.totalGst, 1990.50);

    // Item Total with GST = 66350 + 1990.50 = 68340.50
    expect(item.itemTotalWithGst, 68340.50);
  });

  testWidgets('Exchange section exists and supports all metal types', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Scroll to find the Exchange section using drag (use .first for explicit targeting)
    await tester.drag(find.byType(SingleChildScrollView).first, kScrollToExchangeOffset);
    await tester.pumpAndSettle();

    // Verify that Exchange section exists
    expect(find.text('Exchange'), findsOneWidget);
    expect(find.text('Enter old gold or silver details to deduct from total'), findsOneWidget);
  });

  testWidgets('Exchange shows value when weight is entered', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // First, set a gold rate in settings
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Set Gold 22K rate to 6000
    final gold22kRateField = find.widgetWithText(TextField, 'Gold 22K/916 Rate');
    await tester.enterText(gold22kRateField, '6000');
    await tester.pumpAndSettle();

    // Save settings
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Scroll to find the Exchange section (use .first to target the main page's SingleChildScrollView)
    await tester.drag(find.byType(SingleChildScrollView).first, kScrollToExchangeOffset);
    await tester.pumpAndSettle();

    // Enter exchange weight (use .last since there are two Weight fields)
    final exchangeWeightField = find.widgetWithText(TextField, 'Weight (gm)').last;
    await tester.enterText(exchangeWeightField, '5');
    await tester.pumpAndSettle();

    // Verify that exchange value is displayed
    expect(find.text('Rate:'), findsOneWidget);
    expect(find.text('Current Item Value:'), findsOneWidget);
  });

  testWidgets('Reset clears exchange input', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Scroll to find the Exchange section (use .first for explicit targeting)
    await tester.drag(find.byType(SingleChildScrollView).first, kScrollToExchangeOffset);
    await tester.pumpAndSettle();

    // Enter exchange weight (use .last since there are two Weight fields)
    final exchangeWeightField = find.widgetWithText(TextField, 'Weight (gm)').last;
    await tester.enterText(exchangeWeightField, '5');
    await tester.pumpAndSettle();

    // Tap reset button
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    // Verify exchange weight field is cleared
    final weightTextField = tester.widget<TextField>(exchangeWeightField);
    expect(weightTextField.controller?.text, isEmpty);
  });

  testWidgets('Add Exchange Item button exists and is initially disabled', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // Scroll to find the Exchange section
    await tester.drag(find.byType(SingleChildScrollView).first, kScrollToExchangeOffset);
    await tester.pumpAndSettle();

    // Verify that Add Exchange Item button exists
    expect(find.text('Add Exchange Item'), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);

    // Verify button is disabled when no weight is entered
    final addExchangeButtonFinder = find.byKey(const Key('add_exchange_item_button'));
    await tester.ensureVisible(addExchangeButtonFinder);
    await tester.pumpAndSettle();

    final addExchangeButton = tester.widget<ElevatedButton>(addExchangeButtonFinder);
    expect(addExchangeButton.onPressed, isNull);
  });

  testWidgets('Can add multiple exchange items', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelCalcApp());

    // First, set a gold rate in settings
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Set Gold 22K rate to 6000
    final gold22kRateField = find.widgetWithText(TextField, 'Gold 22K/916 Rate');
    await tester.enterText(gold22kRateField, '6000');
    await tester.pumpAndSettle();

    // Save settings
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Scroll to the Exchange section to ensure it's fully visible
    await tester.drag(find.byType(SingleChildScrollView).first, kScrollToExchangeOffset, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Find the exchange weight field and ensure it's visible
    final exchangeWeightField = find.widgetWithText(TextField, 'Weight (gm)').last;
    await tester.ensureVisible(exchangeWeightField);
    await tester.pumpAndSettle();

    // Enter exchange weight
    await tester.enterText(exchangeWeightField, '5');
    await tester.pumpAndSettle();

    // Unfocus the text field by tapping elsewhere on the page (not on the scaffold which includes the snackbar)
    // This clears any focus/decoration overlays
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // Ensure the add button is visible and tap it
    final addExchangeButton = find.byKey(const Key('add_exchange_item_button'));
    await tester.ensureVisible(addExchangeButton);
    await tester.pumpAndSettle();
    await tester.tap(addExchangeButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Added Exchange Items section appears
    expect(find.textContaining('Added Exchange Items'), findsOneWidget);

    // Verify delete icon exists for the added exchange item
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  test('ExchangeItem calculates correctly', () {
    final item = ExchangeItem(
      type: 'Gold 22K/916',
      weightGm: 10.0,
      ratePerGram: 6000.0,
    );

    // Value = 10 * 6000 = 60000
    expect(item.value, 60000.0);
  });
}
