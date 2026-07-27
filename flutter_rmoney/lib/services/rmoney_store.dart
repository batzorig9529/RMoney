import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/models.dart';
import '../utils/finance_calculator.dart';

class RMoneyStore {
  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/rmoney_data.json');
  }

  Future<Map<String, dynamic>> _readRoot() async {
    final file = await _file();
    if (!await file.exists()) return {};
    final decoded = jsonDecode(await file.readAsString());
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  Future<void> _writeRoot(Map<String, dynamic> root) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(root));
  }

  Future<List<MoneyRecord>> load() async {
    try {
      final root = await _readRoot();
      final items = (root['transactions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MoneyRecord.fromJson)
          .toList();
      final pruned = FinanceCalculator.latestSixMonths(items, DateTime.now());
      if (pruned.length != items.length) {
        await save(pruned);
      }
      return pruned;
    } catch (_) {
      return [];
    }
  }

  Future<SavingsPlan> loadSavingsPlan() async {
    try {
      final root = await _readRoot();
      final json = root['savingsPlan'];
      return SavingsPlan.fromJson(json is Map<String, dynamic> ? json : null);
    } catch (_) {
      return const SavingsPlan();
    }
  }

  Future<void> saveSavingsPlan(SavingsPlan plan) async {
    final root = await _readRoot();
    root['savingsPlan'] = plan.toJson();
    await _writeRoot(root);
  }

  Future<void> add(MoneyRecord record) async {
    final records = await load();
    records.add(record);
    await save(FinanceCalculator.latestSixMonths(records, DateTime.now()));
  }

  Future<void> save(List<MoneyRecord> records) async {
    final root = await _readRoot();
    root['transactions'] = records.map((record) => record.toJson()).toList();
    root['savingsPlan'] ??= const SavingsPlan().toJson();
    await _writeRoot(root);
  }
}
