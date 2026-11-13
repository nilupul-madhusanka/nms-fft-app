import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Income'),
              Tab(text: 'Expense'),
            ],
          ),
        ),
        body: provider.categoriesLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.categoriesFailed
            ? const Center(child: Text('Could not load categories.'))
            : TabBarView(
                children: [
                  _CategoryList(
                    categories: provider.incomeCategories,
                    type: 'income',
                  ),
                  _CategoryList(
                    categories: provider.expenseCategories,
                    type: 'expense',
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: provider.categoriesLoading || provider.categoriesFailed
              ? null
              : () => _showAddCategoryDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final provider = context.read<AppProvider>();
    final categoryId = 'cat_${const Uuid().v4()}';
    var categoryName = '';
    String? nameError;
    String? saveError;
    var saving = false;
    String selectedType = 'expense';
    String selectedIcon = '📦';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Category'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type toggle
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Income'),
                        selected: selectedType == 'income',
                        onSelected: saving
                            ? null
                            : (_) => setDialogState(() {
                                selectedType = 'income';
                                nameError = null;
                              }),
                        selectedColor: AppTheme.incomeColor,
                        labelStyle: TextStyle(
                          color: selectedType == 'income'
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Expense'),
                        selected: selectedType == 'expense',
                        onSelected: saving
                            ? null
                            : (_) => setDialogState(() {
                                selectedType = 'expense';
                                nameError = null;
                              }),
                        selectedColor: AppTheme.expenseColor,
                        labelStyle: TextStyle(
                          color: selectedType == 'expense'
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Name
                TextField(
                  enabled: !saving,
                  onChanged: (value) => setDialogState(() {
                    categoryName = value;
                    nameError = null;
                  }),
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g., Rent',
                    errorText: nameError,
                  ),
                ),
                const SizedBox(height: 16),
                // Icon picker
                const Text(
                  'Choose Icon',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoryIcons
                      .map(
                        (emoji) => GestureDetector(
                          onTap: saving
                              ? null
                              : () =>
                                    setDialogState(() => selectedIcon = emoji),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedIcon == emoji
                                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: selectedIcon == emoji
                                  ? Border.all(
                                      color: AppTheme.primaryColor,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (saveError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      saveError!,
                      style: const TextStyle(color: AppTheme.expenseColor),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (saving) return;
                      final name = categoryName.trim();
                      final categories = selectedType == 'income'
                          ? provider.incomeCategories
                          : provider.expenseCategories;
                      if (name.isEmpty) {
                        setDialogState(
                          () => nameError = 'Enter a category name.',
                        );
                        return;
                      }
                      if (categories.any(
                        (category) =>
                            category.id != categoryId &&
                            category.name.trim().toLowerCase() ==
                                name.toLowerCase(),
                      )) {
                        setDialogState(
                          () => nameError = 'That category already exists.',
                        );
                        return;
                      }

                      final category = CategoryModel(
                        id: categoryId,
                        name: name,
                        icon: selectedIcon,
                        type: selectedType,
                        createdAt: DateTime.now(),
                      );

                      setDialogState(() {
                        saving = true;
                        saveError = null;
                      });
                      try {
                        await provider.addCategory(category);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (error) {
                        debugPrint('Could not add category: $error');
                        if (ctx.mounted) {
                          setDialogState(() {
                            saving = false;
                            saveError =
                                'Could not add the category. Try again.';
                          });
                        }
                      }
                    },
              child: Text(saving ? 'Adding…' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<CategoryModel> categories;
  final String type;

  const _CategoryList({required this.categories, required this.type});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'income' ? Icons.trending_up : Icons.trending_down,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No $type categories yet',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to add one',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    (type == 'income'
                            ? AppTheme.incomeColor
                            : AppTheme.expenseColor)
                        .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(cat.icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            title: Text(
              cat.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.expenseColor,
              ),
              onPressed: () => _confirmDelete(context, cat),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, CategoryModel cat) async {
    final provider = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}" from the category list?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await provider.deleteCategory(cat.id);
    } catch (error) {
      debugPrint('Could not delete category: $error');
      if (messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not delete the category. Try again.'),
          ),
        );
      }
    }
  }
}
