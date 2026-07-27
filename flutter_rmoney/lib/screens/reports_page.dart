import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../components/components.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage(
      {super.key, required this.records, required this.savingsPlan});

  final List<MoneyRecord> records;
  final SavingsPlan savingsPlan;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final period = FinanceCalculator.periodFor(now);
    final summary =
        FinanceCalculator.summarizeMonth(records, now, now, savingsPlan);
    final comparisons =
        FinanceCalculator.lastSixPeriodComparisons(records, now);
    return PageShell(
      title: 'Тайлан',
      subtitle:
          '${FinanceCalculator.periodLabel(period)} худалдан авалтын график',
      children: [
        ExpenseChart(values: summary.reportBreakdown),
        PeriodComparisonChart(items: comparisons),
        FilledButton.icon(
          onPressed: () => _exportReport(context, period, summary, comparisons),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('PDF тайлан татах'),
        ),
        const SizedBox(height: 12),
        InfoCard(
            title: 'Зайлшгүй / Зайлшгүй бус',
            body: _lines(summary.expensesByNecessity)),
        InfoCard(
            title: 'Худалдан авалтын төрлөөр',
            body: _lines(summary.expensesByCategory)),
        InfoCard(
            title: 'Графикт орсон нэмэлт',
            body: _lines(summary.extraOutflowBreakdown)),
      ],
    );
  }

  String _lines(Map<String, int> values) {
    if (values.isEmpty) return 'Мэдээлэл алга';
    return values.entries
        .map((entry) => '${entry.key}: ${formatMnt(entry.value)}')
        .join('\n');
  }

  Future<void> _exportReport(
    BuildContext context,
    FinancePeriod period,
    FinanceSummary summary,
    List<PeriodComparison> comparisons,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'rmoney_report_${period.start.year}_${period.start.month.toString().padLeft(2, '0')}_${period.start.day.toString().padLeft(2, '0')}.pdf';
    final file = File('${directory.path}/$fileName');
    final bytes = await _reportPdf(period, summary, comparisons);
    await file.writeAsBytes(bytes, flush: true);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF хадгаллаа: ${file.path}')),
      );
    }
    await OpenFilex.open(file.path);
  }

  Future<List<int>> _reportPdf(
    FinancePeriod period,
    FinanceSummary summary,
    List<PeriodComparison> comparisons,
  ) async {
    final fontData = await rootBundle.load('assets/fonts/arial_unicode.ttf');
    final font = pw.Font.ttf(fontData);
    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(base: font, bold: font);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text('RMoney тайлан',
              style:
                  pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Үе: ${FinanceCalculator.periodLabel(period)}'),
          pw.SizedBox(height: 18),
          _pdfSummaryTable(summary),
          pw.SizedBox(height: 18),
          _pdfSection('Худалдан авалтын төрлөөр', summary.expensesByCategory),
          _pdfSection('Зайлшгүй / Зайлшгүй бус', summary.expensesByNecessity),
          _pdfSection('Графикт орсон нэмэлт', summary.extraOutflowBreakdown),
          pw.SizedBox(height: 10),
          pw.Text('Сүүлийн 6 үеийн зардал',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Үе', 'Орлого', 'Зардал', 'Хадгаламж'],
            data: comparisons
                .map((item) => [
                      FinanceCalculator.periodLabel(item.period),
                      formatMnt(item.income),
                      formatMnt(item.expense),
                      formatMnt(item.savings),
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfSummaryTable(FinanceSummary summary) {
    return pw.TableHelper.fromTextArray(
      headers: ['Үзүүлэлт', 'Дүн'],
      data: [
        ['Орлого', formatMnt(summary.income)],
        ['Зардал', formatMnt(summary.expense)],
        ['Хадгаламж', formatMnt(summary.savings)],
        ['10% нөөц', formatMnt(summary.reservedTenPercent)],
        ['Өдрийн боломж', formatMnt(summary.dailyBudget)],
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  pw.Widget _pdfSection(String title, Map<String, int> values) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (values.isEmpty)
            pw.Text('Мэдээлэл алга')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Ангилал', 'Дүн'],
              data: values.entries
                  .map((entry) => [entry.key, formatMnt(entry.value)])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
        ],
      ),
    );
  }
}
