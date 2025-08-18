// main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InvestmentApp());
}

class InvestmentApp extends StatelessWidget {
  const InvestmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Investment Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// --------------------------------------------------------------------
// Data Models

class InvestmentItem {
  String id;
  String name;
  String category;
  double todayValue;
  double invested;
  double? earnings;
  double? quantity;
  String? note;
  double? withdrawal;

  InvestmentItem({
    required this.id,
    required this.name,
    required this.category,
    required this.todayValue,
    required this.invested,
    this.earnings,
    this.quantity,
    this.note,
    this.withdrawal,
  });
  double get profitPercentage {
    final effectiveInvested = invested - (withdrawal ?? 0);
    if (effectiveInvested <= 0) {
      return 0.0;
    }
    return (computedEarnings / effectiveInvested) * 100;
  }

  // CORRECTED LOGIC: Withdrawal reduces the invested amount, not the earnings
  double get computedEarnings =>
      (earnings ?? (todayValue - (invested - (withdrawal ?? 0))));

  factory InvestmentItem.fromMap(Map<String, dynamic> map) => InvestmentItem(
    id: map['id'],
    name: map['name'] ?? '',
    category: map['category'] ?? 'Uncategorized',
    todayValue: (map['todayValue'] ?? 0).toDouble(),
    invested: (map['invested'] ?? 0).toDouble(),
    earnings: map['earnings'] == null
        ? null
        : (map['earnings'] as num).toDouble(),
    quantity: map['quantity'] == null
        ? null
        : (map['quantity'] as num).toDouble(),
    note: map['note'],
    withdrawal: map['withdrawal'] == null
        ? null
        : (map['withdrawal'] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'todayValue': todayValue,
    'invested': invested,
    'earnings': earnings,
    'quantity': quantity,
    'note': note,
    'withdrawal': withdrawal,
  };
}

class HistoryRecord {
  String action;
  String details;
  DateTime time;

  HistoryRecord({
    required this.action,
    required this.details,
    required this.time,
  });

  factory HistoryRecord.fromMap(Map<String, dynamic> map) => HistoryRecord(
    action: map['action'],
    details: map['details'],
    time: DateTime.parse(map['time']),
  );

  Map<String, dynamic> toMap() => {
    'action': action,
    'details': details,
    'time': time.toIso8601String(),
  };
}

// --------------------------------------------------------------------
// Home Page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _nf = NumberFormat('#,##0');
  List<InvestmentItem> _items = [];
  List<HistoryRecord> _history = [];
  String _query = '';
  String _categoryFilter = 'All';
  int _selectedIndex = 0;

  static const _storeItemsKey = 'investments_v2';
  static const _storeHistoryKey = 'history_v1';

  static final List<InvestmentItem> _defaultInvestments = [
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "Easypaisa Gold",
      invested: 6000,
      todayValue: 8500,
      category: 'Funds',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "Easypaisa FB",
      invested: 1000,
      todayValue: 1100,
      category: 'Funds',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "Binance 144",
      invested: 44200,
      todayValue: 35070,
      category: 'Crypto',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "Kucoin 27",
      invested: 7850,
      todayValue: 8214,
      category: 'Crypto',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "Bybit 17",
      invested: 2620,
      todayValue: 3118,
      category: 'Crypto',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "Bitgat 6",
      invested: 1750,
      todayValue: 2128,
      category: 'Crypto',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "Fassat 17",
      invested: 5000,
      todayValue: 4930,
      category: 'Stock',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "iSave MCB",
      invested: 14178,
      todayValue: 20178,
      category: 'Bank',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "Meezan Investment",
      invested: 13812,
      todayValue: 20154,
      category: 'Funds',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "NBP Fund",
      invested: 16625,
      todayValue: 20425,
      category: 'Funds',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "UBL Funds",
      invested: 16933,
      todayValue: 18882,
      category: 'Funds',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "HBL Funds",
      invested: 18867,
      todayValue: 20410,
      category: 'Funds',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "Zindagi",
      invested: 1100,
      todayValue: 1100,
      category: 'Bank',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "KTrade",
      invested: 22040,
      todayValue: 30040,
      category: 'Stock',
    ),
    InvestmentItem(
      id: UniqueKey().toString(),
      name: "Cash",
      invested: 11500,
      todayValue: 11500,
      category: 'Cash',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  double get totalCashInHand {
    return _items
        .where((item) => item.category.toLowerCase() == 'cash')
        .fold(0, (sum, item) => sum + item.todayValue);
  }

  double get taxOnProfit {
    if (totalProfit <= 0) {
      return 0.0;
    }
    return totalProfit * 0.20;
  }

  Future<void> _loadData() async {
    final sp = await SharedPreferences.getInstance();
    final rawItems = sp.getString(_storeItemsKey);
    final rawHistory = sp.getString(_storeHistoryKey);
    if (rawItems != null) {
      final list = (jsonDecode(rawItems) as List).cast<Map<String, dynamic>>();
      _items = list.map((e) => InvestmentItem.fromMap(e)).toList();
    } else {
      _items = _defaultInvestments;
    }
    if (rawHistory != null) {
      final list = (jsonDecode(rawHistory) as List)
          .cast<Map<String, dynamic>>();
      _history = list.map((e) => HistoryRecord.fromMap(e)).toList();
    }
    setState(() {});
  }

  Future<void> _saveData() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _storeItemsKey,
      jsonEncode(_items.map((e) => e.toMap()).toList()),
    );
    await sp.setString(
      _storeHistoryKey,
      jsonEncode(_history.map((e) => e.toMap()).toList()),
    );
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("OK"),
              ),
            ],
          ),
        ) ??
        false;
  }

  double get totalInvested =>
      _items.fold(0, (s, i) => s + i.invested - (i.withdrawal ?? 0));
  double get totalValue => _items.fold(0, (s, i) => s + i.todayValue);
  double get totalProfit => _items.fold(0, (s, i) => s + i.computedEarnings);

  // New function to calculate total profit percentage
  double get totalProfitPercentage {
    if (totalInvested == 0) {
      return 0.0;
    }
    final netProfit = totalProfit - taxOnProfit;
    return (netProfit / totalInvested) * 100;
  }

  List<String> get _allCategories {
    final s = {'All'}..addAll(_items.map((e) => e.category));
    return s.toList();
  }

  void _addInvestment() async {
    final newItem = await Navigator.push<InvestmentItem>(
      context,
      MaterialPageRoute(builder: (_) => const AddInvestmentPage()),
    );
    if (newItem != null) {
      setState(() {
        _items.add(newItem);
        _history.add(
          HistoryRecord(
            action: "Add",
            details: "Added ${newItem.name}",
            time: DateTime.now(),
          ),
        );
        _saveData();
      });
    }
  }

  void _editInvestment(InvestmentItem item) async {
    final editedItem = await Navigator.push<InvestmentItem>(
      context,
      MaterialPageRoute(builder: (_) => AddInvestmentPage(existing: item)),
    );
    if (editedItem != null) {
      setState(() {
        final index = _items.indexWhere((e) => e.id == item.id);
        if (index != -1) {
          _items[index] = editedItem;
          _history.add(
            HistoryRecord(
              action: "Edit",
              details: "Edited ${editedItem.name}",
              time: DateTime.now(),
            ),
          );
          _saveData();
        }
      });
    }
  }

  void _deleteInvestment(String id) async {
    final ok = await _confirm(context, "Confirm", "Delete this investment?");
    if (ok) {
      final removed = _items.firstWhere((e) => e.id == id);
      setState(() {
        _items.removeWhere((e) => e.id == id);
        _history.add(
          HistoryRecord(
            action: "Delete",
            details: "Deleted ${removed.name}",
            time: DateTime.now(),
          ),
        );
        _saveData();
      });
    }
  }

  void _importFromNote() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import from Note'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: ctrl,
            maxLines: 14,
            decoration: const InputDecoration(
              hintText: 'Paste your note text here...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final parsed = _parseFromNote(ctrl.text);
              if (parsed.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nothing parsed. Check your text.'),
                  ),
                );
                return;
              }
              setState(() {
                _items.addAll(parsed);
                _history.add(
                  HistoryRecord(
                    action: "Import",
                    details: "Imported ${parsed.length} items",
                    time: DateTime.now(),
                  ),
                );
              });
              await _saveData();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _exportCsv() async {
    final headers = [
      'Name',
      'Category',
      'Quantity',
      'Invested',
      'TodayValue',
      'Earnings',
      'Note',
      'Withdrawal',
    ];
    final rows = _items.map(
      (e) => [
        e.name,
        e.category,
        e.quantity?.toString() ?? '',
        e.invested.toStringAsFixed(2),
        e.todayValue.toStringAsFixed(2),
        e.computedEarnings.toStringAsFixed(2),
        e.note ?? '',
        e.withdrawal?.toString() ?? '',
      ],
    );
    final csv = StringBuffer()..writeln(headers.join(','));
    for (final r in rows) {
      csv.writeln(r.map((c) => '"${c.replaceAll('"', '""')}"').join(','));
    }
    await Clipboard.setData(ClipboardData(text: csv.toString()));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard')));
    }
  }

  List<InvestmentItem> _parseFromNote(String note) {
    final text = note
        .replaceAll('\u00A0', ' ')
        .replaceAll('\t', ' ')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('|', '|')
        .replaceAll('__', '')
        .replaceAll('…', '...');

    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final items = <InvestmentItem>[];

    for (final raw in lines) {
      final p1 = RegExp(
        r'^(.*?)\s*(\d+(?:\.\d+)?)?\s*(\d[\d,]*)(?:\/(\d[\d,]*))?(?:\s*[\|~\-]\s*(\d[\d,]*))?\s*$',
      );
      final m1 = p1.firstMatch(raw);
      if (m1 != null) {
        final name = (m1.group(1) ?? '')
            .replaceAll(RegExp(r'[\[\]]'), '')
            .trim()
            .replaceAll(RegExp(r'\.$'), '');
        final qty = m1.group(2) != null ? _toDouble(m1.group(2)!) : null;
        final today = _toDouble(m1.group(3)!);
        final invested = m1.group(4) != null ? _toDouble(m1.group(4)!) : today;
        final extra = m1.group(5) != null ? _toDouble(m1.group(5)!) : null;

        items.add(
          InvestmentItem(
            id: UniqueKey().toString(),
            name: name,
            category: _guessCategory(name),
            todayValue: today,
            invested: invested,
            earnings: null,
            quantity: qty,
            note: extra == null ? null : 'Extra: ${extra.toStringAsFixed(0)}',
            withdrawal: null,
          ),
        );
        continue;
      }
    }
    return items;
  }

  String _guessCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('binance') ||
        lower.contains('kucoin') ||
        lower.contains('bybit') ||
        lower.contains('bitgat')) {
      return 'Crypto';
    }
    if (lower.contains('easypaisa') ||
        lower.contains('meezan') ||
        lower.contains('nbp') ||
        lower.contains('ubl') ||
        lower.contains('hbl') ||
        lower.contains('funds')) {
      return 'Funds';
    }
    if (lower.contains('stock') ||
        lower.contains('ktrade') ||
        lower.contains('fassat')) {
      return 'Stock';
    }
    if (lower.contains('cash') || lower.contains('wallet')) {
      return 'Cash';
    }
    if (lower.contains('bank') ||
        lower.contains('isave') ||
        lower.contains('zindagi')) {
      return 'Bank';
    }
    return 'Uncategorized';
  }

  double _toDouble(String text) {
    return double.tryParse(text.replaceAll(',', '')) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'import') {
                _importFromNote();
              } else if (v == 'reset') {
                final ok = await _confirm(
                  context,
                  'Reset all data?',
                  'This will clear all items and history.',
                );
                if (ok) {
                  setState(() {
                    _items.clear();
                    _history.clear();
                  });
                  await _saveData();
                }
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'import', child: Text('Import from Note')),
              PopupMenuItem(value: 'reset', child: Text('Reset data')),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: "Investments",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: "Analytics",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _addInvestment,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildInvestments();
      case 1:
        return _buildAnalytics();
      case 2:
        return _buildHistory();
      default:
        return const Center(child: Text("Error"));
    }
  }

  Widget _buildInvestments() {
    final filtered = _items.where((e) {
      final matchesQuery = e.name.toLowerCase().contains(_query.toLowerCase());
      final matchesCat =
          _categoryFilter == 'All' || e.category == _categoryFilter;
      return matchesQuery && matchesCat;
    }).toList();

    return Column(
      children: [
        _SummaryHeader(
          totalInvested: totalInvested,
          totalValue: totalValue,
          totalPL: totalProfit,
          profitPercentage: totalProfitPercentage, // Add this line
          taxOnProfit: taxOnProfit,
          cashInHand: totalCashInHand,
          nf: _nf,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search by name',
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _allCategories.contains(_categoryFilter)
                    ? _categoryFilter
                    : 'All',
                onChanged: (v) => setState(() => _categoryFilter = v ?? 'All'),
                items: _allCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final item = filtered[i];
              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  // ... (existing code)
                ),
                onDismissed: (_) => _deleteInvestment(item.id),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.category}  •  Invested ₨${_nf.format(item.invested)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₨${_nf.format(item.todayValue)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${item.computedEarnings >= 0 ? '+' : ''}₨${_nf.format(item.computedEarnings)}',
                          style: TextStyle(
                            color: item.computedEarnings >= 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Add this new Text widget for the profit percentage
                        Text(
                          '${item.profitPercentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: item.computedEarnings >= 0
                                ? Colors.green
                                : Colors.red,
                            fontSize: 12, // smaller font for a cleaner look
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _editInvestment(item),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalytics() {
    final categoryTotals = <String, double>{};
    for (var item in _items) {
      final category = item.category;
      final value = item.todayValue;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + value;
    }

    final pieChartSections = categoryTotals.entries.map((entry) {
      final totalVal = totalValue;
      final percentage = totalVal > 0 ? (entry.value / totalVal) * 100 : 0.0;
      return PieChartSectionData(
        color:
            Colors.primaries[categoryTotals.keys.toList().indexOf(entry.key) %
                Colors.primaries.length],
        value: entry.value,
        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Portfolio Distribution by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: pieChartSections,
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // You can add more charts here, e.g., for profit/loss history
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (ctx, i) {
        final h = _history[i];
        return ListTile(
          leading: Icon(
            h.action == "Add"
                ? Icons.add_circle
                : h.action == "Edit"
                ? Icons.edit
                : Icons.delete,
            color: h.action == "Delete"
                ? Colors.red
                : (h.action == "Edit" ? Colors.blue : Colors.green),
          ),
          title: Text(h.action),
          subtitle: Text(h.details),
          trailing: Text(
            "${h.time.hour}:${h.time.minute.toString().padLeft(2, '0')}",
          ),
        );
      },
    );
  }
}

// --------------------------------------------------------------------
// Add/Edit Page

class AddInvestmentPage extends StatefulWidget {
  final InvestmentItem? existing;
  const AddInvestmentPage({super.key, this.existing});

  @override
  State<AddInvestmentPage> createState() => _AddInvestmentPageState();
}

class _AddInvestmentPageState extends State<AddInvestmentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _category;
  late TextEditingController _invested;
  late TextEditingController _today;
  late TextEditingController _withdrawal;
  late TextEditingController _quantity;
  late TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? "");
    _category = TextEditingController(text: widget.existing?.category ?? "");
    _invested = TextEditingController(
      text: widget.existing?.invested.toString() ?? "",
    );
    _withdrawal = TextEditingController(
      text: widget.existing?.withdrawal?.toString() ?? "",
    );
    _today = TextEditingController(
      text: widget.existing?.todayValue.toString() ?? "",
    );
    _quantity = TextEditingController(
      text: widget.existing?.quantity?.toString() ?? "",
    );
    _note = TextEditingController(text: widget.existing?.note ?? "");
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _invested.dispose();
    _withdrawal.dispose();
    _today.dispose();
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newItem = InvestmentItem(
        id: widget.existing?.id ?? UniqueKey().toString(),
        name: _name.text,
        category: _category.text,
        invested: double.tryParse(_invested.text) ?? 0,
        todayValue: double.tryParse(_today.text) ?? 0,
        withdrawal: double.tryParse(_withdrawal.text),
        quantity: double.tryParse(_quantity.text),
        note: _note.text,
      );
      Navigator.pop(context, newItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? "Add Investment" : "Edit Investment",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) => v == null || v.isEmpty ? "Enter name" : null,
              ),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: "Category"),
              ),
              TextFormField(
                controller: _invested,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Invested"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter invested" : null,
              ),
              TextFormField(
                controller: _withdrawal,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Withdrawal"),
              ),
              TextFormField(
                controller: _today,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Today Value"),
                validator: (v) => v == null || v.isEmpty ? "Enter value" : null,
              ),
              TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantity (optional)",
                ),
              ),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(labelText: "Note (optional)"),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text("Save")),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// Helper Widgets

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.totalInvested,
    required this.totalValue,
    required this.totalPL,
    required this.profitPercentage, // Add this line
    required this.taxOnProfit,
    required this.cashInHand,
    required this.nf,
  });

  final double totalInvested;
  final double totalValue;
  final double totalPL;
  final double profitPercentage; // Add this line
  final double taxOnProfit;
  final double cashInHand;
  final NumberFormat nf;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildSummaryRow('Total Invested', totalInvested),
            _buildSummaryRow('Total Value', totalValue),
            _buildSummaryRow(
              'Total P/L',
              totalPL,
              // Update the label to include the percentage
              labelSuffix: ' (${profitPercentage.toStringAsFixed(2)}%)',
              color: totalPL >= 0 ? Colors.green : Colors.red,
            ),
            const Divider(),
            _buildSummaryRow(
              'Tax Deduction (20%)',
              taxOnProfit,
              color: totalPL > 0 ? Colors.orange : null,
            ),
          ],
        ),
      ),
    );
  }

  // Update the helper function to accept an optional suffix for the label
  Widget _buildSummaryRow(
    String label,
    double value, {
    Color? color,
    String? labelSuffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label + (labelSuffix ?? ''),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            '₨${nf.format(value)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
