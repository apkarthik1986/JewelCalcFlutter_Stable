import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// GST rate constant (1.5% each for CGST and SGST)
const double kGstRate = 0.015;

void main() {
  runApp(const JewelCalcApp());
}

/// Represents a single jewellery item with all its calculation details
class JewelItem {
  final String type;
  final double weightGm;
  final double wastageGm;
  final double ratePerGram;
  final double makingCharges;

  JewelItem({
    required this.type,
    required this.weightGm,
    required this.wastageGm,
    required this.ratePerGram,
    required this.makingCharges,
  });

  double get netWeightGm => weightGm + wastageGm;
  double get jAmount => netWeightGm * ratePerGram;
  double get itemTotal => jAmount + makingCharges;
  // GST breakdown for display in receipt (calculated on item total before discount)
  double get cgst => itemTotal * kGstRate;
  double get sgst => itemTotal * kGstRate;
  double get totalGst => cgst + sgst;
  double get itemTotalWithGst => itemTotal + totalGst;
}

/// Represents an exchange item (old gold or silver) with its value calculation
class ExchangeItem {
  final String type;
  final double weightGm;
  final double wastageDeductionGm;
  final double ratePerGram;

  ExchangeItem({
    required this.type,
    required this.weightGm,
    required this.wastageDeductionGm,
    required this.ratePerGram,
  }) : assert(weightGm >= 0, 'weightGm must be non-negative'),
       assert(wastageDeductionGm >= 0, 'wastageDeductionGm must be non-negative'),
       assert(ratePerGram >= 0, 'ratePerGram must be non-negative');

  double get netWeightGm => weightGm - wastageDeductionGm;
  double get value => netWeightGm * ratePerGram;
}

class JewelCalcApp extends StatelessWidget {
  const JewelCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jewel Calc',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const JewelCalcHome(),
    );
  }
}

class JewelCalcHome extends StatefulWidget {
  const JewelCalcHome({super.key});

  @override
  State<JewelCalcHome> createState() => _JewelCalcHomeState();
}

class _JewelCalcHomeState extends State<JewelCalcHome> {
  // Base values
  Map<String, double> metalRates = {
    'Gold 22K/916': 0.0,
    'Gold 20K/833': 0.0,
    'Gold 18K/750': 0.0,
    'Silver': 0.0,
  };

  double goldWastagePercentage = 0.0;
  double silverWastagePercentage = 0.0;
  double goldMcPerGm = 0.0;
  double silverMcPerGm = 0.0;

  // Form fields
  final TextEditingController billNumberController = TextEditingController();
  final TextEditingController customerAccController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController wastageController = TextEditingController();
  final TextEditingController makingChargesController = TextEditingController();

  // Settings dialog controllers
  final Map<String, TextEditingController> metalRateControllers = {};
  late final TextEditingController goldWastageController;
  late final TextEditingController silverWastageController;
  late final TextEditingController goldMcController;
  late final TextEditingController silverMcController;

  String selectedType = 'Gold 22K/916';
  double weightGm = 0.0;
  double wastageGm = 0.0;
  double makingCharges = 0.0;
  String mcType = 'Rupees';
  double mcPercentage = 0.0;
  String discountType = 'None';
  double discountAmount = 0.0;
  double discountPercentage = 0.0;

  // Exchange fields (for old gold/silver exchange)
  final TextEditingController exchangeWeightController = TextEditingController();
  final TextEditingController exchangeWastageController = TextEditingController();
  String exchangeType = 'Gold 22K/916';
  double exchangeWeight = 0.0;
  double exchangeWastageDeduction = 0.0;

  // List to store multiple items
  List<JewelItem> items = [];
  
  // List to store multiple exchange items
  List<ExchangeItem> exchangeItems = [];

  @override
  void initState() {
    super.initState();
    // Initialize settings dialog controllers
    for (var type in metalRates.keys) {
      metalRateControllers[type] = TextEditingController();
    }
    goldWastageController = TextEditingController();
    silverWastageController = TextEditingController();
    goldMcController = TextEditingController();
    silverMcController = TextEditingController();
    _loadBaseValues();
  }

  Future<void> _loadBaseValues() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString('last_date') ?? '';

    // Reset if new day
    if (lastDate != today) {
      await _resetToDefaults();
      return;
    }

    setState(() {
      metalRates['Gold 22K/916'] = prefs.getDouble('rate_gold_22k') ?? 0.0;
      metalRates['Gold 20K/833'] = prefs.getDouble('rate_gold_20k') ?? 0.0;
      metalRates['Gold 18K/750'] = prefs.getDouble('rate_gold_18k') ?? 0.0;
      metalRates['Silver'] = prefs.getDouble('rate_silver') ?? 0.0;
      goldWastagePercentage = prefs.getDouble('gold_wastage') ?? 0.0;
      silverWastagePercentage = prefs.getDouble('silver_wastage') ?? 0.0;
      goldMcPerGm = prefs.getDouble('gold_mc') ?? 0.0;
      silverMcPerGm = prefs.getDouble('silver_mc') ?? 0.0;

      // Update controllers with loaded values
      _updateSettingsControllers();
    });
  }

  void _updateSettingsControllers() {
    for (var entry in metalRates.entries) {
      metalRateControllers[entry.key]!.text =
          entry.value == 0.0 ? '' : entry.value.toString();
    }
    goldWastageController.text =
        goldWastagePercentage == 0.0 ? '' : goldWastagePercentage.toString();
    silverWastageController.text = silverWastagePercentage == 0.0
        ? ''
        : silverWastagePercentage.toString();
    goldMcController.text = goldMcPerGm == 0.0 ? '' : goldMcPerGm.toString();
    silverMcController.text =
        silverMcPerGm == 0.0 ? '' : silverMcPerGm.toString();
  }

  Future<void> _saveBaseValues() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await prefs.setString('last_date', today);
    await prefs.setDouble('rate_gold_22k', metalRates['Gold 22K/916']!);
    await prefs.setDouble('rate_gold_20k', metalRates['Gold 20K/833']!);
    await prefs.setDouble('rate_gold_18k', metalRates['Gold 18K/750']!);
    await prefs.setDouble('rate_silver', metalRates['Silver']!);
    await prefs.setDouble('gold_wastage', goldWastagePercentage);
    await prefs.setDouble('silver_wastage', silverWastagePercentage);
    await prefs.setDouble('gold_mc', goldMcPerGm);
    await prefs.setDouble('silver_mc', silverMcPerGm);
  }

  Future<void> _resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    setState(() {
      metalRates = {
        'Gold 22K/916': 0.0,
        'Gold 20K/833': 0.0,
        'Gold 18K/750': 0.0,
        'Silver': 0.0,
      };
      goldWastagePercentage = 0.0;
      silverWastagePercentage = 0.0;
      goldMcPerGm = 0.0;
      silverMcPerGm = 0.0;

      // Reset controllers
      for (var controller in metalRateControllers.values) {
        controller.text = '';
      }
      goldWastageController.text = '';
      silverWastageController.text = '';
      goldMcController.text = '';
      silverMcController.text = '';
    });

    await prefs.setString('last_date', today);
    await prefs.setDouble('rate_gold_22k', 0.0);
    await prefs.setDouble('rate_gold_20k', 0.0);
    await prefs.setDouble('rate_gold_18k', 0.0);
    await prefs.setDouble('rate_silver', 0.0);
    await prefs.setDouble('gold_wastage', 0.0);
    await prefs.setDouble('silver_wastage', 0.0);
    await prefs.setDouble('gold_mc', 0.0);
    await prefs.setDouble('silver_mc', 0.0);
  }

  void _resetAllInputs() {
    setState(() {
      billNumberController.clear();
      customerAccController.clear();
      customerNameController.clear();
      addressController.clear();
      mobileNumberController.clear();
      weightController.clear();
      wastageController.clear();
      makingChargesController.clear();
      exchangeWeightController.clear();
      exchangeWastageController.clear();
      weightGm = 0.0;
      wastageGm = 0.0;
      makingCharges = 0.0;
      mcPercentage = 0.0;
      discountAmount = 0.0;
      discountPercentage = 0.0;
      discountType = 'None';
      exchangeWeight = 0.0;
      exchangeWastageDeduction = 0.0;
      exchangeType = 'Gold 22K/916';
      items.clear();
      exchangeItems.clear();
    });
  }

  void _resetCurrentItemInputs() {
    setState(() {
      weightController.clear();
      wastageController.clear();
      makingChargesController.clear();
      weightGm = 0.0;
      wastageGm = 0.0;
      makingCharges = 0.0;
      mcPercentage = 0.0;
    });
  }

  void _addCurrentItem() {
    if (weightGm <= 0) return;
    
    setState(() {
      items.add(JewelItem(
        type: selectedType,
        weightGm: weightGm,
        wastageGm: wastageGm,
        ratePerGram: ratePerGram,
        makingCharges: makingCharges,
      ));
      _resetCurrentItemInputs();
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _resetCurrentExchangeInputs() {
    setState(() {
      exchangeWeightController.clear();
      exchangeWastageController.clear();
      exchangeWeight = 0.0;
      exchangeWastageDeduction = 0.0;
    });
  }

  void _addCurrentExchangeItem() {
    if (exchangeWeight <= 0) return;
    
    final rate = metalRates[exchangeType] ?? 0.0;
    if (rate <= 0) return; // Don't add if rate is zero or not set
    
    setState(() {
      exchangeItems.add(ExchangeItem(
        type: exchangeType,
        weightGm: exchangeWeight,
        wastageDeductionGm: exchangeWastageDeduction,
        ratePerGram: rate,
      ));
      _resetCurrentExchangeInputs();
    });
  }

  void _removeExchangeItem(int index) {
    setState(() {
      exchangeItems.removeAt(index);
    });
  }

  double get netWeightGm => weightGm + wastageGm;

  double get ratePerGram => metalRates[selectedType] ?? 0.0;

  double get jAmount => netWeightGm * ratePerGram;

  bool get isGold => selectedType.contains('Gold');

  double get minMakingCharge => isGold ? 250.0 : 200.0;

  double _calculateMakingCharges() {
    if (mcType == 'Rupees') {
      final mcPerGram = isGold ? goldMcPerGm : silverMcPerGm;
      final calculated = mcPerGram * weightGm;
      return calculated > minMakingCharge ? calculated : minMakingCharge;
    } else {
      final calculated = jAmount * (mcPercentage / 100);
      return calculated > minMakingCharge ? calculated : minMakingCharge;
    }
  }

  // Total of all items in the list (without GST, for calculation)
  double get itemsTotal => items.fold(0.0, (sum, item) => sum + item.itemTotal);

  // Total of all items with GST included (for display)
  double get itemsTotalWithGst => items.fold(0.0, (sum, item) => sum + item.itemTotalWithGst);

  // Current item total (before adding to list)
  double get currentItemTotal => jAmount + makingCharges;

  // Grand total: all items + current item (if any weight entered)
  double get amountBeforeGst => itemsTotal + (weightGm > 0 ? currentItemTotal : 0);

  double get actualDiscountAmount {
    if (discountType == 'Rupees') {
      return discountAmount;
    } else if (discountType == 'Percentage') {
      return amountBeforeGst * (discountPercentage / 100);
    }
    return 0.0;
  }

  double get amountAfterDiscount => amountBeforeGst - actualDiscountAmount;

  // Exchange rate for current exchange item input
  double get exchangeRate => metalRates[exchangeType] ?? 0.0;
  
  // Net weight after wastage deduction for current exchange item
  double get currentExchangeNetWeight => exchangeWeight - exchangeWastageDeduction;
  
  // Current exchange item value (before adding to list)
  double get currentExchangeValue => currentExchangeNetWeight * exchangeRate;
  
  // Total value of all exchange items in the list
  double get exchangeItemsTotal => exchangeItems.fold(0.0, (sum, item) => sum + item.value);
  
  // Total exchange value: all exchange items + current exchange item (if any weight entered)
  double get totalExchangeValue => exchangeItemsTotal + (exchangeWeight > 0 ? currentExchangeValue : 0);
  
  // Total number of exchange items (saved + current if any)
  int get totalExchangeCount => exchangeItems.length + (exchangeWeight > 0 ? 1 : 0);

  double get cgstAmount => amountAfterDiscount * kGstRate;

  double get sgstAmount => amountAfterDiscount * kGstRate;

  double get finalAmount => amountAfterDiscount + cgstAmount + sgstAmount - totalExchangeValue;

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    
    // Build list of item widgets for PDF
    List<pw.Widget> _buildItemWidgets() {
      List<pw.Widget> widgets = [];
      
      // Add saved items
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        widgets.addAll([
          pw.Text('Item ${i + 1}: ${item.type}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text('Rate: Rs.${item.ratePerGram}/gm',
              style: const pw.TextStyle(fontSize: 14)),
          pw.Text('Weight: ${item.weightGm.toStringAsFixed(3)} gm',
              style: const pw.TextStyle(fontSize: 14)),
          pw.Text('Wastage: ${item.wastageGm.toStringAsFixed(3)} gm',
              style: const pw.TextStyle(fontSize: 14)),
          pw.Text('Net Weight: ${item.netWeightGm.toStringAsFixed(3)} gm',
              style: const pw.TextStyle(fontSize: 14)),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('J Amount:', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Rs.${item.jAmount.round()}', style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Making Charges:', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Rs.${item.makingCharges.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Sub Total:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Rs.${item.itemTotal.round()}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('CGST 1.5%:', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Rs.${item.cgst.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('SGST 1.5%:', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Rs.${item.sgst.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Item Total:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Rs.${item.itemTotalWithGst.round()}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 8),
        ]);
      }
      
      // Add current item if any weight entered
      if (weightGm > 0) {
        final itemNum = items.length + 1;
        final currentAmountBeforeGst = jAmount + makingCharges;
        final currentCgst = currentAmountBeforeGst * kGstRate;
        final currentSgst = currentAmountBeforeGst * kGstRate;
        final currentTotalWithGst = currentAmountBeforeGst + currentCgst + currentSgst;
        widgets.addAll([
          pw.Text('Item $itemNum: $selectedType',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text('Rate: Rs.$ratePerGram/gm',
              style: const pw.TextStyle(fontSize: 14)),
          pw.Text('Weight: ${weightGm.toStringAsFixed(3)} gm',
              style: const pw.TextStyle(fontSize: 14)),
          pw.Text('Wastage: ${wastageGm.toStringAsFixed(3)} gm',
              style: const pw.TextStyle(fontSize: 14)),
          pw.Text('Net Weight: ${netWeightGm.toStringAsFixed(3)} gm',
              style: const pw.TextStyle(fontSize: 14)),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('J Amount:', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Rs.${jAmount.round()}', style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Making Charges:', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Rs.${makingCharges.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Sub Total:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Rs.${currentAmountBeforeGst.round()}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('CGST 1.5%:', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Rs.${currentCgst.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('SGST 1.5%:', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Rs.${currentSgst.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Item Total:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Rs.${currentTotalWithGst.round()}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 8),
        ]);
      }
      
      return widgets;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Center(
                  child: pw.Text('ESTIMATE',
                      style: pw.TextStyle(
                          fontSize: 21, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                      DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
                      style: const pw.TextStyle(fontSize: 15)),
                ),
                pw.Divider(),
                if (billNumberController.text.isNotEmpty)
                  pw.Text('Bill No: ${billNumberController.text}',
                      style: const pw.TextStyle(fontSize: 16)),
                if (customerAccController.text.isNotEmpty)
                  pw.Text('Acc No: ${customerAccController.text}',
                      style: const pw.TextStyle(fontSize: 16)),
                if (customerNameController.text.isNotEmpty)
                  pw.Text('Name: ${customerNameController.text}',
                      style: const pw.TextStyle(fontSize: 16)),
                if (addressController.text.isNotEmpty)
                  pw.Text('Address: ${addressController.text}',
                      style: const pw.TextStyle(fontSize: 16)),
                if (mobileNumberController.text.isNotEmpty)
                  pw.Text('Mobile: ${mobileNumberController.text}',
                      style: const pw.TextStyle(fontSize: 16)),
                pw.Divider(),
                pw.Text('ITEM DETAILS (${items.length + (weightGm > 0 ? 1 : 0)} items)',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                ..._buildItemWidgets(),
                pw.Divider(),
                pw.Text('AMOUNT SUMMARY',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal:',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs.${amountBeforeGst.round()}',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                if (actualDiscountAmount > 0) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Discount:',
                          style: const pw.TextStyle(fontSize: 16)),
                      pw.Text('Rs.${actualDiscountAmount.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 16)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('After Discount:',
                          style: pw.TextStyle(
                              fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Rs.${amountAfterDiscount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                              fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('CGST 1.5%:',
                        style: const pw.TextStyle(fontSize: 16)),
                    pw.Text('Rs.${cgstAmount.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 16)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('SGST 1.5%:',
                        style: const pw.TextStyle(fontSize: 16)),
                    pw.Text('Rs.${sgstAmount.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 16)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Overall Total:',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs.${(amountAfterDiscount + cgstAmount + sgstAmount).round()}',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                if (totalExchangeValue > 0) ...[
                  pw.Divider(),
                  pw.Text('EXCHANGE ($totalExchangeCount items)',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  // Add saved exchange items
                  ...exchangeItems.map((item) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 4),
                      pw.Text('${item.type}',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('${item.weightGm.toStringAsFixed(3)} gm @ Rs.${item.ratePerGram.toStringAsFixed(2)}/gm',
                          style: const pw.TextStyle(fontSize: 12)),
                      if (item.wastageDeductionGm > 0)
                        pw.Text('Wastage Deduction: ${item.wastageDeductionGm.toStringAsFixed(3)} gm',
                            style: const pw.TextStyle(fontSize: 12)),
                      if (item.wastageDeductionGm > 0)
                        pw.Text('Net Weight: ${item.netWeightGm.toStringAsFixed(3)} gm',
                            style: const pw.TextStyle(fontSize: 12)),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Value:',
                              style: const pw.TextStyle(fontSize: 14)),
                          pw.Text('- Rs.${item.value.round()}',
                              style: const pw.TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                  )),
                  // Add current exchange item if any weight entered
                  if (exchangeWeight > 0) ...[
                    pw.SizedBox(height: 4),
                    pw.Text('$exchangeType',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${exchangeWeight.toStringAsFixed(3)} gm @ Rs.${exchangeRate.toStringAsFixed(2)}/gm',
                        style: const pw.TextStyle(fontSize: 12)),
                    if (exchangeWastageDeduction > 0)
                      pw.Text('Wastage Deduction: ${exchangeWastageDeduction.toStringAsFixed(3)} gm',
                          style: const pw.TextStyle(fontSize: 12)),
                    if (exchangeWastageDeduction > 0)
                      pw.Text('Net Weight: ${currentExchangeNetWeight.toStringAsFixed(3)} gm',
                          style: const pw.TextStyle(fontSize: 12)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Value:',
                            style: const pw.TextStyle(fontSize: 14)),
                        pw.Text('- Rs.${currentExchangeValue.round()}',
                            style: const pw.TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Exchange:',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('- Rs.${totalExchangeValue.round()}',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(totalExchangeValue > 0 ? 'Net Payable:' : 'T.Amount:',
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs.${finalAmount.round()}',
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('💎 Jewel Calc 💎'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAllInputs,
            tooltip: 'Reset All',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildCustomerInfoSection(),
            const SizedBox(height: 16),
            _buildItemCalculationSection(),
            const SizedBox(height: 16),
            _buildAmountCalculationSection(),
            const SizedBox(height: 16),
            _buildItemsListSection(),
            const SizedBox(height: 16),
            _buildDiscountSection(),
            const SizedBox(height: 16),
            _buildGstSection(),
            const SizedBox(height: 16),
            _buildExchangeSection(),
            const SizedBox(height: 16),
            _buildFinalAmountSection(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generatePdf,
                icon: const Icon(Icons.print),
                label: const Text('Print'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsListSection() {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Added Items (${items.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Total: ₹${itemsTotalWithGst.round()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${index + 1}. ${item.type}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(index),
                              tooltip: 'Remove Item',
                            ),
                          ],
                        ),
                        Text('Weight: ${item.weightGm.toStringAsFixed(3)}gm | Net: ${item.netWeightGm.toStringAsFixed(3)}gm'),
                        Text('Wastage: ${item.wastageGm.toStringAsFixed(3)}gm'),
                        Text('Making Charges: ₹${item.makingCharges.toStringAsFixed(2)}'),
                        Text('CGST 1.5%: ₹${item.cgst.toStringAsFixed(2)} | SGST 1.5%: ₹${item.sgst.toStringAsFixed(2)}'),
                        const SizedBox(height: 4),
                        Text(
                          'Item Total: ₹${item.itemTotalWithGst.round()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoSection() {
    return Card(
      child: ExpansionTile(
        title: const Text('Customer Information'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: billNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Bill Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: customerAccController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Acc Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mobileNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCalculationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item Calculation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: metalRates.keys.map((String type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                  wastageGm = weightGm *
                      (isGold
                          ? goldWastagePercentage
                          : silverWastagePercentage) /
                      100;
                  wastageController.text = wastageGm.toStringAsFixed(3);
                  makingCharges = _calculateMakingCharges();
                });
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📌 Current Rate: ₹${ratePerGram.toStringAsFixed(2)} per gram',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (gm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        weightGm = double.tryParse(value) ?? 0.0;
                        wastageGm = weightGm *
                            (isGold
                                ? goldWastagePercentage
                                : silverWastagePercentage) /
                            100;
                        wastageController.text = wastageGm.toStringAsFixed(3);
                        makingCharges = _calculateMakingCharges();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: wastageController,
                    decoration: InputDecoration(
                      labelText: 'Wastage (gm)',
                      border: const OutlineInputBorder(),
                      hintText: wastageGm.toStringAsFixed(3),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        wastageGm = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Net Weight: ${netWeightGm.toStringAsFixed(3)} gm',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCalculationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount Calculation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('J Amount:'),
                Text('₹${jAmount.round()}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            Text(
              'Making Charges',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Rupees', label: Text('Rupees (₹)')),
                ButtonSegment(
                    value: 'Percentage', label: Text('Percentage (%)')),
              ],
              selected: {mcType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  mcType = newSelection.first;
                  makingCharges = _calculateMakingCharges();
                });
              },
            ),
            const SizedBox(height: 12),
            if (mcType == 'Rupees')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: makingChargesController,
                    decoration: const InputDecoration(
                      labelText: 'Making Charges (₹)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        makingCharges =
                            double.tryParse(value) ?? minMakingCharge;
                        if (makingCharges < minMakingCharge) {
                          makingCharges = minMakingCharge;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Calculated: ₹${makingCharges.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Making Charge Percentage (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        mcPercentage = double.tryParse(value) ?? 0.0;
                        makingCharges = _calculateMakingCharges();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Making Charges: ₹${makingCharges.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Item:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('₹${currentItemTotal.round()}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('add_item_button'),
                onPressed: weightGm > 0 ? _addCurrentItem : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add Item to List'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('All Items Total (${items.length} items):',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹${itemsTotal.round()}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discount',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'None', label: Text('None')),
                ButtonSegment(value: 'Rupees', label: Text('Rupees (₹)')),
                ButtonSegment(
                    value: 'Percentage', label: Text('Percentage (%)')),
              ],
              selected: {discountType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  discountType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 12),
            if (discountType == 'Rupees')
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Discount Amount (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    discountAmount = double.tryParse(value) ?? 0.0;
                  });
                },
              )
            else if (discountType == 'Percentage')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Discount Percentage (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        discountPercentage = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Discount Amount: ₹${actualDiscountAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            if (actualDiscountAmount > 0) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount After Discount:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('₹${amountAfterDiscount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGstSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CGST 1.5%:'),
                Text('₹${cgstAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SGST 1.5%:'),
                Text('₹${sgstAmount.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeSection() {
    // Allow all metal types for exchange (gold and silver)
    final allTypes = metalRates.keys.toList();
    final isExchangeSilver = exchangeType == 'Silver';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exchange',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter old gold or silver details to deduct from total',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: exchangeType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: allTypes.map((String type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        exchangeType = value!;
                        // For Silver, auto-calculate 30% wastage deduction
                        if (exchangeType == 'Silver' && exchangeWeight > 0) {
                          exchangeWastageDeduction = exchangeWeight * 0.30;
                          exchangeWastageController.text = exchangeWastageDeduction.toStringAsFixed(3);
                        } else if (exchangeType != 'Silver') {
                          // For Gold, reset wastage to 0 (manual entry only)
                          exchangeWastageDeduction = 0.0;
                          exchangeWastageController.clear();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: exchangeWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (gm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        exchangeWeight = double.tryParse(value) ?? 0.0;
                        // For Silver, auto-calculate 30% wastage deduction
                        if (exchangeType == 'Silver' && exchangeWeight > 0) {
                          exchangeWastageDeduction = exchangeWeight * 0.30;
                          exchangeWastageController.text = exchangeWastageDeduction.toStringAsFixed(3);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            if (exchangeWeight > 0) ...[
              const SizedBox(height: 12),
              TextField(
                controller: exchangeWastageController,
                decoration: InputDecoration(
                  labelText: 'Wastage Deduction (gm)',
                  border: const OutlineInputBorder(),
                  helperText: isExchangeSilver 
                      ? 'Auto 30% deduction, can be manually changed'
                      : 'Manual entry only',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    exchangeWastageDeduction = double.tryParse(value) ?? 0.0;
                    // Ensure wastage deduction is not more than weight
                    if (exchangeWastageDeduction > exchangeWeight) {
                      exchangeWastageDeduction = exchangeWeight;
                      exchangeWastageController.text = exchangeWastageDeduction.toStringAsFixed(3);
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Rate:'),
                        Text('₹${exchangeRate.toStringAsFixed(2)}/gm'),
                      ],
                    ),
                    if (exchangeWastageDeduction > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Net Weight:'),
                          Text('${currentExchangeNetWeight.toStringAsFixed(3)} gm'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Item Value:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('- ₹${currentExchangeValue.round()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('add_exchange_item_button'),
                onPressed: exchangeWeight > 0 ? _addCurrentExchangeItem : null,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Add Exchange Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
            if (exchangeItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Added Exchange Items (${exchangeItems.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Total: - ₹${exchangeItemsTotal.round()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exchangeItems.length,
                itemBuilder: (context, index) {
                  final item = exchangeItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}. ${item.type}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('${item.weightGm.toStringAsFixed(3)}gm @ ₹${item.ratePerGram.toStringAsFixed(2)}/gm'),
                                if (item.wastageDeductionGm > 0)
                                  Text('Wastage Deduction: ${item.wastageDeductionGm.toStringAsFixed(3)}gm'),
                                if (item.wastageDeductionGm > 0)
                                  Text('Net Weight: ${item.netWeightGm.toStringAsFixed(3)}gm'),
                                Text(
                                  'Value: - ₹${item.value.round()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeExchangeItem(index),
                            tooltip: 'Remove Exchange Item',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinalAmountSection() {
    final totalItemsCount = items.length + (weightGm > 0 ? 1 : 0);
    final amountWithGst = amountAfterDiscount + cgstAmount + sgstAmount;
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (totalItemsCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '📦 Total Items: $totalItemsCount',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            if (totalExchangeValue > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount with GST:',
                      style: TextStyle(fontSize: 14)),
                  Text('₹${amountWithGst.round()}',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Exchange ($totalExchangeCount items):',
                      style: const TextStyle(fontSize: 14, color: Colors.orange)),
                  Text('- ₹${totalExchangeValue.round()}',
                      style: const TextStyle(fontSize: 14, color: Colors.orange)),
                ],
              ),
              const Divider(),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(totalExchangeValue > 0 ? '💰 Net Payable:' : '💰 Amount Incl. GST:',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('₹${finalAmount.round()}',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    // Update controllers with current values before showing dialog
    _updateSettingsControllers();
    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('⚙️ Base Values Configuration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Metal Rates (₹ per gram)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...metalRates.keys.map((type) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: '$type Rate',
                        border: const OutlineInputBorder(),
                        hintText: 'e.g., 6500',
                      ),
                      keyboardType: TextInputType.number,
                      controller: metalRateControllers[type],
                      onChanged: (value) {
                        metalRates[type] = double.tryParse(value) ?? 0.0;
                      },
                    ),
                  )),
              const Divider(),
              const Text('Wastage Settings',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Gold Wastage (%)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 10',
                ),
                keyboardType: TextInputType.number,
                controller: goldWastageController,
                onChanged: (value) {
                  goldWastagePercentage = double.tryParse(value) ?? 0.0;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Silver Wastage (%)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 8',
                ),
                keyboardType: TextInputType.number,
                controller: silverWastageController,
                onChanged: (value) {
                  silverWastagePercentage = double.tryParse(value) ?? 0.0;
                },
              ),
              const Divider(),
              const Text('Making Charges',
                  key: Key('settings_making_charges'),
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Gold MC (₹ per gram)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 350',
                ),
                keyboardType: TextInputType.number,
                controller: goldMcController,
                onChanged: (value) {
                  goldMcPerGm = double.tryParse(value) ?? 0.0;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Silver MC (₹ per gram)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 200',
                ),
                keyboardType: TextInputType.number,
                controller: silverMcController,
                onChanged: (value) {
                  silverMcPerGm = double.tryParse(value) ?? 0.0;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _resetToDefaults();
              setState(() {});
            },
            child: const Text('Reset to Defaults'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveBaseValues();
              Navigator.of(dialogContext).pop();
              setState(() {});
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                const SnackBar(
                  content: Text('Settings saved successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    billNumberController.dispose();
    customerAccController.dispose();
    customerNameController.dispose();
    addressController.dispose();
    mobileNumberController.dispose();
    weightController.dispose();
    wastageController.dispose();
    makingChargesController.dispose();
    exchangeWeightController.dispose();
    exchangeWastageController.dispose();
    for (var controller in metalRateControllers.values) {
      controller.dispose();
    }
    goldWastageController.dispose();
    silverWastageController.dispose();
    goldMcController.dispose();
    silverMcController.dispose();
    super.dispose();
  }
}
