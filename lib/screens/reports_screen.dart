import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TransactionType _chartType = TransactionType.expense;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'This Week'),
            Tab(text: 'This Month'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportView(
            rangeType: _RangeType.week,
            chartType: _chartType,
            onChartTypeChanged: (t) => setState(() => _chartType = t),
          ),
          _ReportView(
            rangeType: _RangeType.month,
            chartType: _chartType,
            onChartTypeChanged: (t) => setState(() => _chartType = t),
          ),
        ],
      ),
    );
  }
}

enum _RangeType { week, month }

class _ReportView extends StatelessWidget {
  final _RangeType rangeType;
  final TransactionType chartType;
  final ValueChanged<TransactionType> onChartTypeChanged;

  const _ReportView({
    required this.rangeType,
    required this.chartType,
    required this.onChartTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final now = DateTime.now();

    final DateTime start;
    final DateTime end;
    final String periodLabel;

    if (rangeType == _RangeType.week) {
      start = Helpers.startOfWeek(now);
      end = Helpers.endOfWeek(now);
      periodLabel =
          '${Helpers.shortDate.format(start)} – ${Helpers.shortDate.format(end)}';
    } else {
      start = Helpers.startOfMonth(now);
      end = Helpers.endOfMonth(now);
      periodLabel = Helpers.monthYearFormat.format(now);
    }

    final rangeTransactions = provider.getTransactionsInRange(start, end);
    final income = rangeTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = rangeTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final balance = income - expense;

    final categoryBreakdown =
        provider.getCategoryBreakdown(chartType, start: start, end: end);
    final memberBreakdown =
        provider.getMemberBreakdown(chartType, start: start, end: end);
    final dailyTotals = provider.getDailyTotals(start, end);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Period Header ───
        Center(
          child: Text(
            periodLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ─── Summary Row ───
        Row(
          children: [
            _SummaryTile(
              label: 'Income',
              amount: income,
              color: AppTheme.incomeColor,
              icon: Icons.arrow_downward_rounded,
            ),
            const SizedBox(width: 12),
            _SummaryTile(
              label: 'Expense',
              amount: expense,
              color: AppTheme.expenseColor,
              icon: Icons.arrow_upward_rounded,
            ),
            const SizedBox(width: 12),
            _SummaryTile(
              label: 'Balance',
              amount: balance,
              color: balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
              icon: Icons.account_balance_wallet_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ─── Daily Trend Chart ───
        _buildSectionTitle('Daily Trend'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: _DailyTrendChart(
                dailyTotals: dailyTotals,
                start: start,
                end: end,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ─── Type Toggle for Pie Chart ───
        Row(
          children: [
            _buildSectionTitle('Breakdown'),
            const Spacer(),
            ToggleButtons(
              isSelected: [
                chartType == TransactionType.expense,
                chartType == TransactionType.income,
              ],
              onPressed: (i) => onChartTypeChanged(
                  i == 0 ? TransactionType.expense : TransactionType.income),
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: chartType == TransactionType.expense
                  ? AppTheme.expenseColor
                  : AppTheme.incomeColor,
              constraints:
                  const BoxConstraints(minWidth: 80, minHeight: 34),
              children: const [
                Text('Expense', style: TextStyle(fontSize: 12)),
                Text('Income', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Pie Chart (Category Breakdown) ───
        if (categoryBreakdown.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No data for this period',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: _CategoryPieChart(
                      breakdown: categoryBreakdown,
                      type: chartType,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Legend
                  ...categoryBreakdown.entries.map((entry) {
                    final total = categoryBreakdown.values
                        .fold(0.0, (s, v) => s + v);
                    final percent = total > 0
                        ? (entry.value / total * 100).toStringAsFixed(1)
                        : '0';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getColorForIndex(
                                  categoryBreakdown.keys
                                      .toList()
                                      .indexOf(entry.key)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(entry.key,
                                style: const TextStyle(fontSize: 13)),
                          ),
                          Text(
                            '${Helpers.formatAmount(entry.value)}  ($percent%)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),

        // ─── Member Breakdown ───
        _buildSectionTitle('By Member'),
        const SizedBox(height: 8),
        if (memberBreakdown.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No data for this period',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: memberBreakdown.entries.map((entry) {
                  final total =
                      memberBreakdown.values.fold(0.0, (s, v) => s + v);
                  final fraction = total > 0 ? entry.value / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            Text(Helpers.formatAmount(entry.value),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: chartType == TransactionType.income
                                      ? AppTheme.incomeColor
                                      : AppTheme.expenseColor,
                                )),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 8,
                            backgroundColor: AppTheme.dividerColor,
                            valueColor: AlwaysStoppedAnimation(
                              chartType == TransactionType.income
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

// ─── Summary Tile ───
class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 2),
              FittedBox(
                child: Text(
                  Helpers.formatAmount(amount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Category Pie Chart ───
class _CategoryPieChart extends StatelessWidget {
  final Map<String, double> breakdown;
  final TransactionType type;

  const _CategoryPieChart({required this.breakdown, required this.type});

  @override
  Widget build(BuildContext context) {
    final entries = breakdown.entries.toList();

    return PieChart(
      PieChartData(
        sections: entries.asMap().entries.map((e) {
          return PieChartSectionData(
            value: e.value.value,
            color: _getColorForIndex(e.key),
            radius: 60,
            title: '',
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }
}

// ─── Daily Trend Bar Chart ───
class _DailyTrendChart extends StatelessWidget {
  final Map<DateTime, Map<String, double>> dailyTotals;
  final DateTime start;
  final DateTime end;

  const _DailyTrendChart({
    required this.dailyTotals,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    // Build list of days
    final days = <DateTime>[];
    var current = Helpers.startOfDay(start);
    final endDay = Helpers.startOfDay(end);
    while (!current.isAfter(endDay)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    if (days.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final maxVal = dailyTotals.values.fold(0.0, (max, dayMap) {
      final dayMax = [
        dayMap['income'] ?? 0.0,
        dayMap['expense'] ?? 0.0,
      ].reduce((a, b) => a > b ? a : b);
      return dayMax > max ? dayMax : max;
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal > 0 ? maxVal * 1.2 : 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Income' : 'Expense';
              return BarTooltipItem(
                '$label\n${Helpers.formatAmount(rod.toY)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= days.length) return const SizedBox();
                // Show every Nth label to avoid crowding
                final step = days.length > 14 ? 5 : (days.length > 7 ? 2 : 1);
                if (idx % step != 0) return const SizedBox();
                return Text(
                  Helpers.shortDate.format(days[idx]),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: days.asMap().entries.map((e) {
          final dayData = dailyTotals[e.value];
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: dayData?['income'] ?? 0,
                color: AppTheme.incomeColor,
                width: days.length > 14 ? 4 : 8,
                borderRadius: BorderRadius.circular(2),
              ),
              BarChartRodData(
                toY: dayData?['expense'] ?? 0,
                color: AppTheme.expenseColor,
                width: days.length > 14 ? 4 : 8,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Color palette for pie chart ───
Color _getColorForIndex(int index) {
  const colors = [
    Color(0xFF6C63FF),
    Color(0xFF2ECC71),
    Color(0xFFE74C3C),
    Color(0xFFF39C12),
    Color(0xFF3498DB),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE67E22),
    Color(0xFF2980B9),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFF8BC34A),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
  ];
  return colors[index % colors.length];
}
