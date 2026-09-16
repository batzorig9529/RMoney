import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/rmoney_store.dart';
import 'add_record_page.dart';
import 'ai_advice_page.dart';
import 'dashboard_page.dart';
import 'loans_page.dart';
import 'reports_page.dart';
import 'savings_page.dart';
import 'transactions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final store = RMoneyStore();
  var tab = 0;
  var records = <MoneyRecord>[];
  var savingsPlan = const SavingsPlan();
  var expenseCategories = <String>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await store.load();
    final loadedPlan = await store.loadSavingsPlan();
    final loadedExpenseCategories = await store.loadExpenseCategories();
    if (mounted) {
      setState(() {
        records = loaded;
        savingsPlan = loadedPlan;
        expenseCategories = loadedExpenseCategories;
      });
    }
  }

  Future<void> _saveSavingsPlan(SavingsPlan plan) async {
    await store.saveSavingsPlan(plan);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Хадгаламжийн зорилт хадгаллаа')),
      );
    }
  }

  Future<void> _add(MoneyRecord record) async {
    await store.add(record);
    await _load();
    if (mounted) {
      setState(() => tab = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Хадгаллаа')),
      );
    }
  }

  Future<void> _addExpenseCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    final updated = {...expenseCategories, trimmed}.toList()..sort();
    await store.saveExpenseCategories(updated);
    await _load();
  }

  Future<void> _update(MoneyRecord record) async {
    final updated = records
        .map((item) => item.id == record.id ? record : item)
        .toList(growable: false);
    await store.save(updated);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заслаа')),
      );
    }
  }

  Future<void> _delete(MoneyRecord record) async {
    final updated =
        records.where((item) => item.id != record.id).toList(growable: false);
    await store.save(updated);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Устгалаа')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
          records: records,
          savingsPlan: savingsPlan,
          onAdd: () => setState(() => tab = 1),
          onAdvice: _openAiAdvice),
      AddRecordPage(
        records: records,
        expenseCategories: expenseCategories,
        onAdd: _add,
        onAddExpenseCategory: _addExpenseCategory,
      ),
      TransactionsPage(
        records: records,
        expenseCategories: expenseCategories,
        onUpdate: _update,
        onDelete: _delete,
        onAddExpenseCategory: _addExpenseCategory,
      ),
      LoansPage(records: records),
      SavingsPage(
          records: records, savingsPlan: savingsPlan, onSave: _saveSavingsPlan),
      ReportsPage(records: records, savingsPlan: savingsPlan),
    ];

    return Scaffold(
      body: SafeArea(child: pages[tab]),
      floatingActionButton: tab == 0
          ? null
          : FloatingActionButton(
              tooltip: 'AI үнэлгээ',
              shape: const CircleBorder(),
              onPressed: _openAiAdvice,
              child: const Icon(Icons.auto_awesome),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Нүүр'),
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'Нэмэх'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Гүйлгээ'),
          NavigationDestination(
              icon: Icon(Icons.people_alt_outlined),
              selectedIcon: Icon(Icons.people_alt),
              label: 'Зээл'),
          NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings),
              label: 'Хадгал'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Тайлан'),
        ],
      ),
    );
  }

  void _openAiAdvice() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiAdvicePage(
          records: records,
          savingsPlan: savingsPlan,
        ),
      ),
    );
  }
}
