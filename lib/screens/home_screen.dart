import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';
import 'categories_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _DashboardTab(),
      const ReportsScreen(),
      const CategoriesScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_rounded),
            label: 'Categories',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
    );
  }
}

// ─── Dashboard Tab ───
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final grouped = provider.transactionsGroupedByDate;

    return CustomScrollView(
      slivers: [
        // ─── App Bar ───
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${user?.displayName?.split(' ').first ?? 'User'} 👋',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  Helpers.monthYearFormat
                                      .format(provider.selectedDate),
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Month picker
                          IconButton(
                            onPressed: () => _pickMonth(context, provider),
                            icon: const Icon(Icons.calendar_month,
                                color: Colors.white),
                          ),
                          // Logout
                          IconButton(
                            onPressed: () => _showLogoutDialog(context, provider),
                            icon:
                                const Icon(Icons.logout, color: Colors.white),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Summary cards
                      Row(
                        children: [
                          Expanded(
                            child: SummaryCard(
                              title: 'Income',
                              amount: provider.totalIncome,
                              icon: Icons.arrow_downward_rounded,
                              color: AppTheme.incomeColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SummaryCard(
                              title: 'Expense',
                              amount: provider.totalExpense,
                              icon: Icons.arrow_upward_rounded,
                              color: AppTheme.expenseColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SummaryCard(
                              title: 'Balance',
                              amount: provider.balance,
                              icon: Icons.account_balance_wallet_rounded,
                              color: provider.balance >= 0
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ─── Filter Chips ───
        SliverToBoxAdapter(
          child: _MemberFilterChips(),
        ),

        // ─── Transaction List ───
        if (grouped.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your first entry',
                    style:
                        TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ...grouped.entries.map((entry) {
            final dayIncome = entry.value
                .where((t) => t.type == TransactionType.income)
                .fold(0.0, (s, t) => s + t.amount);
            final dayExpense = entry.value
                .where((t) => t.type == TransactionType.expense)
                .fold(0.0, (s, t) => s + t.amount);

            return SliverMainAxisGroup(slivers: [
              // Day Header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (dayIncome > 0)
                        Text(
                          '+${Helpers.formatAmount(dayIncome)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.incomeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (dayIncome > 0 && dayExpense > 0)
                        const SizedBox(width: 8),
                      if (dayExpense > 0)
                        Text(
                          '-${Helpers.formatAmount(dayExpense)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.expenseColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Transactions
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => TransactionCard(
                    transaction: entry.value[index],
                  ),
                  childCount: entry.value.length,
                ),
              ),
            ]);
          }),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  void _pickMonth(BuildContext context, AppProvider provider) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      provider.setSelectedDate(picked);
    }
  }

  void _showLogoutDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseColor,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─── Member Filter Chips ───
class _MemberFilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: provider.membersStream,
      builder: (context, snapshot) {
        final members = snapshot.data ?? [];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All Members'),
                selected: provider.filterMember == 'all',
                onSelected: (_) => provider.setFilterMember('all'),
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: provider.filterMember == 'all'
                      ? Colors.white
                      : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              ...members.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: CircleAvatar(
                        backgroundImage: m['photoUrl'] != null &&
                                (m['photoUrl'] as String).isNotEmpty
                            ? NetworkImage(m['photoUrl'])
                            : null,
                        radius: 14,
                        child: m['photoUrl'] == null ||
                                (m['photoUrl'] as String).isEmpty
                            ? Text(
                                (m['displayName'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                      ),
                      label: Text(
                          (m['displayName'] ?? 'User').split(' ').first),
                      selected: provider.filterMember == m['uid'],
                      onSelected: (_) =>
                          provider.setFilterMember(m['uid'] ?? ''),
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: provider.filterMember == m['uid']
                            ? Colors.white
                            : AppTheme.textPrimary,
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
