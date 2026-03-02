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
        body: TabBarView(
          children: [
            _CategoryList(
                categories: provider.incomeCategories, type: 'income'),
            _CategoryList(
                categories: provider.expenseCategories, type: 'expense'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddCategoryDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'expense';
    String selectedIcon = '📦';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Category'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        onSelected: (_) =>
                            setDialogState(() => selectedType = 'income'),
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
                        onSelected: (_) =>
                            setDialogState(() => selectedType = 'expense'),
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
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g., Rent',
                  ),
                ),
                const SizedBox(height: 16),
                // Icon picker
                const Text('Choose Icon',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '💰', '💼', '💻', '🎁', '🛒', '🚗', '🔌', '🏥',
                    '📚', '🛍️', '🎬', '🎀', '📦', '🏠', '✈️', '🍔',
                    '☕', '👗', '💊', '📱', '🎮', '⚽', '🎵', '🐾',
                  ]
                      .map((emoji) => GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedIcon = emoji),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selectedIcon == emoji
                                    ? AppTheme.primaryColor
                                        .withValues(alpha: 0.2)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: selectedIcon == emoji
                                    ? Border.all(
                                        color: AppTheme.primaryColor, width: 2)
                                    : null,
                              ),
                              child: Center(
                                  child: Text(emoji,
                                      style: const TextStyle(fontSize: 20))),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final category = CategoryModel(
                  id: 'cat_${const Uuid().v4().substring(0, 8)}',
                  name: name,
                  icon: selectedIcon,
                  type: selectedType,
                  createdAt: DateTime.now(),
                );

                context.read<AppProvider>().addCategory(category);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
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
                color: (type == 'income'
                        ? AppTheme.incomeColor
                        : AppTheme.expenseColor)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Center(child: Text(cat.icon, style: const TextStyle(fontSize: 22))),
            ),
            title: Text(cat.name,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.expenseColor),
              onPressed: () => _confirmDelete(context, cat),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CategoryModel cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}"? This won\'t affect existing transactions.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AppProvider>().deleteCategory(cat.id);
              Navigator.pop(ctx);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
