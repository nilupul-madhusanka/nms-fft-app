import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? editTransaction;

  const AddTransactionScreen({super.key, this.editTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late final String _newTransactionId = const Uuid().v4();

  TransactionType _type = TransactionType.expense;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  bool get isEditing => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final t = widget.editTransaction!;
      _type = t.type;
      _amountController.text = t.amount.toString();
      _noteController.text = t.note;
      _selectedCategory = t.category;
      _selectedDate = t.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final categories = _type == TransactionType.income
        ? provider.incomeCategories
        : provider.expenseCategories;
    final original = widget.editTransaction;
    final originalCategoryMissing =
        original != null &&
        original.type == _type &&
        !categories.any((category) => category.name == original.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─── Type Toggle ───
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (_type == TransactionType.income) return;
                        _type = TransactionType.income;
                        _selectedCategory = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.income
                              ? AppTheme.incomeColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              color: _type == TransactionType.income
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Income',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _type == TransactionType.income
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (_type == TransactionType.expense) return;
                        _type = TransactionType.expense;
                        _selectedCategory = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.expense
                              ? AppTheme.expenseColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              color: _type == TransactionType.expense
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Expense',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _type == TransactionType.expense
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Amount ───
            const Text(
              'Amount',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                hintText: '0.00',
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: _type == TransactionType.income
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor,
                ),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter an amount';
                final amount = double.tryParse(val);
                if (amount == null || !amount.isFinite || amount <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ─── Category ───
            const Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (originalCategoryMissing)
                  ChoiceChip(
                    label: Text(original.category),
                    selected: _selectedCategory == original.category,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = original.category),
                  ),
                ...categories.map((cat) {
                  final isSelected = _selectedCategory == cat.name;
                  return ChoiceChip(
                    label: Text('${cat.icon} ${cat.name}'),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat.name),
                    selectedColor: _type == TransactionType.income
                        ? AppTheme.incomeColor.withValues(alpha: 0.2)
                        : AppTheme.expenseColor.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? (_type == TransactionType.income
                                ? AppTheme.incomeColor
                                : AppTheme.expenseColor)
                          : AppTheme.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? (_type == TransactionType.income
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor)
                            : AppTheme.dividerColor,
                      ),
                    ),
                  );
                }),
              ],
            ),
            if (provider.categoriesLoading && categories.isEmpty)
              const LinearProgressIndicator()
            else if (provider.categoriesFailed)
              const Text('Could not load categories.')
            else if (categories.isEmpty && !originalCategoryMissing)
              const Text('Add a category from the Categories tab first.')
            else if (_selectedCategory == null)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Please select a category',
                  style: TextStyle(color: AppTheme.expenseColor, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),

            // ─── Date ───
            const Text(
              'Date',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final earliest = DateTime(now.year - 2);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: _selectedDate.isBefore(earliest)
                      ? _selectedDate
                      : earliest,
                  lastDate: _selectedDate.isAfter(now) ? _selectedDate : now,
                );
                if (picked != null && mounted) {
                  setState(() => _selectedDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Helpers.dateFormat.format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── Note ───
            const Text(
              'Note (optional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Add a note...',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 32),

            // ─── Save Button ───
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == TransactionType.income
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        isEditing ? 'Update' : 'Save',
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving ||
        !_formKey.currentState!.validate() ||
        _selectedCategory == null) {
      return;
    }

    final provider = context.read<AppProvider>();
    final user = provider.user;
    if (user == null) return;
    final original = widget.editTransaction;
    final categories = _type == TransactionType.income
        ? provider.incomeCategories
        : provider.expenseCategories;
    if (!categories.any((category) => category.name == _selectedCategory) &&
        !(original?.type == _type && original?.category == _selectedCategory)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a category that still exists.')),
      );
      return;
    }
    setState(() => _isSaving = true);

    final transaction = TransactionModel(
      id: original?.id ?? _newTransactionId,
      userId: original?.userId ?? user.uid,
      userName: original?.userName ?? Helpers.displayName(user.displayName),
      userPhotoUrl: original?.userPhotoUrl ?? user.photoURL ?? '',
      type: _type,
      category: _selectedCategory!,
      amount: double.parse(_amountController.text),
      note: _noteController.text.trim(),
      date: _selectedDate,
      createdAt: original?.createdAt ?? DateTime.now(),
    );

    try {
      if (isEditing) {
        await provider.updateTransaction(transaction);
      } else {
        await provider.addTransaction(transaction);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      debugPrint('Could not save transaction: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not save the transaction. Try again.'),
            backgroundColor: AppTheme.expenseColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
